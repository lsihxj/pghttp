-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pghttp" to load this file. \quit

-- HTTP GET function (simple version)
CREATE OR REPLACE FUNCTION http_get(
    url text,
    headers text DEFAULT NULL
) RETURNS text
AS 'MODULE_PATHNAME', 'pghttp_get'
LANGUAGE C;

-- HTTP POST function
CREATE OR REPLACE FUNCTION http_post(
    url text,
    body text,
    headers text DEFAULT NULL
) RETURNS text
AS 'MODULE_PATHNAME', 'pghttp_post'
LANGUAGE C;

-- HTTP request function with detailed response
CREATE TYPE http_response AS (
    status_code integer,
    content_type text,
    body text
);

CREATE OR REPLACE FUNCTION http_request(
    method text,
    url text,
    body text DEFAULT NULL,
    headers text DEFAULT NULL
) RETURNS http_response
AS 'MODULE_PATHNAME', 'pghttp_request'
LANGUAGE C;

COMMENT ON FUNCTION http_get(text, text) IS 'Perform HTTP GET request';
COMMENT ON FUNCTION http_post(text, text, text) IS 'Perform HTTP POST request with body and optional headers';
COMMENT ON FUNCTION http_request(text, text, text, text) IS 'Perform HTTP request with full control and detailed response';
