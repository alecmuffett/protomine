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

DIRECTORY=`dirname $0`
cd $DIRECTORY
DIRECTORY=`pwd`
HTTP_SERVER="http://localhost"
HTTP_PATH="/~$USER/mine" # NO TRAILING SLASH

cat <<EOF
#!/usr/bin/perl
\$MINE_HTTP_SERVER     = "$HTTP_SERVER";
\$MINE_HTTP_PATH       = "$HTTP_PATH";
\$MINE_HTTP_FULLPATH   = \$MINE_HTTP_SERVER . \$MINE_HTTP_PATH;

\$MINE_DIRECTORY       = "$DIRECTORY";

unshift(@INC, "\$MINE_DIRECTORY/mine");
1;
EOF

exit 0
