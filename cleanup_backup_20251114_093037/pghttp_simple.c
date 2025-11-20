/* Simple PostgreSQL HTTP Extension using WinHTTP (Windows only) */

/* Avoid timezone struct redefinition on Windows */
#ifdef WIN32
#define _TIMEZONE_DEFINED
#endif

#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "lib/stringinfo.h"

#ifdef WIN32
#include <windows.h>
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")
#endif

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

/* Module load/unload callbacks */
void _PG_init(void);
void _PG_fini(void);

void _PG_init(void) {
    /* Empty - safe initialization */
}

void _PG_fini(void) {
    /* Empty cleanup */
}

/* Simple HTTP GET using WinHTTP */
PG_FUNCTION_INFO_V1(pghttp_get_simple);
Datum pghttp_get_simple(PG_FUNCTION_ARGS) {
    text *url_text;
    char *url;
    char *result_str;
    text *result;
    
    HINTERNET hSession = NULL;
    HINTERNET hConnect = NULL;
    HINTERNET hRequest = NULL;
    BOOL bResults = FALSE;
    DWORD dwSize = 0;
    DWORD dwDownloaded = 0;
    LPSTR pszOutBuffer;
    StringInfoData response;
    
    WCHAR wszURL[2048];
    WCHAR wszHost[256];
    URL_COMPONENTS urlComp;
    
    /* Get URL parameter */
    url_text = PG_GETARG_TEXT_PP(0);
    url = text_to_cstring(url_text);
    
    elog(WARNING, "=== pghttp_get_simple: URL = %s ===", url);
    
    /* Convert URL to wide string */
    MultiByteToWideChar(CP_UTF8, 0, url, -1, wszURL, 2048);
    
    /* Parse URL */
    ZeroMemory(&urlComp, sizeof(urlComp));
    urlComp.dwStructSize = sizeof(urlComp);
    urlComp.lpszHostName = wszHost;
    urlComp.dwHostNameLength = 256;
    urlComp.dwUrlPathLength = (DWORD)-1;
    
    if (!WinHttpCrackUrl(wszURL, 0, 0, &urlComp)) {
        elog(ERROR, "pghttp: Failed to parse URL");
        PG_RETURN_NULL();
    }
    
    /* Initialize response buffer */
    initStringInfo(&response);
    
    /* Create session */
    hSession = WinHttpOpen(L"pghttp/1.0",
                           WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                           WINHTTP_NO_PROXY_NAME,
                           WINHTTP_NO_PROXY_BYPASS, 0);
    
    if (!hSession) {
        elog(ERROR, "pghttp: WinHttpOpen failed");
        PG_RETURN_NULL();
    }
    
    elog(WARNING, "pghttp: Session created");
    
    /* Connect to server */
    hConnect = WinHttpConnect(hSession, wszHost, urlComp.nPort, 0);
    
    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        elog(ERROR, "pghttp: WinHttpConnect failed");
        PG_RETURN_NULL();
    }
    
    elog(WARNING, "pghttp: Connected to server");
    
    /* Create HTTP request */
    hRequest = WinHttpOpenRequest(hConnect, L"GET", urlComp.lpszUrlPath,
                                   NULL, WINHTTP_NO_REFERER,
                                   WINHTTP_DEFAULT_ACCEPT_TYPES,
                                   (urlComp.nScheme == INTERNET_SCHEME_HTTPS) ? WINHTTP_FLAG_SECURE : 0);
    
    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        elog(ERROR, "pghttp: WinHttpOpenRequest failed");
        PG_RETURN_NULL();
    }
    
    elog(WARNING, "pghttp: Request created");
    
    /* Send request */
    bResults = WinHttpSendRequest(hRequest,
                                   WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                                   WINHTTP_NO_REQUEST_DATA, 0,
                                   0, 0);
    
    if (!bResults) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        elog(ERROR, "pghttp: WinHttpSendRequest failed");
        PG_RETURN_NULL();
    }
    
    elog(WARNING, "pghttp: Request sent");
    
    /* Receive response */
    bResults = WinHttpReceiveResponse(hRequest, NULL);
    
    if (!bResults) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        elog(ERROR, "pghttp: WinHttpReceiveResponse failed");
        PG_RETURN_NULL();
    }
    
    elog(WARNING, "pghttp: Response received, reading data...");
    
    /* Read data */
    do {
        dwSize = 0;
        if (!WinHttpQueryDataAvailable(hRequest, &dwSize)) {
            elog(WARNING, "pghttp: Error in WinHttpQueryDataAvailable");
            break;
        }
        
        if (dwSize == 0)
            break;
        
        pszOutBuffer = (LPSTR)palloc(dwSize + 1);
        if (!pszOutBuffer) {
            elog(WARNING, "pghttp: Out of memory");
            break;
        }
        
        ZeroMemory(pszOutBuffer, dwSize + 1);
        
        if (!WinHttpReadData(hRequest, (LPVOID)pszOutBuffer, dwSize, &dwDownloaded)) {
            elog(WARNING, "pghttp: Error in WinHttpReadData");
            pfree(pszOutBuffer);
            break;
        }
        
        appendBinaryStringInfo(&response, pszOutBuffer, dwDownloaded);
        pfree(pszOutBuffer);
        
    } while (dwSize > 0);
    
    elog(WARNING, "pghttp: Data read complete, size = %d bytes", response.len);
    
    /* Cleanup */
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    
    /* Return result */
    if (response.len > 0) {
        result = cstring_to_text_with_len(response.data, response.len);
        pfree(response.data);
        elog(WARNING, "pghttp: Returning result");
        PG_RETURN_TEXT_P(result);
    } else {
        pfree(response.data);
        elog(WARNING, "pghttp: Empty response");
        PG_RETURN_NULL();
    }
}
