#!/bin/bash
# Wrapper for knowledge-base search
exec "$(dirname "$0")/knowledge-base/search.sh" "$@"
