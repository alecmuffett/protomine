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

if [ "x$mine_server" = x ]
then
    mine_server="http://127.0.0.1"
fi

if [ "x$mine_path" = x ]
then
    mine_path="/~$USER/mine" # no trailing slash
fi

cat <<EOF
#!/usr/bin/perl

# important: unambiguous, fully qualified hostname
\$main::MINE_HTTP_SERVER     = "$mine_server";

# important: no trailing slash on this URL
\$main::MINE_HTTP_PATH       = "$mine_path";

# path to the mine installation directory
\$main::MINE_DIRECTORY       = "$thisdir";

# these should not need editing
\$main::MINE_HTTP_FULLPATH   = \$MINE_HTTP_SERVER . \$MINE_HTTP_PATH;
unshift(@INC, "\$MINE_DIRECTORY/lib");

# done
1;
EOF

exit 0
