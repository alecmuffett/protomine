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

##################################################################

## There are 4 main kinds of object in this file
##
## 1) File - a raw unix data file
## 2) Page - a (potentially nested) listref of listrefs/things to be printed, decorated
## 3) Tree - a (potentially nested) hashref of hashrefs/things to be printed, decorated
## 4) Result - special class of Tree, different HTTP mime type, no decoration

## methods named "catFoo" send Foo to the browser in raw form
## methods named "printFoo" send Foo to the browser with decoration
## decoration => use $self->{DEFAULT_TYPE} for HTTP type, add header, footer

## a bullet-list is a listref (obvious)
## a table is a listref of listrefs; NxM
## a dictlist is a hashref; title => definition
## a cloud is a hashref; linktext => url
## a page is a listref of arbitrarily nested stuff
## a tree is a hashref of arbitrarily nested stuff

##################################################################

package MineUI;

use strict;
use warnings;

use CGI::Carp;
use CGI::Pretty;

my $BUFSIZ = 1024 * 64;         # for the C-programmer in you

##################################################################
# CONSTRUCTOR
##################################################################

## new -- returns new blank object

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    # CGI object, provided by user
    my $q = $self->{CGI} = shift;

    # /cgi-bin/mine.cgi <- provided by user
    $self->{URL_DECLARED} = shift;

    # GET / PUT / POST / DELETE / ...
    $self->{METHOD} = $q->request_method;

    # http://foo
    $self->{URL_BASE} = $q->url(-base => 1);

    # /cgi-bin/mine.cgi/path/file.ext
    $self->{URL_BODY} = $q->url(-absolute => 1, -path => 1);

    # http://foo/cgi-bin/mine.cgi/path/file.ext?foo=bar
    my $full = $self->{URL_FULL} = $q->url(-path => 1, -query => 1);

    # store the query
    if ($full =~ m!(\?.*)$!o) {
	$self->{URL_QUERY} = $1; # $foo=bar
    }
    else {
	$self->{URL_QUERY} = ''; # no query
    }

    # customised variables
    $self->boot;

    # done
    return $self;
}

##################################################################
# CLASS METHODS
##################################################################

## boot -- initialises an object; meant to be overridden in subclasses

sub boot {
    my $self = shift;

    $self->{FILE_CSS} = "database/ui/bits/mine.css";
    $self->{FILE_FOOTER} = "database/ui/bits/footer.html";
    $self->{FILE_HEADER} = "database/ui/bits/header.html";

    my $root = $self->{URL_BASE} . $self->{URL_DECLARED};

    $self->{URL_CSS}    = $root . "/ui/bits/mine.css";
    $self->{URL_FOOTER} = $root . "/ui/bits/footer.html";
    $self->{URL_HEADER} = $root . "/ui/bits/header.html";

    $self->{DEFAULT_TYPE} = "text/html";

    return $self;
}

##################################################################

# ACCESSOR METHODS

sub cgi {                       # return my CGI object
    my $self = shift;
    return $self->{CGI};
}

sub path {                      # TODO: add a cache here?
    my $self = shift;
    my $body = $self->{URL_BODY};
    my $declared = $self->{URL_DECLARED};
    die "path: url error stripping '$declared' from '$body'\n"
	unless ($body =~ s!^$declared!!);
    return $body;
}

sub method {                    # return my CGI object
    my $self = shift;
    return $self->{METHOD};
}

sub setXBase {                   # set the xbase header for dynamic documents
    my $self = shift;
    my $path = shift;
    $self->{URL_XBASE} =
	$self->{URL_BASE} .
	$self->{URL_DECLARED} .
	'/' .
	$path;
}

##################################################################

# this routine takes the accessed URL and canonicalises it, which
# should get us past most of the common sorts of security bugs; if
# there is a failure to match, a redirect is issued.

sub assertCanonicalURL {
    my $self = shift;

    # fetch the appropriate fragment
    my $clean = $self->{URL_BODY};

    # if different, issue a redirect
    $clean =~ s!/\./!/!go;      # squash "/./" -> "/"
    1 while ($clean =~ s!/[^/]+/\.\./!/!o); # squash "/foo/../" into "/"
    $clean =~ s!//+!/!go;       # squash "//" (or more) into "/"

    if ($clean ne $self->{URL_BODY}) {
	my $reconstruct =
	    $self->{URL_BASE} . # http://foo
	    $clean .            # /cgi-bin/mine.cgi/dir/
	    $self->{URL_QUERY}; # ?foo=bar

	my $q = $self->cgi;
	print $q->redirect(-uri => $reconstruct, -status => 301);
    }
}

# this routine is a no-op if the url for the query originally
# contained a trailing slash; otherwise it issues a HTTP redirect to
# the page *with* a trailing slash, for use in directory displays.

