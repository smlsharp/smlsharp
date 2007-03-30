#!/bin/sh
[ "$1" = "-b" ] && shift 2
exec g++ "$@"
