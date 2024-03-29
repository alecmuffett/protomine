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

package Page;

use strict;
use warnings;

use JSON::XS;
use Data::Dumper;
use HTML::Template;

# for the C-programmer in me, and you
my $BUFSIZ = 1024 * 64;
my $DIRMAGIC = '[directory]';
my $ENCODING = 'UTF-8';

# enumeration for speed, later
my $REWRITE_FILE = -2;
my $STATIC_FILE = -1;
my $DYNAMIC_PLAIN = 1;
my $DYNAMIC_XML = 2;
my $DYNAMIC_HTML = 3;
my $DYNAMIC_JSON = 4;
my $DYNAMIC_PERL = 5;		# not for public use

##################################################################

# I am treating this as a private constructor in order to catch sloppy
# coding elsewhere; because there are several layered constructors
# below, I am trying to encourage *their* use instead...

sub __new {
    my $class = shift;
    my $self = {};

    $self->{TYPE} = shift;      # eg: text/html
    $self->{STYLE} = shift;    # eg: $DYNAMIC_HTML

    $self->{DATA} = [];         # where the text goes
    $self->{STATUS} = 200;      # http return status

    $self->{CTX} = undef;	# ref to Context
    $self->{CGI} = undef;	# ref to CGI
    $self->{PATH} = undef;	# filename or dirname
    $self->{XBASE} = undef;	# xbase path

    bless $self, $class;
    return $self;
}

##################################################################

sub setStatus {			# set the HTTP return code
    my $self = shift;
    my $arg = shift;
    $self->{STATUS} = $arg;
}

##################################################################

sub newError {                  # handler for error pages
    my $class = shift;
    my $http_error = shift || 500;
    my $error_string = shift;

    my $p = $class->__new('text/plain', $DYNAMIC_PLAIN); # i like plain text error pages

    $p->setStatus($http_error);

    if (defined($error_string)) {
	$p->add($error_string);
    }

    Log->msg("http_error $http_error $error_string");

    return $p;
}

sub newFile {                   # handler for actual on-disk files
    my $class = shift;
    my $filename = shift;
    my $mimetype = shift || &main::mime_type($filename);

    my $p = $class->__new($mimetype, $STATIC_FILE);
    $p->{PATH} = $filename;	# reading the file is deferred
    return $p;
}

sub newFileRewrite {		# handler for actual on-disk files
    my $class = shift;
    my $minekey = shift;
    my $filename = shift;
    my $mimetype = shift || &main::mime_type($filename);

    my $p = $class->__new($mimetype, $REWRITE_FILE);
    $p->{PATH} = $filename;	# reading the file is deferred
    $p->{MINEKEY} = $minekey;
    return $p;
}

sub newDirectory {              # handler for real dirs, or those with 'index.html', etc
    my $class = shift;
    my $dirname = shift;

    my $p = $class->__new('text/html', $DYNAMIC_HTML); # synthesised on the fly
    $p->{PATH} = $dirname;
    $p->addDirectory($dirname);	# reading the directory is immediate
    return $p;
}

sub newHTML {                   # HTML page: DIFFERENT !!! HTML Constructor takes XBASE as 1st argument !!!
    my $class = shift;
    my $xbase = shift;

    my $p = $class->__new('text/html', $DYNAMIC_HTML); # subject to header/footer, css, etc
    $p->{XBASE} = $xbase;
    return $p;
}

