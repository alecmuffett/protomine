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

cd $DIRECTORY/..

DIRECTORY=`pwd`

HTTP_SERVER="http://localhost"
HTTP_PATH="/~$USER/mine"

echo "#!/usr/bin/perl"
echo "\$mine_directory   = \"$DIRECTORY\";"
echo "\$mine_http_server = \"$HTTP_SERVER\";"
echo "\$mine_http_path   = \"$HTTP_PATH\";"
echo "1;"

exit 0