sub assertTrailingSlash {
    my $self = shift;

    # fetch the appropriate fragment
    my $path = $self->{URL_BODY};

    # if no trailing slash, issue a redirect
    unless ($path =~ m!/$!o) {
	my $reconstruct =
	    $self->{URL_BASE} . # http://foo
	    $self->{URL_BODY} . # /cgi-bin/mine.cgi/foo
	    "/" .               # trailing "/"
	    $self->{URL_QUERY}; # ?foo=bar

	my $q = $self->cgi;
	print $q->redirect(-uri => $reconstruct, -status => 301);

	exit 0;
    }
}

##################################################################

# METHODS WHICH ACTUALLY PRINT HTTP-READY OUTPUT, INCLUDING HEADERS

## printRedirect (where) -- redirect to 'where' which must lead with a '/' and be under mine root

sub printRedirect {
    my $self = shift;
    my $arg = shift;
    my $reconstruct = $self->{URL_DECLARED} . $arg;
    my $q = $self->cgi;
    print $q->redirect(-uri => $reconstruct, -status => 301);
}

## printError (code, args...) -- generate a error page, text/plain for simplicity

sub printError {
    my $self = shift;
    my ($code, @message) = @_;
    my $q = $self->cgi;
    print $q->header(-status => $code, -type => "text/plain");
    print "http error $code:\n";
    print "@message\n";
    exit 1;
}

## printFile (file) -- print a file (jpeg, mp3, whatever) to browser, setting mime type

sub printFile {
    my $self = shift;
    my $arg = shift;
    my $type = &main::mime_type($arg);
    my $q = $self->cgi;
    print $q->header(-type => $type);
    $self->catFile($arg);
}

## printFH (fh, type) -- print a FH (jpeg, mp3, whatever) to browser with mime type

sub printFH {
    my $self = shift;
    my ($fh, $type) = @_;
    my $q = $self->cgi;
    print $q->header(-type => $type);
    $self->catFH($fh);
}

## printPageUsing (...) -- print page argument, with decoration

sub printPageUsing {
    my $self = shift;
    my $type = shift;

    my $q = $self->cgi;

    print $q->header(-type => $type);

    if ($type eq 'text/html') {
	my @meta;

	my $title = sprintf "%s %s", $self->{METHOD}, $self->{URL_FULL};
	push(@meta, -title => $title);

	my $xbase = $self->{URL_XBASE};
	push(@meta, -xbase => $xbase) if (defined($xbase));

	push(@meta, -style => { -src => $self->{URL_CSS} });

	print $q->start_html(@meta);

	$self->catPageHeader;
    }

    $self->catPage(@_);

    if ($type eq 'text/html') {
	$self->catPageFooter;
	print $q->end_html;
    }
}

## printTreeUsing (...) -- print tree arguments, with decoration

sub printTreeUsing {
    my $self = shift;
    my $type = shift;

    my $q = $self->cgi;
    print $q->header(-type => $type);

    if ($type eq 'text/html') {
	my $title = sprintf "%s %s", $self->{METHOD}, $self->{URL_FULL};

	my $xbase = $self->{URL_XBASE};

	if (defined($xbase)) {
	    print $q->start_html(-title => $title, -xbase => $xbase);
	}
	else {
	    print $q->start_html($title);
	}

	$self->catPageHeader;
    }

    $self->catTree(@_);

    if ($type eq 'text/html') {
	$self->catPageFooter;
	print $q->end_html;
    }
}

sub printPageXML {
    my $self = shift;
    return $self->printPageUsing("application/xml", @_);
}

sub printTreeXML {
    my $self = shift;
    return $self->printTreeUsing("application/xml", @_);
}

sub printPageATOM {
    my $self = shift;
    return $self->printPageUsing("application/atom+xml", @_);
}

sub printTreeATOM {
    my $self = shift;
    return $self->printTreeUsing("application/atom+xml", @_);
}

sub printPageHTML {
    my $self = shift;
    return $self->printPageUsing("text/html", @_);
}

sub printTreeHTML {
    my $self = shift;
    return $self->printTreeUsing("text/html", @_);
}

sub printPageText {
    my $self = shift;
    return $self->printPageUsing("text/plain", @_);
}

sub printTreeText {
    my $self = shift;
    return $self->printTreeUsing("text/plain", @_);
}

##################################################################
##################################################################
##################################################################

# METHODS WHICH ACTUALLY PRINT STUFF

# print decoration header

sub catPageHeader {
    my $self = shift;
    my $arg = shift;

    if ($self->{FILE_HEADER} ne '') {
	$self->catFile($self->{FILE_HEADER});
    }
}

# print decoration footer

sub catPageFooter {
    my $self = shift;
    my $arg = shift;

    if ($self->{FILE_FOOTER} ne '') {
	$self->catFile($self->{FILE_FOOTER});
    }
}

