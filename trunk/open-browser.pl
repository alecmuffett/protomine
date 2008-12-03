#!/usr/bin/perl

# OSX kludge to open a browser pointing at the installed mine,
# using the mine's own config file to save on typing...

require "protomine-config.pl";
system("open", $MINE_HTTP_FULLPATH);
exit 0;
