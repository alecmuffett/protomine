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

# for the C-programmer in me, and you
my $BUFSIZ = 1024 * 64;

# enumeration for speed, later
my $STATIC_DIRECTORY = -2;
my $STATIC_FILE = -1;
my $DYNAMIC_ATOM = 1;
my $DYNAMIC_JSON = 2;
my $DYNAMIC_XML = 3;
my $DYNAMIC_HTML = 4;
my $DYNAMIC_PLAIN = 5;


# inverse lookup table
my %typelookup =
    (
     'application/atom+xml' => $DYNAMIC_ATOM,
     'application/json' => $DYNAMIC_JSON,
     'application/xml' => $DYNAMIC_XML,
     'text/html' => $DYNAMIC_HTML,
     'text/plain' => $DYNAMIC_PLAIN,
    );

##################################################################

# I am treating this as a private constructor in order to catch sloppy
# coding elsewhere; because there are several layered constructors
# below, I am trying to encourage *their* use instead...

sub __new {
    my $class = shift;
    my $self = {};

    $self->{TYPE} = shift;      # eg: text/html
    $self->{METHOD} = shift;    # eg: $DYNAMIC_HTML
    $self->{STATUS} = 200;      # http return status

    $self->{DATA} = [];         # where the text goes

    $self->{CTX} = undef;
    $self->{CGI} = undef;
    $self->{PATH} = undef;

    bless $self, $class;
    return $self;
}

##################################################################

sub setStatus {			# set the HTTP return code
    my $self = shift;
    my $status = shift;
    $self->{STATUS} = $status;
}

sub setXBase {                   # set the xbase header for dynamic documents
    my $self = shift;
    my $path = shift;
    my $ctx = $self->{CTX};
    $self->{URL_XBASE} = $ctx->{URL_BASE} . $ctx->{URL_DECLARED} . '/' .  $path;
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

    Log->msg("newError $http_error $error_string");

    return $p;
}

sub newFile {                   # handler for actual on-disk files
    my $class = shift;
    my $filename = shift;

    my $mimetype = &main::mime_type($filename);
    my $p = $class->__new($mimetype, $STATIC_FILE);
    $p->{PATH} = $filename;

    return $p;
}

sub newDirectory {              # handler for real dirs, or those with 'index.html', etc
    my $class = shift;
    my $dirname = shift;

    my $p = $class->__new('text/html', $DYNAMIC_HTML); # synthesised on the fly
    $p->{PATH} = $dirname;

    return $p;
}

sub newText {                   # plain text page
    my $class = shift;
    return $class->__new('text/plain', $DYNAMIC_PLAIN);
}

sub newHTML {                   # HTML page
    my $class = shift;
    return $class->__new('text/html', $DYNAMIC_HTML);
}

sub newXML {                    # XML page
    my $class = shift;
    return $class->__new('application/xml', $DYNAMIC_XML);
}

sub newJSON {                   # JSON page
    my $class = shift;
    return $class->__new('application/json', $DYNAMIC_JSON);
}

sub newATOM {                   # ATOM page
    my $class = shift;
    return $class->__new('application/atom+xml', $DYNAMIC_ATOM);
}

##################################################################

sub add {                       # add lines to the page
    my $self = shift;
    push(@{$self->{DATA}}, @_);
}

sub addList {                   # add a HTML list (listref) to the page
    my $self = shift;
    my $arg = shift;
    my $pageref = $self->{DATA};

    push(@{$pageref}, "<UL>\n");

    foreach my $line (@{$arg}) {
	push(@{$pageref}, "<LI> ");
	push(@{$pageref}, $line);
	push(@{$pageref}, "</LI>\n");
    }

    push(@{$pageref}, "</UL>\n");
}

sub addTable {                # add a HTML table (listref-of-listrefs)
    my $self = shift;
    my $arg = shift;
    my $pageref = $self->{DATA};

    push(@{$pageref}, "<TABLE>\n");

    foreach my $row (@{$arg}) {
	my $rowcount = 0;
	my $markup;

	if ($rowcount++ == 0) {
	    $markup = 'TH';
	}
	else {
	    $markup = 'TD';
	}

	push(@{$pageref}, "<TR>");                # row start
	push(@{$pageref}, "<$markup>");   # row prefix
	push(@{$pageref}, join("</$markup>\n<$markup>", @{$row})); # separator
	push(@{$pageref}, "</$markup>\n");        # row suffix
	push(@{$pageref}, "</TR>\n");     # row end
    }

    push(@{$pageref}, "</TABLE>\n");
}

