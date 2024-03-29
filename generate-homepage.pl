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

$emphasis = 'em';

##################################################################
print $header;

# body
while (<DATA>) {
    next if /^\s*(\#.*)?$/o;    # ski blanks
    chop;

    ($cmd, @rest) = split;

    if ($cmd eq ':') {          # start block / header
	$anchor = "@rest";
	$anchor =~ s!\W+!!go;
	print "<h2><A NAME=\"$anchor\" HREF=\"#$anchor\">@rest</a></h2>\n";
	print "<UL>\n";
    }
    elsif ($cmd eq '-') {       # end block
	print "</UL>\n";
    }
    elsif ($cmd eq '{') {       # start manual LI
	print "<LI>\n";
	print "<$emphasis>@rest:</$emphasis>\n";
    }
    elsif ($cmd eq '}') {       # end manual LI
	print "</LI>\n";
    }
    elsif ($cmd eq '+') {       # manual text
	$url = shift(@rest);
	push(@rest, $url) if ($#rest < 0);
	print "<A HREF=\"$url\"><button>@rest</button></A>\n";
    }
    elsif ($cmd eq '.') {       # automatic LI
	$url = shift(@rest);
	push(@rest, $url) if ($#rest < 0);
	print "<LI><A HREF=\"$url\">@rest</A></LI>\n";
    }
    elsif ($cmd eq '\'') {      # verbatim quote
	print "@rest\n";
    }
}

exit 0;
##################################################################
__END__;

: welcome to protomine!

{ my objects
+ list-objects.html list
+ #composenewpost compose new
+ create-object.html upload file
}

{ my tags
+ list-tags.html list
+ create-tag.html create
+ #addquicktags create quick
}

{ my relationships
+ list-relations.html list
+ create-relation.html create
}

{ mine configuration
+ show-config.html show
+ update-config.html update
+ version.html version
}

{ mine documentation
+ ../doc/ local
+ #themineproject project documentation
}
-

' <p/>
' <hr/>
' <p/>

: compose new post
' <form method="post" enctype="multipart/form-data" action="create-object.html">
' <em>Title</em> <br/> <input type="text" size="40" name="objectName" value=""/> <p/>
' <em>Content</em> <br/> <textarea cols="40" rows="12" name="data" value=""></textarea> <p/>
' <em>Summary</em> <br/> <textarea cols="40" rows="1" name="objectDescription" value=""></textarea> <p/>
' <em>Tags</em> <br/> <input type="text" size="40" name="objectTags" value=""/> <p/>
' <em>Status</em><br/>
' <input type="radio" name="objectStatus" value="draft"/ checked> draft
' <input type="radio" name="objectStatus" value="final"/> final
' <input type="radio" name="objectStatus" value="public"/> public
' <p/>
' <input type="hidden" name="objectType" value="text/html" />
' <input type="submit" value="submit"/> <input type="reset" value="reset"/>
' </form>
-

: add quick tags
' <form method="post" enctype="multipart/form-data" action="bulk-tags.html">
' <em>simple:</em> drink wine red-wine white-wine merlot ... <p/>
' <em>smart:</em> drink wine:drink red-wine:wine merlot:red-wine tag:implies1,implies2,... <p/>
' <input type="text" size="80" name="bulktags" value=""/> <p/>
' <input type="submit" value="submit"/> <input type="reset" value="reset"/>
' </form>
-

' <p/>
' <hr/>
' <p/>

: the mine! project
. http://themineproject.org/index.php/about/ about
. http://themineproject.org/ home page and blog
. http://themineproject.org/index.php/feed/ rss feed (full)
. http://themineproject.org/index.php/the-mine-papers/ mine! concepts
-

: protomine! software
. http://code.google.com/p/protomine/ google code home page
. http://code.google.com/p/protomine/w/list documentation wiki
. http://code.google.com/p/protomine/updates/list updates and history
. http://code.google.com/p/protomine/issues/list bugs and bug reporting
. http://code.google.com/p/protomine/source/checkout subversion code download
-

: protomine! authors
. http://www.mediainfluencer.net/ adriana lukas, mine! inventor
. http://www.crypticide.com/dropsafe/ alec muffett, programmer / geek
-

' <p/>
' <hr/>
' <p/>

' &copy; 2008-2009 Adriana Lukas &amp; Alec Muffett;
' protomine is open source software distributed under the Apache 2.0 license,
' please see the <A HREF="http://code.google.com/p/protomine/w/list">project home page</A> for details

