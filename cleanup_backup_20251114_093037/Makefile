EXTENSION = pghttp
DATA = pghttp--1.0.0.sql
MODULES = pghttp

# PostgreSQL build system
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)

# Compiler flags for libcurl
PG_CPPFLAGS = -I$(shell $(PG_CONFIG) --includedir)
SHLIB_LINK = -lcurl

include $(PGXS)
