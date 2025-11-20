-- Simple HTTP GET function using WinHTTP
CREATE OR REPLACE FUNCTION http_get(
    url text
) RETURNS text
AS 'MODULE_PATHNAME', 'pghttp_get_simple'
LANGUAGE C;

COMMENT ON FUNCTION http_get(text) IS 'Perform simple HTTP GET request using WinHTTP';