sub addDictList {               # add a dictlist (hashref: KEY=NAME VALUE=BODY)
    my $self = shift;
    my $arg = shift;
    my $pageref = $self->{DATA};

    push(@{$pageref}, "<DL>\n");

    foreach my $key (sort keys %{$arg}) {
	my $value = $arg->{$key};

	push(@{$pageref}, "<DT>");
	push(@{$pageref}, $key);
	push(@{$pageref}, "</DT>\n");

	push(@{$pageref}, "<DD>");
	push(@{$pageref}, $value);
	push(@{$pageref}, "</DD>\n");
    }

    push(@{$pageref}, "</DL>\n");
}

sub addCloud {                  # add a cloud (hashref: KEY=LINK VALUE=BODY)
    my $self = shift;
    my $arg = shift;
    my $pageref = $self->{DATA};

    foreach my $key (sort keys %{$arg}) {
	my $value = $arg->{$key};
	push(@{$pageref}, "<A HREF=\"$key\">$value</A>\n");
    }
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
    my $arg = shift;
    my $pageref = $self->{DATA};

    open(ADDFILETEMPLATE, $arg) or die "addFileTemplate: open: $arg: $!\n";

    while (my $line = <ADDFILETEMPLATE>) {
	# TODO: MATCH AND SUBSTITUTE HERE
	push(@{$pageref}, $line);
    }

    close(ADDFILETEMPLATE) or die "addFileTemplate: close: $arg: $!\n";
}

sub addDirectoryHash {		# format a directory hash
    my $self = shift;
    my $arg = shift;
    my $pageref = $self->{DATA};

    my @sortkeys = sort keys %{$arg};
    my @sortorder;

    push(@sortorder, grep { $arg->{$_}->[1] eq 'directory' } @sortkeys);
    push(@sortorder, grep { $arg->{$_}->[1] ne 'directory' } @sortkeys);

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

	if ($type eq 'directory') {
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
	    return $self->addFile($indexfile);
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
	    $type = "directory";
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
    my $ctx = shift;             # takes Context as argument

    unless ($self->{METHOD} = $typelookup{$self->{TYPE}}) {
	die "printUsing: unknown page content-type '$self->{TYPE}', abort\n";
    }

    # extract the CGI object
    my $q = $ctx->cgi;

    # cache the CTX and CGI, just in case
    $self->{CTX} = $ctx;
    $self->{CGI} = $q;

    # print the HTTP header
    print $q->header(-status => $self->{STATUS}, -type => $self->{TYPE});

    # print HTML header, if appropriate
    if ($self->{METHOD} == $DYNAMIC_HTML) {
    }

    # print the body
    $self->printBody(@_);

    # print HTML footer, if appropriate
    if ($self->{METHOD} == $DYNAMIC_HTML) {
    }
}

##################################################################

sub printBody {
    my $self = shift;

    foreach my $arg (@_) {
	my $argtype = ref($arg);

	if ($argtype eq '') {
	    print $arg;
	}
	elsif ($argtype eq 'SCALAR') {
	    print ${$arg};
	}
	elsif ($argtype eq 'ARRAY') {
	    $self->printBody(@{$arg});
	}
	elsif ($argtype eq 'CODE') {
	    $self->printBody(&{$arg});
	}
	elsif ($argtype eq 'HASH') {
	    foreach my $key (sort keys %{$arg}) {
		my $value = $arg->{$key};
		print "<$key>";
		$self->printBody($value);
		print "</$key>\n";
	    }
	}
	elsif ($argtype eq 'Object') {
	    $self->printBody( { object => $arg->toDataStructure } );
	}
	elsif ($argtype eq 'Relation') {
	    $self->printBody( { relation => $arg->toDataStructure } );
	}
	elsif($argtype eq 'Tag') {
	    $self->printBody( { tag => $arg->toDataStructure } );
	}
	else {
	    die "printBody: encountered unknown object, type '$argtype'\n";
	}
    }
}

##################################################################

1;
