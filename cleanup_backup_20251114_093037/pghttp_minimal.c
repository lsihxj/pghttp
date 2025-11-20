/* Minimal test version - just return a fixed string */

#ifdef WIN32
#define _TIMEZONE_DEFINED
#endif

#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

void _PG_init(void) {
    /* Empty */
}

void _PG_fini(void) {
    /* Empty */
}

/* Minimal test function - just return a fixed string */
PG_FUNCTION_INFO_V1(pghttp_get_simple);
Datum pghttp_get_simple(PG_FUNCTION_ARGS) {
    text *result;
    const char *test_msg = "Hello from pghttp! Function is working!";
    
    /* This should work if basic function calling works */
    result = cstring_to_text(test_msg);
    PG_RETURN_TEXT_P(result);
}
