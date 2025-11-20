/* PostgreSQL HTTP Extension using WinHTTP (MSVC) */

#ifdef WIN32
#define _TIMEZONE_DEFINED
#endif

#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "lib/stringinfo.h"
#include "catalog/pg_type.h"
#include "access/htup_details.h"

#ifdef WIN32
#include <windows.h>
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")
#endif

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

void _PG_init(void) {}
void _PG_fini(void) {}

/* HTTP response structure */
typedef struct {
    long status_code;
    char *content_type;
    char *body;
} http_response_data;

/* Helper: Convert char* to WCHAR* */
static WCHAR* char_to_wchar(const char *str) {
    int len = MultiByteToWideChar(CP_UTF8, 0, str, -1, NULL, 0);
    WCHAR *wstr = (WCHAR*)palloc(len * sizeof(WCHAR));
    MultiByteToWideChar(CP_UTF8, 0, str, -1, wstr, len);
    return wstr;
}

/* Perform HTTP request using WinHTTP */
static http_response_data* perform_http_request(const char *method, const char *url, 
                                                  const char *body, const char *headers_json) {
    HINTERNET hSession = NULL;
    HINTERNET hConnect = NULL;
    HINTERNET hRequest = NULL;
    BOOL bResults = FALSE;
    DWORD dwSize = 0;
    DWORD dwDownloaded = 0;
    DWORD dwStatusCode = 0;
    LPSTR pszOutBuffer;
    StringInfoData response_body;
    http_response_data *response;
    
    WCHAR *wszURL;
    WCHAR wszHost[256];
    WCHAR wszPath[2048];
    URL_COMPONENTS urlComp;
    WCHAR *wszMethod;
    
    elog(NOTICE, "pghttp: Request - Method: %s, URL: %s", method, url);
    
    /* Initialize response */
    response = (http_response_data*)palloc0(sizeof(http_response_data));
    initStringInfo(&response_body);
    
    /* Convert URL to wide string */
    wszURL = char_to_wchar(url);
    wszMethod = char_to_wchar(method);
    
    /* Parse URL */
    ZeroMemory(&urlComp, sizeof(urlComp));
    urlComp.dwStructSize = sizeof(urlComp);
    urlComp.lpszHostName = wszHost;
    urlComp.dwHostNameLength = 256;
    urlComp.lpszUrlPath = wszPath;
    urlComp.dwUrlPathLength = 2048;
    
    if (!WinHttpCrackUrl(wszURL, 0, 0, &urlComp)) {
        elog(ERROR, "pghttp: Failed to parse URL");
        pfree(wszURL);
        pfree(wszMethod);
        return NULL;
    }
    
    /* Create session */
    hSession = WinHttpOpen(L"pghttp/1.0",
                           WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                           WINHTTP_NO_PROXY_NAME,
                           WINHTTP_NO_PROXY_BYPASS, 0);
    
    if (!hSession) {
        elog(ERROR, "pghttp: Failed to create HTTP session");
        pfree(wszURL);
        pfree(wszMethod);
        return NULL;
    }
    
    /* Set timeout (30 seconds) */
    DWORD timeout = 30000;
    WinHttpSetOption(hSession, WINHTTP_OPTION_CONNECT_TIMEOUT, &timeout, sizeof(timeout));
    WinHttpSetOption(hSession, WINHTTP_OPTION_RECEIVE_TIMEOUT, &timeout, sizeof(timeout));
    
    /* Connect to server */
    hConnect = WinHttpConnect(hSession, wszHost, urlComp.nPort, 0);
    
    if (!hConnect) {
        elog(ERROR, "pghttp: Failed to connect to server");
        WinHttpCloseHandle(hSession);
        pfree(wszURL);
        pfree(wszMethod);
        return NULL;
    }
    
    /* Create HTTP request */
    DWORD dwFlags = (urlComp.nScheme == INTERNET_SCHEME_HTTPS) ? WINHTTP_FLAG_SECURE : 0;
    hRequest = WinHttpOpenRequest(hConnect, wszMethod, wszPath,
                                   NULL, WINHTTP_NO_REFERER,
                                   WINHTTP_DEFAULT_ACCEPT_TYPES, dwFlags);
    
    if (!hRequest) {
        elog(ERROR, "pghttp: Failed to create HTTP request");
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        pfree(wszURL);
        pfree(wszMethod);
        return NULL;
    }
    
    /* Add Content-Type header for POST/PUT requests with body */
    if (body != NULL && strlen(body) > 0) {
        WinHttpAddRequestHeaders(hRequest, 
                                  L"Content-Type: application/json",
                                  -1, 
                                  WINHTTP_ADDREQ_FLAG_ADD);
    }
    
    /* Add custom headers if provided */
    if (headers_json != NULL && strlen(headers_json) > 0) {
        WCHAR *wszHeaders = char_to_wchar(headers_json);
        WinHttpAddRequestHeaders(hRequest, wszHeaders, -1, 
                                  WINHTTP_ADDREQ_FLAG_ADD | WINHTTP_ADDREQ_FLAG_REPLACE);
        pfree(wszHeaders);
    }
    
    /* Send request */
    LPVOID lpBody = (body != NULL) ? (LPVOID)body : WINHTTP_NO_REQUEST_DATA;
    DWORD dwBodyLen = (body != NULL) ? strlen(body) : 0;
    
    bResults = WinHttpSendRequest(hRequest,
                                   WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                                   lpBody, dwBodyLen, dwBodyLen, 0);
    
    if (!bResults) {
        elog(ERROR, "pghttp: Failed to send HTTP request");
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        pfree(wszURL);
        pfree(wszMethod);
        return NULL;
    }
    
    /* Receive response */
    bResults = WinHttpReceiveResponse(hRequest, NULL);
    
    if (!bResults) {
        elog(ERROR, "pghttp: Failed to receive HTTP response");
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        pfree(wszURL);
        pfree(wszMethod);
        return NULL;
    }
    
    /* Get status code */
    dwSize = sizeof(dwStatusCode);
    WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                        NULL, &dwStatusCode, &dwSize, NULL);
    response->status_code = (long)dwStatusCode;
    
    elog(NOTICE, "pghttp: HTTP Status: %ld", response->status_code);
    
    /* Get content type */
    WCHAR wszContentType[256];
    dwSize = sizeof(wszContentType);
    if (WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_CONTENT_TYPE,
                            NULL, wszContentType, &dwSize, NULL)) {
        char szContentType[256];
        WideCharToMultiByte(CP_UTF8, 0, wszContentType, -1, szContentType, 256, NULL, NULL);
        response->content_type = pstrdup(szContentType);
    }
    
    /* Read response body */
    do {
        dwSize = 0;
        if (!WinHttpQueryDataAvailable(hRequest, &dwSize))
            break;
        
        if (dwSize == 0)
            break;
        
        pszOutBuffer = (LPSTR)palloc(dwSize + 1);
        ZeroMemory(pszOutBuffer, dwSize + 1);
        
        if (!WinHttpReadData(hRequest, (LPVOID)pszOutBuffer, dwSize, &dwDownloaded)) {
            pfree(pszOutBuffer);
            break;
        }
        
        appendBinaryStringInfo(&response_body, pszOutBuffer, dwDownloaded);
        pfree(pszOutBuffer);
        
    } while (dwSize > 0);
    
    elog(NOTICE, "pghttp: Response size: %d bytes", response_body.len);
    
    /* Cleanup */
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    pfree(wszURL);
    pfree(wszMethod);
    
    /* Set response body */
    if (response_body.len > 0) {
        response->body = response_body.data;
    } else {
        response->body = pstrdup("");
        pfree(response_body.data);
    }
    
    return response;
}

