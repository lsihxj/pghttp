# PostgreSQL HTTP Extension Makefile (Linux)
# For Windows, use build_full.ps1

MODULE_big = pghttp
OBJS = pghttp.o

EXTENSION = pghttp
DATA = pghttp--1.0.0.sql
PGFILEDESC = "pghttp - HTTP client for PostgreSQL"

# libcurl dependency for Linux
PG_CPPFLAGS = -I/usr/include
SHLIB_LINK = -lcurl

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
