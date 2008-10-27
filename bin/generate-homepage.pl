#!/usr/bin/perl
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

$emphasis = 'b';

# header
$header = <<"EOF;";
<hr>
<p>
<h1>welcome to protomine!</h1>
<p>
EOF;

$footer = <<"EOF;";
<p>
<hr>
EOF;


##################################################################
print $header;

# body
while (<DATA>) {
    next if /^\s*(\#.*)?$/o;	# ski blanks
    chop;

    ($cmd, @rest) = split;

    if ($cmd eq ':') {		# start block / header
	$anchor = "@rest";
	$anchor =~ s!\W+!!go;
	print "<h2><A NAME=\"$anchor\" HREF=\"#$anchor\">@rest</a></h2>\n";
	print "<UL>\n";
    }
    elsif ($cmd eq '-') {	# end block
	print "</UL>\n";
    }
    elsif ($cmd eq '{') {	# start manual LI
	print "<LI>\n";
	print "<$emphasis>@rest:</$emphasis>\n";
    }
    elsif ($cmd eq '}') {	# end manual LI
	print "</LI>\n";
    }
    elsif ($cmd eq '+') {	# manual text
	$url = shift(@rest);
	push(@rest, $url) if ($#rest < 0);
	print "<A HREF=\"$url\">[@rest]</A>\n";
    }
    elsif ($cmd eq '.') {	# automatic LI
	$url = shift(@rest);
	push(@rest, $url) if ($#rest < 0);
	print "<LI><A HREF=\"$url\">@rest</A></LI>\n";
    }
}

print $footer;

exit 0;
##################################################################
__END__;
: this mine!
{ documentation 
+ ../doc/ local
}

{ objects
+ show-objects.html show objects
+ create-object.html create object
}

{ relationships
+ show-relations.html show relationships
+ create-relation.html create relationships
}

{ tags
+ show-tags.html show tags
+ create-tag.html create tag
}

{ management
+ version.html version information
+ show-config.html show configuration
+ update-config.html update configuration
}
-

: the mine! project
. http://themineproject.org/index.php/about/ about
. http://themineproject.org/ home page and blog
. http://themineproject.org/index.php/feed/ rss feed (full)
. http://themineproject.org/index.php/the-mine-papers/ mine! concepts
-

: protomine! software
. http://themineproject.org/index.php/feed/ rss feed (announcements)
. http://themineproject.org/index.php/download/ downloads
-

: protomine! authors
. http://www.mediainfluencer.net/ adriana lukas, mine! inventor
. http://www.crypticide.com/dropsafe/ alec muffett, programmer / geek
-

: hacking, test
. ../test
-

: hacking, feeds
. ../feed/COOKIE
-

: hacking, api
. ../api/config.xml
. ../api/config.xml?_method=PUT
. ../api/object.xml
. ../api/object.xml?_method=POST
. ../api/object/3
. ../api/object/3.xml
. ../api/object/3.xml?_method=DELETE
. ../api/object/3.xml?_method=PUT
. ../api/object/3/clone.xml
. ../api/object/3/clone.xml?_method=POST
. ../api/object/3?_method=PUT
. ../api/relation.xml
. ../api/relation.xml?_method=POST
. ../api/relation/2.xml
. ../api/relation/2.xml?_method=DELETE
. ../api/relation/2.xml?_method=PUT
. ../api/select/object.xml
. ../api/select/relation.xml
. ../api/select/tag.xml
. ../api/share/raw/2/1/3.xml
. ../api/share/redirect/2.xml
. ../api/share/redirect/2/3.xml
. ../api/share/url/2.xml
. ../api/share/url/2/3.xml
. ../api/tag.xml
. ../api/tag.xml?_method=POST
. ../api/tag/4.xml
. ../api/tag/4.xml?_method=DELETE
. ../api/tag/4.xml?_method=PUT
. ../api/version.xml
-

: hacking, ui
. ../ui/clone-object/3.html
. ../ui/create-object.html?_method=POST
. ../ui/create-relation.html?_method=POST
. ../ui/create-tag.html?_method=POST
. ../ui/delete-object/3.html
. ../ui/delete-relation/2.html
. ../ui/delete-tag/4.html
. ../ui/read-data/3
. ../ui/read-object/3.html
. ../ui/read-relation/2.html
. ../ui/read-tag/4.html
. ../ui/select/object.html
. ../ui/select/relation.html
. ../ui/select/tag.html
. ../ui/share/raw/2/1/3
. ../ui/share/redirect/2
. ../ui/share/redirect/2/3
. ../ui/share/url/2.html
. ../ui/share/url/2/3.html
. ../ui/show-clones/3.html
. ../ui/show-config.html
. ../ui/show-objects.html
. ../ui/show-relations.html
. ../ui/show-tags.html
. ../ui/update-config.html?_method=POST
. ../ui/update-data/3.html?_method=POST
. ../ui/update-object/3.html?_method=POST
. ../ui/update-relation/2.html?_method=POST
. ../ui/update-tag/4.html?_method=POST
. ../ui/version.html
-
