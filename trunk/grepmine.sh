#!/bin/sh
exec egrep -n "$@" protomine.cgi lib/*.pl
exit 1