# print file without decoration

sub catFile {
    my $self = shift;
    my $arg = shift;
    my $buffer;

    open(CATFILE, $arg) or die "catFile: open: $arg: $!\n";
    while (read(CATFILE, $buffer, $BUFSIZ) > 0) {
	print $buffer;
    }
    close(CATFILE) or die "catFile: close: $arg: $!\n";
}

# print filehandle without decoration

sub catFH {
    my $self = shift;
    my $arg = shift;
    my $buffer;

    while (read($arg, $buffer, $BUFSIZ) > 0) {
	print $buffer;
    }
    close($arg) or die "catFH: close: $!\n";
}

# recursively descend a nested list of scalars and listrefs and other
# references, printing them as you go...

sub catPage {
    my $self = shift;

    foreach my $arg (@_) {
	my $argtype = ref($arg);

	if ($argtype eq '') {   # if it is a primitive, print it
	    print $arg;
	}
	elsif ($argtype eq 'SCALAR') { # if it is a reference to a primitive, print it
	    print ${$arg};
	}
	elsif ($argtype eq 'ARRAY') { # if it is a listref, catPage the list
	    $self->catPage(@{$arg});
	}
	elsif ($argtype eq 'CODE') { # if it is a coderef, catPage the result of running it
	    $self->catPage(&{$arg});
	}
	elsif ($argtype eq 'HASH') { # if it is a hash, try to do something representative

	    foreach my $key (sort keys %{$arg}) {
		my $value = $arg->{$key};
		print "$key => (begin $key)";
		$self->catPage($value);
		print "(end $key)\n";
	    }
	}
	elsif ($argtype eq 'Object') {
	    print $self->catPage($arg->toPage);
	}
	elsif ($argtype eq 'Relation') {
	    print $self->catPage($arg->toPage);
	}
	elsif ($argtype eq 'Tag') {       # ditto
	    print $self->catPage($arg->toPage);
	}
	else {
	    die "catPage: encountered unknown object, type '$argtype'\n";
	}
    }
}

# catTree -- recursively descend a hash, printing as you go.

sub catTree {
    my $self = shift;

    foreach my $arg (@_) {
	my $argtype = ref($arg);

	if ($argtype eq '') {   # if it is a primitive reference, print it
	    print $arg;
	}
	elsif ($argtype eq 'SCALAR') { # reference to a primitive, print the primitive
	    print ${$arg};
	}
	elsif ($argtype eq 'ARRAY') { # reference to a list, catTree the list
	    $self->catTree(@{$arg});
	}
	elsif ($argtype eq 'CODE') { # reference to a list, catTree the result of calling it
	    $self->catTree(&{$arg});
	}
	elsif ($argtype eq 'HASH') {
	    foreach my $key (sort keys %{$arg}) {
		my $value = $arg->{$key};

		if (ref($value) eq 'ARRAY') { # special case listrefs to provide multi-values
		    print "<$key>\n";
		    my $countdown = $#{$value};
		    foreach my $element (@{$value}) {
			$self->catTree($element);
			print "\n" if ($countdown-- > 0);
		    }
		    print "\n</$key>\n";
		}
		else {          # single value key
		    print "<$key>";
		    $self->catTree($value);
		    print "</$key>\n";
		}
	    }
	}
	elsif ($argtype eq 'Object') {
	    $self->catTree( { object => $arg->toTree } );
	}
	elsif ($argtype eq 'Relation') {
	    $self->catTree( { relation => $arg->toTree } );
	}
	elsif($argtype eq 'Tag') {
	    $self->catTree( { tag => $arg->toTree } );
	}
	else {
	    die "catTree: encountered unknown object, type '$argtype'\n";
	}
    }
}

##################################################################
##################################################################
##################################################################

# FORMATTING FILESYSTEM OBJECTS

sub formatFile {
    my $self = shift;
    my $arg = shift;
    my @retval;

    open(FORMATFILE, $arg) or die "formatFile: open: $arg: $!\n";
    @retval = <FORMATFILE>;
    close(FORMATFILE) or die "formatFile: close: $arg: $!\n";
    return \@retval;
}

##################################################################

sub formatDirectory {           # format a filesystem directory
    my $self = shift;
    my $arg = shift;

    foreach my $file (qw{ index.html INDEX.HTML index.htm INDEX.HTM }) {
	my $indexfile = "$arg/$file";

	if (-f $indexfile) {
	    return $self->formatFile($indexfile);
	}
    }

    unless (opendir(DIRFILE, $arg)) {
	die "formatDirectory: cannot open directory $arg\n";
    }

    my @files = sort grep { !/^(\.|index.html?)/oi } readdir(DIRFILE);

    closedir(DIRFILE);

    my %dirhash;

    foreach my $file (@files) {
	my $type;
	my $size;

	my $this = "$arg/$file";
	if (-d $this) {
	    $type = "directory";
	    $size = 0;
	}
	else {
	    $type = &main::mime_type($file);
	    $size = (-s $this);
	}

	$dirhash{$file} = [ $size, $type ];
    }

    return $self->formatDirectoryHash(\%dirhash);
}

