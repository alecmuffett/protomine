#!/bin/sh

##
## Copyright 2008 Adriana Lukas & Alec Muffett
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You
## may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
## implied. See the License for the specific language governing
## permissions and limitations under the License.
##

thisdir=`dirname $0`

cd $thisdir

thisdir=`pwd`

http_server="http://localhost"

http_path="/~$USER/mine" # no trailing slash

cat <<EOF
#!/usr/bin/perl

\$main::MINE_HTTP_SERVER     = "$http_server";
\$main::MINE_HTTP_PATH       = "$http_path";
\$main::MINE_HTTP_FULLPATH   = \$MINE_HTTP_SERVER . \$MINE_HTTP_PATH;

\$main::MINE_DIRECTORY       = "$thisdir";

unshift(@INC, "\$MINE_DIRECTORY/lib");

1;
EOF

exit 0
