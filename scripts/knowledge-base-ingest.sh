#!/bin/bash
# Wrapper for knowledge-base ingest
exec "$(dirname "$0")/knowledge-base/ingest.sh" "$@"