/* http_get function */
PG_FUNCTION_INFO_V1(pghttp_get);
Datum pghttp_get(PG_FUNCTION_ARGS) {
    text *url_text;
    text *headers_text;
    char *url;
    char *headers;
    http_response_data *response;
    text *result;
    
    url_text = PG_GETARG_TEXT_PP(0);
    headers_text = PG_ARGISNULL(1) ? NULL : PG_GETARG_TEXT_PP(1);
    
    url = text_to_cstring(url_text);
    headers = headers_text ? text_to_cstring(headers_text) : NULL;
    
    response = perform_http_request("GET", url, NULL, headers);
    
    if (response == NULL || response->body == NULL) {
        PG_RETURN_NULL();
    }
    
    result = cstring_to_text(response->body);
    PG_RETURN_TEXT_P(result);
}

/* http_post function */
PG_FUNCTION_INFO_V1(pghttp_post);
Datum pghttp_post(PG_FUNCTION_ARGS) {
    text *url_text;
    text *body_text;
    text *headers_text;
    char *url;
    char *body;
    char *headers;
    http_response_data *response;
    text *result;
    
    url_text = PG_GETARG_TEXT_PP(0);
    body_text = PG_GETARG_TEXT_PP(1);
    headers_text = PG_ARGISNULL(2) ? NULL : PG_GETARG_TEXT_PP(2);
    
    url = text_to_cstring(url_text);
    body = text_to_cstring(body_text);
    headers = headers_text ? text_to_cstring(headers_text) : NULL;
    
    response = perform_http_request("POST", url, body, headers);
    
    if (response == NULL || response->body == NULL) {
        PG_RETURN_NULL();
    }
    
    result = cstring_to_text(response->body);
    PG_RETURN_TEXT_P(result);
}

/* http_request function with detailed response */
PG_FUNCTION_INFO_V1(pghttp_request);
Datum pghttp_request(PG_FUNCTION_ARGS) {
    text *method_text;
    text *url_text;
    text *body_text;
    text *headers_text;
    char *method;
    char *url;
    char *body;
    char *headers;
    http_response_data *response;
    TupleDesc tupdesc;
    Datum values[3];
    bool nulls[3];
    HeapTuple tuple;
    
    method_text = PG_GETARG_TEXT_PP(0);
    url_text = PG_GETARG_TEXT_PP(1);
    body_text = PG_ARGISNULL(2) ? NULL : PG_GETARG_TEXT_PP(2);
    headers_text = PG_ARGISNULL(3) ? NULL : PG_GETARG_TEXT_PP(3);
    
    method = text_to_cstring(method_text);
    url = text_to_cstring(url_text);
    body = body_text ? text_to_cstring(body_text) : NULL;
    headers = headers_text ? text_to_cstring(headers_text) : NULL;
    
    response = perform_http_request(method, url, body, headers);
    
    if (response == NULL) {
        PG_RETURN_NULL();
    }
    
    /* Build tuple descriptor */
    if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("function returning record called in context that cannot accept type record")));
    
    tupdesc = BlessTupleDesc(tupdesc);
    
    /* Fill in values */
    memset(nulls, 0, sizeof(nulls));
    
    values[0] = Int32GetDatum(response->status_code);
    
    if (response->content_type != NULL) {
        values[1] = CStringGetTextDatum(response->content_type);
    } else {
        nulls[1] = true;
    }
    
    values[2] = CStringGetTextDatum(response->body);
    
    tuple = heap_form_tuple(tupdesc, values, nulls);
    PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}