sub newText {                   # plain text page
    my $class = shift;
    my $p = $class->__new('text/plain', $DYNAMIC_PLAIN);
    $p->add(@_) if ($#_ >= 0);
    return $p;
}

sub newXML {                    # XML page
    my $class = shift;
    my $p = $class->__new('application/xml', $DYNAMIC_XML);
    $p->add(@_) if ($#_ >= 0);
    return $p;
}

sub newJSON {                   # JSON page
    my $class = shift;
    my $p = $class->__new('application/json', $DYNAMIC_JSON);
    $p->add(@_) if ($#_ >= 0);
    return $p;
}

sub newPerl {                   # Perl page
    my $class = shift;
    my $p = $class->__new('text/plain', $DYNAMIC_PERL);
    $p->add(@_) if ($#_ >= 0);
    return $p;
}

sub newAtom {                   # ATOM page
    my $class = shift;
    my $p = $class->__new('application/atom+xml', $DYNAMIC_XML);
    $p->add(@_) if ($#_ >= 0);
    return $p;
}

##################################################################

sub add {                       # add lines to the page
    my $self = shift;
    push(@{$self->{DATA}}, @_);
}

sub addFileContent {            # add the contents of a file to the page
    my $self = shift;
    my $arg = shift;

    open(ADDFILECONTENT, $arg) or die "addFileContent: open: $arg: $!\n";
    push(@{$self->{DATA}}, <ADDFILECONTENT>);
    close(ADDFILECONTENT) or die "addFileContent: close: $arg: $!\n";
}

sub addFileTemplate {           # add the contents of a template to the page, substituted
    my $self = shift;
    my $filename = shift;
    my $paramref = shift;

    my $template = HTML::Template->new(filename => "database/ui/$filename",
				       die_on_bad_params => 1,
				       strict => 1,
				       case_sensitive => 1,
				       loop_context_vars => 1,
				       no_includes => 1,
				       default_escape => 'HTML',
				       @_); # any other inherited args, eg: caching

    $template->param($paramref);

    my $pageref = $self->{DATA};


    push(@{$pageref}, "<!-- begin template $filename -->\n");
    my @debug = keys %{$paramref};
    push(@{$pageref}, "<!-- debug keys='@debug' -->\n");
    push(@{$pageref}, $template->output());
    push(@{$pageref}, "<!-- end template $filename -->\n");
}

sub addDirectoryHash {		# format a directory hash
    my $self = shift;
    my $arg = shift;
    my $pageref = $self->{DATA};

    my @sortkeys = sort keys %{$arg};
    my @sortorder;

    push(@sortorder, grep { $arg->{$_}->[1] eq $DIRMAGIC } @sortkeys);
    push(@sortorder, grep { $arg->{$_}->[1] ne $DIRMAGIC } @sortkeys);

    push(@{$pageref}, "<UL>\n");

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

	if ($type eq $DIRMAGIC) {
	    $slash = '/';
	    $blurb = "directory";
	}
	else {
	    $slash = '';
	    $blurb = "$bytes, $type";
	}

	push(@{$pageref}, "<LI>");
	push(@{$pageref}, "<A HREF=\"$file$slash\">");
	push(@{$pageref}, $file);
	push(@{$pageref}, "</A>");
	push(@{$pageref}, " [$blurb]");
	push(@{$pageref}, "</LI>\n");
    }

    push(@{$pageref}, "</UL>\n");
}

sub addDirectory {           # format a filesystem directory
    my $self = shift;
    my $arg = shift;

    foreach my $file (qw{ index.html INDEX.HTML index.htm INDEX.HTM }) {
	my $indexfile = "$arg/$file";

	if (-f $indexfile) {
	    return $self->addFileContent($indexfile);
	}
    }

    unless (opendir(DIRFILE, $arg)) {
	die "addDirectory: cannot open directory $arg\n";
    }

    my @files = sort grep { !/^(\.|index.html?)/oi } readdir(DIRFILE);

    closedir(DIRFILE);

    my %dirhash;

    foreach my $file (@files) {
	my $type;
	my $size;

	my $this = "$arg/$file";
	if (-d $this) {
	    $type = $DIRMAGIC; # has to be a non-mime-type
	    $size = 0;
	}
	else {
	    $type = &main::mime_type($file);
	    $size = (-s $this);
	}

	$dirhash{$file} = [ $size, $type ];
    }

    $self->addDirectoryHash(\%dirhash);
}

##################################################################
##################################################################
##################################################################

sub printFile {
    my $self = shift;
    my $arg = shift;
    my $buffer;

    open(PRINTFILE, $arg) or die "printFile: open: $arg: $!\n";
    while (read(PRINTFILE, $buffer, $BUFSIZ) > 0) {
	print $buffer;
    }
    close(PRINTFILE) or die "printFile: close: $arg: $!\n";
}

##################################################################

sub printUsing {
    my $self = shift;
    my $ctx = shift;		# takes Context as argument

    # extract the CGI object
    my $q = $ctx->cgi;

    # cache the CTX and CGI, just in case
    $self->{CTX} = $ctx;
    $self->{CGI} = $q;

    unless ($self->{STYLE}) {
	die "printUsing: unknown page style, abort\n";
    }

    # deal with static files, fast
    if ($self->{STYLE} == $STATIC_FILE) {
	my $file = $self->{PATH};
	my $bytes = (-s $file);

	print $q->header(-type => $self->{TYPE}, -Content_length => $bytes);

	$self->printFile($file);

	return;
    }
    elsif ($self->{STYLE} == $REWRITE_FILE) {
	my $file = $self->{PATH};
	my $mk = $self->{MINEKEY};

	print $q->header(-type => $self->{TYPE});

	open(REWRITEFILE, $file) or die "printUsing: rewrite_file: open: $file: $!\n";

	my $buffer;

	while ($buffer = <REWRITEFILE>) {
	    print $mk->rewrite($buffer);
	}

	close(REWRITEFILE) or die "printUsing: rewritefile: close: $file: $!\n";

	return;
    }

    # print the HTTP header
    print $q->header(-status => $self->{STATUS},
		     -type => $self->{TYPE},
		     -charset => $ENCODING);

    # print HTML header, if appropriate
    if ($self->{STYLE} == $DYNAMIC_HTML) {
        my @meta;

        my $title = sprintf "%s %s", $ctx->method, $ctx->path;

	push(@meta, -encoding => $ENCODING);
	push(@meta, -title => $title);
	push(@meta, -style => { -src => $ctx->{URL_CSS} });
	if (defined($self->{XBASE})) {
	    push(@meta, -xbase => $ctx->{URL_BASE} . $ctx->{URL_DECLARED} . '/' .  $self->{XBASE});
	}

        print $q->start_html(@meta);

	my $header = $ctx->{FILE_HEADER};
	$self->printFile($header) if ($header ne '');
    }

    # print the body
    if ($self->{STYLE} == $DYNAMIC_PLAIN) {
	$self->printBodyXML($self->{DATA}); # works equally well
    }
    elsif ($self->{STYLE} == $DYNAMIC_XML) {
	$self->printBodyXML($self->{DATA});
    }
    elsif ($self->{STYLE} == $DYNAMIC_HTML) {
        $self->printBodyHTML($self->{DATA});
    }
    elsif ($self->{STYLE} == $DYNAMIC_JSON) {
	my $root;

	if ($#{$self->{DATA}} == 0) {
	    $root = $self->{DATA}->[0];
	}
	else {
	    $root = $self->{DATA};
	}
	my $json = new JSON::XS;
	print $json->encode($root);
	print "\n";
    }
    elsif ($self->{STYLE} == $DYNAMIC_PERL) {
	my $root;

	if ($#{$self->{DATA}} == 0) {
	    $root = $self->{DATA}->[0];
	}
	else {
	    $root = $self->{DATA};
	}

	my $d = Data::Dumper->new( [ $root ] );
	$d->Purity(1);
	$d->Indent(1);
	print $d->Dump; 
	print "\n";
    }
    else {
	die "printUsing: this can't happen";
    }

    # print HTML footer, if appropriate
    if ($self->{STYLE} == $DYNAMIC_HTML) {
	my $footer = $ctx->{FILE_FOOTER};
	$self->printFile($footer) if ($footer ne '');

        print $q->end_html;
    }
}

##################################################################

sub printBodyXML {
    my $self = shift;

    foreach my $arg (@_) {
	my $argtype = ref($arg);

	if ($argtype eq '') {	# if it's primitive, print it
	    print $arg;
	}
	elsif ($argtype eq 'SCALAR') { # if ref of primitive, print THAT
	    print ${$arg};
	}
	elsif ($argtype eq 'ARRAY') { #
	    $self->printBodyXML(@{$arg});
	}
	elsif ($argtype eq 'HASH') {
	    foreach my $key (sort keys %{$arg}) {
		my $value = $arg->{$key};
		print "<$key>";
		$self->printBodyXML($value);
		print "</$key>\n";
	    }
	}
	elsif ($argtype eq 'Object') {
	    $self->printBodyXML( { object => $arg->toDataStructure } );
	}
	elsif ($argtype eq 'Relation') {
	    $self->printBodyXML( { relation => $arg->toDataStructure } );
	}
	elsif($argtype eq 'Tag') {
	    $self->printBodyXML( { tag => $arg->toDataStructure } );
	}
	else {
	    die "printBodyXML: encountered unknown object, type '$argtype'\n";
	}
    }
}

##################################################################

sub printBodyHTML {
    my $self = shift;

    foreach my $arg (@_) {
	my $argtype = ref($arg);

	if ($argtype eq '') {	# if it's primitive, print it
	    print $arg;
	}
	elsif ($argtype eq 'SCALAR') { # if ref of primitive, print THAT
	    print ${$arg};
	}
	elsif ($argtype eq 'ARRAY') { #
	    # print "<ul>\n";
	    # foreach my $li (@{$arg}) {
	    # print "<li>";
	    # $self->printBodyHTML($li);
	    # print "</li>\n";
	    # }
	    # print "</ul>\n";

	    $self->printBodyHTML(@{$arg});
	}
	elsif ($argtype eq 'HASH') {

	    print "<dl>\n";
	    foreach my $key (sort keys %{$arg}) {
                print "<dt>\n";
		print $key;
                print "</dt>\n";

		print "<dd>\n";
		my $value = $arg->{$key};
		$self->printBodyHTML($value);
		print "</dd>\n";
	    }
	    print "</dl>\n";
	}
	elsif ($argtype eq 'Object') {
	    $self->printBodyHTML( $arg->toDataStructure );
	}
	elsif ($argtype eq 'Relation') {
	    $self->printBodyHTML( $arg->toDataStructure );
	}
	elsif($argtype eq 'Tag') {
	    $self->printBodyHTML( $arg->toDataStructure );
	}
	else {
	    die "printBodyHTML: encountered unknown object, type '$argtype'\n";
	}
    }
}

##################################################################

1;