##################################################################

sub formatDirectoryHash {       # format a directory hash
    my $self = shift;
    my $arg = shift;
    my @retval;

    my @sortkeys = sort keys %{$arg};
    my @sortorder;

    push(@sortorder, grep { $arg->{$_}->[1] eq 'directory' } @sortkeys);
    push(@sortorder, grep { $arg->{$_}->[1] ne 'directory' } @sortkeys);

    push(@retval, "<UL>\n");

    foreach my $file (@sortorder) {
	my $info = $arg->{$file};
	my $size = $info->[0];
	my $type = $info->[1];

	my $slash;
	my $blurb;
	my $bytes;

	if ($size > 1024) {
	    $bytes = sprintf "%d Kb", int($size/1024);
	}
	else {
	    $bytes = sprintf "%d bytes", $size;
	}

	if ($type eq 'directory') {
	    $slash = '/';
	    $blurb = "directory";
	}
	else {
	    $slash = '';
	    $blurb = "$bytes, $type";
	}

	push(@retval, "<LI>");
	push(@retval, "<A HREF=\"$file$slash\">");
	push(@retval, $file);
	push(@retval, "</A>");
	push(@retval, " [$blurb]");
	push(@retval, "</LI>\n");
    }

    push(@retval, "</UL>\n");

    return \@retval;
}

##################################################################
##################################################################
##################################################################

# FORMATTING STRUCTURAL ELEMENTS

sub formatList {               # format a list (listref)
    my $self = shift;
    my $arg = shift;
    my @retval;

    push(@retval, "<UL>\n");
    foreach my $line (@{$arg}) {
	push(@retval, "<LI> ");
	push(@retval, $line);
	push(@retval, "</LI>\n");
    }
    push(@retval, "</UL>\n");

    return \@retval;
}

##################################################################

sub formatTable {               # format a table (listref-of-listrefs)
    my $self = shift;
    my $arg = shift;
    my @retval;

    push(@retval, "<TABLE>\n");
    foreach my $row (@{$arg}) {
	my $rowcount = 0;
	my $a;
	my $b;
	my $c;

	if ($rowcount++ == 0) {
	    $a = '[';
	    $b = '] [';
	    $c = ']';
	}
	else {
	    $a = '<';
	    $b = '> <';
	    $c = '>';
	}

	push(@retval, $a);                # row start
	push(@retval, join($b, @{$row})); # separator
	push(@retval, $c);                # row end
	push(@retval, "\n");              # newline
    }
    push(@retval, "</TABLE>\n");

    return \@retval;
}

##################################################################

sub formatDictList {            # format a dictlist (hashref)
    my $self = shift;
    my $arg = shift;
    my @retval;

    push(@retval, "<DL>\n");
    foreach my $key (sort keys %{$arg}) {
	my $value = $arg->{$key};

	push(@retval, "<DT>");
	push(@retval, $key);
	push(@retval, "</DT>\n");

	push(@retval, "<DD>");
	push(@retval, $value);
	push(@retval, "</DD>\n");
    }
    push(@retval, "</DL>\n");

    return \@retval;
}

##################################################################

sub formatCloud {               # format a cloud (hashref)
    my $self = shift;
    my $arg = shift;
    my @retval;

    foreach my $key (sort keys %{$arg}) {
	my $value = $arg->{$key};
	push(@retval, "<A HREF=\"$key\">$value</A>\n");
   }

    return \@retval;
}

##################################################################
##################################################################
##################################################################

sub toString {
    my $self = shift;
    my @retval;
    my $key;
    my $value;
    my $q;
    my $v;

    $q = $self->{CGI};
    $v = $q->Vars;

    push(@retval, "========================================\n");
    push(@retval, "MineUI Dump\n");

    foreach $key (sort keys %{$self}) {
	$value = $self->{$key};
	push(@retval, "MineUI $key: $value\n");
    }


    push(@retval, "----------------------------------------\n");
    push(@retval, "CGI Dump\n");

    foreach $key (sort keys %{$q}) {
	$value = $q->{$key};
	push(@retval, "CGI $key: $value\n");
    }

    push(@retval, "----------------------------------------\n");
    push(@retval, "Param Dump\n");

    foreach $key (sort keys %{$v}) {
	$value = $v->{$key};
	push(@retval, "Param $key: $value\n");
    }

    push(@retval, "========================================\n");

    return join('', @retval);
}

1;
