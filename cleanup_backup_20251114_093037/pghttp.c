/* Avoid timezone struct redefinition on Windows */
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
#include <curl/curl.h>
#include <string.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

/* Module load/unload callbacks */
void _PG_init(void);
void _PG_fini(void);

/* Track curl initialization */
static bool curl_initialized = false;

/* Initialize curl library on module load */
void _PG_init(void) {
    /* Do nothing here - elog may not be safe at this stage
     * We'll initialize curl lazily when first needed */
}

/* Cleanup curl library on module unload */
void _PG_fini(void) {
    if (curl_initialized) {
        curl_global_cleanup();
        curl_initialized = false;
    }
}

/* Response buffer structure */
typedef struct {
    char *data;
    size_t size;
} response_buffer;

/* HTTP response structure */
typedef struct {
    long status_code;
    char *content_type;
    char *body;
} http_response_data;

/* Callback function for libcurl to write response data */
static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    response_buffer *mem = (response_buffer *)userp;
    
    char *ptr = realloc(mem->data, mem->size + realsize + 1);
    if(ptr == NULL) {
        elog(ERROR, "pghttp: insufficient memory for response");
        return 0;
    }
    
    mem->data = ptr;
    memcpy(&(mem->data[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->data[mem->size] = 0;
    
    return realsize;
}

/* Callback function for libcurl to capture headers */
static size_t header_callback(char *buffer, size_t size, size_t nitems, void *userdata) {
    size_t numbytes = size * nitems;
    char **content_type = (char **)userdata;
    
    /* Look for Content-Type header */
    if (strncasecmp(buffer, "Content-Type:", 13) == 0) {
        char *start = buffer + 13;
        while (*start == ' ') start++;
        
        char *end = start;
        while (*end != '\r' && *end != '\n' && *end != '\0') end++;
        
        size_t len = end - start;
        *content_type = palloc(len + 1);
        memcpy(*content_type, start, len);
        (*content_type)[len] = '\0';
    }
    
    return numbytes;
}

/* Parse JSON headers string and add to curl headers */
static struct curl_slist* parse_and_add_headers(const char *headers_json, struct curl_slist *headers) {
    if (headers_json == NULL || strlen(headers_json) == 0)
        return headers;
    
    /* Simple JSON parser for header object */
    /* Expected format: {"Header1":"Value1","Header2":"Value2"} */
    const char *ptr = headers_json;
    
    /* Skip opening brace */
    while (*ptr && (*ptr == ' ' || *ptr == '{')) ptr++;
    
    while (*ptr && *ptr != '}') {
        /* Skip whitespace and quotes */
        while (*ptr && (*ptr == ' ' || *ptr == ',' || *ptr == '"')) ptr++;
        if (*ptr == '}') break;
        
        /* Read header name */
        const char *name_start = ptr;
        while (*ptr && *ptr != '"' && *ptr != ':') ptr++;
        size_t name_len = ptr - name_start;
        
        /* Skip to value */
        while (*ptr && (*ptr == '"' || *ptr == ':' || *ptr == ' ')) ptr++;
        
        /* Read header value */
        const char *value_start = ptr;
        while (*ptr && *ptr != '"') ptr++;
        size_t value_len = ptr - value_start;
        
        if (name_len > 0 && value_len > 0) {
            char *header_line = palloc(name_len + value_len + 3);
            snprintf(header_line, name_len + value_len + 3, "%.*s: %.*s", 
                    (int)name_len, name_start, (int)value_len, value_start);
            headers = curl_slist_append(headers, header_line);
            pfree(header_line);
        }
        
        /* Skip closing quote */
        if (*ptr == '"') ptr++;
    }
    
    return headers;
}

/* Perform HTTP request */
static http_response_data* perform_http_request(const char *method, const char *url, 
                                                 const char *body, const char *headers_json) {
    CURL *curl;
    CURLcode res;
    response_buffer chunk;
    http_response_data *response;
    struct curl_slist *headers = NULL;
    char *content_type = NULL;
    
    /* Lazy initialization of curl - only once per backend process */
    if (!curl_initialized) {
        elog(WARNING, "pghttp: Initializing curl library (first call)...");
        CURLcode init_res = curl_global_init(CURL_GLOBAL_ALL);
        if (init_res != CURLE_OK) {
            elog(ERROR, "pghttp: Failed to initialize curl library: %s", curl_easy_strerror(init_res));
            return NULL;
        }
        curl_initialized = true;
        elog(WARNING, "pghttp: Curl library initialized successfully");
    }
    
    /* Debug logging */
    elog(WARNING, "pghttp: Starting HTTP request - Method: %s, URL: %s", method, url);
    
    /* Initialize response buffer */
    chunk.data = malloc(1);
    chunk.size = 0;
    
    if (chunk.data == NULL) {
        elog(ERROR, "pghttp: Failed to allocate memory for response buffer");
        return NULL;
    }
    
    /* Initialize response structure */
    response = (http_response_data *)palloc(sizeof(http_response_data));
    response->status_code = 0;
    response->content_type = NULL;
    response->body = NULL;
    
    /* Initialize curl */
    elog(WARNING, "pghttp: Initializing CURL...");
    curl = curl_easy_init();
    if(!curl) {
        free(chunk.data);
        elog(ERROR, "pghttp: failed to initialize CURL");
        return NULL;
    }
    elog(WARNING, "pghttp: CURL initialized successfully");
    
    /* Set URL */
    curl_easy_setopt(curl, CURLOPT_URL, url);
    
    /* Set UTF-8 encoding by default */
    headers = curl_slist_append(headers, "Accept-Charset: utf-8");
    
    /* Parse and add custom headers */
    if (headers_json != NULL) {
        headers = parse_and_add_headers(headers_json, headers);
    }
    
    /* Set method and body */
    if (strcasecmp(method, "POST") == 0) {
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        if (body != NULL) {
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, strlen(body));
            
            /* Set default Content-Type if not specified */
            if (headers_json == NULL || strstr(headers_json, "Content-Type") == NULL) {
                headers = curl_slist_append(headers, "Content-Type: application/json; charset=utf-8");
            }
        }
    } else if (strcasecmp(method, "GET") == 0) {
        curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
    } else {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, method);
        if (body != NULL) {
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
        }
    }
    
    /* Set headers */
    if (headers != NULL) {
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    }
    
    /* Set callbacks */
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, header_callback);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, (void *)&content_type);
    
    /* Follow redirects */
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    
    /* Set timeout (30 seconds) */
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    
    /* SSL options - verify peer and host */
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
    
    /* Enable verbose logging for debugging */
    /* curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); */
    
    /* Perform request */
    elog(WARNING, "pghttp: Executing HTTP request...");
    res = curl_easy_perform(curl);
    elog(WARNING, "pghttp: HTTP request completed with code: %d", res);
    
    if(res != CURLE_OK) {
        char error_msg[256];
        snprintf(error_msg, sizeof(error_msg), "pghttp: HTTP request failed - %s (URL: %s)", 
                 curl_easy_strerror(res), url);
        
        curl_easy_cleanup(curl);
        curl_slist_free_all(headers);
        free(chunk.data);
        
        elog(ERROR, "%s", error_msg);
        return NULL;
    }
    
    elog(WARNING, "pghttp: Request successful, response size: %zu bytes", chunk.size);
    
    /* Get status code */
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response->status_code);
    
    /* Copy response data to PostgreSQL memory */
    if (chunk.size > 0) {
        response->body = palloc(chunk.size + 1);
        memcpy(response->body, chunk.data, chunk.size);
        response->body[chunk.size] = '\0';
    } else {
        /* Empty response - allocate empty string instead of NULL */
        response->body = palloc(1);
        response->body[0] = '\0';
    }
    
    /* Copy content type */
    if (content_type != NULL) {
        response->content_type = content_type;
    }
    
    /* Cleanup */
    curl_easy_cleanup(curl);
    curl_slist_free_all(headers);
    free(chunk.data);
    
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
    
    /* CRITICAL: First line of function - if this doesn't show, function isn't being called */
    elog(WARNING, "=== pghttp_get FUNCTION ENTRY ===");
    
    PG_TRY();
    {
        elog(WARNING, "pghttp_get: Getting arguments...");
        url_text = PG_GETARG_TEXT_PP(0);
        headers_text = PG_ARGISNULL(1) ? NULL : PG_GETARG_TEXT_PP(1);
        
        elog(WARNING, "pghttp_get: Converting text to cstring...");
        url = text_to_cstring(url_text);
        headers = headers_text ? text_to_cstring(headers_text) : NULL;
        
        elog(WARNING, "pghttp_get: About to call perform_http_request with URL: %s", url);
        response = perform_http_request("GET", url, NULL, headers);
        
        elog(WARNING, "pghttp_get: perform_http_request returned, checking response...");
        if (response == NULL) {
            elog(WARNING, "pghttp_get: Response is NULL, returning NULL");
            PG_RETURN_NULL();
        }
        
        /* response->body is never NULL now, it's at least an empty string */
        elog(WARNING, "pghttp_get: Converting response to text...");
        result = cstring_to_text(response->body);
        
        elog(WARNING, "pghttp_get: SUCCESS - Returning result");
        PG_RETURN_TEXT_P(result);
    }
    PG_CATCH();
    {
        elog(WARNING, "pghttp_get: EXCEPTION CAUGHT!");
        PG_RE_THROW();
    }
    PG_END_TRY();
    
    /* Should never reach here */
    elog(WARNING, "pghttp_get: ERROR - Reached end of function without return!");
    PG_RETURN_NULL();
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
    
    if (response == NULL) {
        PG_RETURN_NULL();
    }
    
    /* response->body is never NULL now */
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
    
    /* response->body is never NULL now, always set it */
    values[2] = CStringGetTextDatum(response->body);
    
    tuple = heap_form_tuple(tupdesc, values, nulls);
    PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}
