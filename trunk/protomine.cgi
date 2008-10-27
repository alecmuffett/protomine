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

use strict;
use warnings;
use diagnostics;

use CGI qw/:standard/;
use CGI::Carp;
use CGI::Pretty;

# what the mine base URL is
my $cgi_mine = "/~alecm/mine";	# NO TRAILING SLASH

# where the mine lives
my $base_directory = "/Users/alecm/protomine";

# directory where we write log info; must be writable by http daemon
my $log_dir = "database/logs";

# set to 0 for debugging in apache errlog
my $trap_exceptions_to_http = 1;

##################################################################

# go to the mine home directory

chdir($base_directory) or die "chdir: $base_directory: $!";

# get the extra stuff we need

require 'mine/pm-api.pl';
require 'mine/pm-ui.pl';
require 'mine/pm-time.pl';

require 'mine/MineUI.pl';

require 'mine/Thing.pl';
require 'mine/Object.pl';
require 'mine/Relation.pl';
require 'mine/Tag.pl';

# impose a 10Mb ceiling on POST data

$CGI::POST_MAX = 10 * (1024**2);

# mappings from CRUD to HTTP for readability

my %crud = (
    CREATE => 'POST',		# REST
    READ => 'GET',		# REST
    UPDATE => 'PUT',		# REST
    DELETE => 'DELETE',		# REST/HTTP
    POST => 'POST',		# HTTP
    GET => 'GET',		# HTTP
    PUT => 'PUT',		# HTTP
    );

# the table of paths and their handlers/arguments; IMPORTANT: DO NOT
# USE PARENTHESIS IN THE PATHS IF YOU ARE ALSO USING PARAMETERS

# the joy of this mechanism is that if we want to create/try an
# alternative almost wholly GET-based API, we can implement it in less
# than 5 minutes.

# you can guess, that the ".xml" suffix will soon be supplanted by
# ".FORMAT" and a smart switch will provide output in the preferred
# format for most URLs

# the order of these rules *is* significant, and you must factor the
# METHOD into the match as well as the URL; for instance performing
# "GET /foo/bar" will not match "POST /foo/bar" but *will* match a
# subsequent "GET /foo/SUFFIX"

my @raw_action_list = (
    [ '/test', 'GET', \&test_test ],

    # empty / root request
    [ '', 'GET', \&do_redirect, '/ui/' ],

    # documentation
    [ '/doc', 'GET', \&do_document, 'database/doc', '.' ],
    [ '/doc/SUFFIX', 'GET', \&do_document, 'database/doc', 'SUFFIX' ],

    # the /feed/ hierarchy is a special case HTTP
    [ '/feed/COOKIE', 'GET', \&do_feed, 'GET', ],

    # the /ui/ hierarchy lives in HTTP space -- POST METHODS
    [ '/ui/update-tag/TID.html', 'POST', \&ui_update_tag, 'TID' ], # NEEDS A DYNAMIC GET
    [ '/ui/update-relation/RID.html', 'POST', \&ui_update_relation, 'RID' ], # NEEDS A DYNAMIC GET
    [ '/ui/update-object/OID.html', 'POST', \&ui_update_object, 'OID' ], # NEEDS A DYNAMIC GET
    [ '/ui/update-data/OID.html', 'POST', \&ui_update_data, 'OID' ], # NEEDS A DYNAMIC GET
    [ '/ui/update-config.html', 'POST', \&ui_update_config ],
    [ '/ui/create-tag.html', 'POST', \&ui_create_tag ],
    [ '/ui/create-relation.html', 'POST', \&ui_create_relation ],
    [ '/ui/create-object.html', 'POST', \&ui_create_object ],

    # (eventually) template-based dynamic GETS for POSTS above
    [ '/ui/update-tag/TID.html', 'GET', \&do_document, 'database/ui', 'update-tag-xxx.html' ],
    [ '/ui/update-relation/RID.html', 'GET', \&do_document, 'database/ui', 'update-relation-xxx.html' ],
    [ '/ui/update-object/OID.html','GET', \&do_document, 'database/ui', 'update-object-xxx.html' ],
    [ '/ui/update-data/OID.html', 'GET', \&do_document, 'database/ui', 'update-data-xxx.html' ],

    # the /ui/ hierarchy lives in HTTP space -- GET METHODS
    [ '/ui/version.html', 'GET', \&ui_version ],
    [ '/ui/show-tags.html', 'GET', \&ui_show_tags ],
    [ '/ui/show-relations.html', 'GET', \&ui_show_relations ],
    [ '/ui/show-objects.html', 'GET', \&ui_show_objects ],
    [ '/ui/show-config.html', 'GET', \&ui_show_config ],
    [ '/ui/show-clones/OID.html', 'GET', \&ui_show_clones, 'OID' ],
    [ '/ui/share/url/RID/OID.html', 'GET', \&ui_share_url, 'RID', 'RVSN', 'OID' ],
    [ '/ui/share/url/RID.html', 'GET', \&ui_share_url, 'RID', 'RVSN', 'OID' ],
    [ '/ui/share/redirect/RID/OID', 'GET', \&ui_share_redirect, 'RID', 'RVSN', 'OID' ],
    [ '/ui/share/redirect/RID', 'GET', \&ui_share_redirect, 'RID', 'RVSN', 'OID' ],
    [ '/ui/share/raw/RID/RVSN/OID', 'GET', \&ui_share_raw, 'RID', 'RVSN', 'OID' ],
    [ '/ui/select/tag.html', 'GET', \&ui_select_tag ],
    [ '/ui/select/relation.html', 'GET', \&ui_select_relation ],
    [ '/ui/select/object.html', 'GET', \&ui_select_object ],
    [ '/ui/read-tag/TID.html', 'GET', \&ui_read_tag, 'TID' ],
    [ '/ui/read-relation/RID.html', 'GET', \&ui_read_relation, 'RID' ],
    [ '/ui/read-object/OID.html', 'GET', \&ui_read_object, 'OID' ],
    [ '/ui/read-data/OID', 'GET', \&api_read_oid_aux, 'OID' ], # same as API
    [ '/ui/delete-tag/TID.html', 'GET', \&ui_delete_tag, 'TID' ],
    [ '/ui/delete-relation/RID.html', 'GET', \&ui_delete_relation, 'RID' ],
    [ '/ui/delete-object/OID.html', 'GET', \&ui_delete_object, 'OID' ],
    [ '/ui/clone-object/OID.html', 'GET', \&ui_clone_object, 'OID' ],

    # catchall for the methods above; we may pick up a *file* for
    # "GET" which corresponds with something that is "POST" above.
    [ '/ui', 'GET', \&do_document, 'database/ui', '.' ],
    [ '/ui/SUFFIX', 'GET', \&do_document, 'database/ui', 'SUFFIX' ],

    # the /api/ hierarchy lives in REST space
    [ '/api/version.xml', 'READ', \&do_xml, \&api_version  ],
    [ '/api/tag/TID.xml', 'UPDATE', \&do_xml, \&api_update_tid, 'TID' ],
    [ '/api/tag/TID.xml', 'READ', \&do_xml, \&api_read_tid, 'TID' ],
    [ '/api/tag/TID.xml', 'DELETE', \&do_xml, \&api_delete_tid, 'TID' ],
    [ '/api/tag.xml', 'READ', \&do_xml, \&api_list_tags ],
    [ '/api/tag.xml', 'CREATE', \&do_xml, \&api_create_tag ],
    [ '/api/share/url/RID/OID.xml', 'READ', \&do_xml, \&api_share_url, 'OID', 'RID' ],
    [ '/api/share/url/RID.xml', 'READ', \&do_xml, \&api_share_url, 'RID' ],
    [ '/api/share/redirect/RID/OID.xml', 'READ', \&do_xml, \&api_share_redir, 'OID', 'RID' ],
    [ '/api/share/redirect/RID.xml', 'READ', \&do_xml, \&api_share_redir, 'RID' ],
    [ '/api/share/raw/RID/RVSN/OID.xml', 'READ', \&do_xml, \&api_share_url, 'OID', 'RID', 'RVSN' ],
    [ '/api/select/tag.xml', 'READ', \&do_xml, \&api_noop ],
    [ '/api/select/relation.xml', 'READ', \&do_xml, \&api_noop ],
    [ '/api/select/object.xml', 'READ', \&do_xml, \&api_noop ],
    [ '/api/relation/RID.xml', 'UPDATE', \&do_xml, \&api_update_rid, 'RID' ],
    [ '/api/relation/RID.xml', 'READ', \&do_xml, \&api_read_rid, 'RID' ],
    [ '/api/relation/RID.xml', 'DELETE', \&do_xml, \&api_delete_rid, 'RID' ],
    [ '/api/relation.xml', 'READ', \&do_xml, \&api_list_relations ],
    [ '/api/relation.xml', 'CREATE', \&do_xml, \&api_create_relation ],
    [ '/api/object/OID/clone.xml', 'READ', \&do_xml, \&api_list_clones, 'OID' ],
    [ '/api/object/OID/clone.xml', 'CREATE', \&do_xml, \&api_create_clone, 'OID' ],
    [ '/api/object/OID.xml', 'UPDATE', \&do_xml, \&api_update_oid, 'OID' ],
    [ '/api/object/OID.xml', 'READ', \&do_xml, \&api_read_oid, 'OID' ],
    [ '/api/object/OID.xml', 'DELETE', \&do_xml, \&api_delete_oid, 'OID' ],
    [ '/api/object/OID', 'UPDATE', \&do_xml, \&api_update_oid_aux, 'OID' ],
    [ '/api/object/OID', 'READ', \&api_read_oid_aux, 'OID' ], # *** AUX, EMITS RAW DATA ***
    [ '/api/object.xml', 'READ', \&do_xml, \&api_list_objects ],
    [ '/api/object.xml', 'CREATE', \&do_xml, \&api_create_object ],
    [ '/api/config.xml', 'UPDATE', \&do_xml, \&api_update_config ],
    [ '/api/config.xml', 'READ', \&do_xml, \&api_read_config ],
    );

# where the compiled actions will reside

my @action_list = ();

##################################################################

# compile the action list
&compile_action_list;

# run the query - eventually make this into fast_cgi?
if (1) {
    # log it using the environment variables for safety
    &log(sprintf "env %s %s %s", 
	 $ENV{REMOTE_ADDR}, 
	 $ENV{REQUEST_METHOD}, 
	 $ENV{REQUEST_URI});

    # rip the CGI query
    my $q = new CGI;

    # create a UI from it
    my $ui = new MineUI($q, $cgi_mine);

    # if there was an error during decoding, fail noisily
    my $cgi_error = $q->cgi_error;

    if ($cgi_error) {
	my $diag = "cgi decoding error: $cgi_error";
	print $ui->printError(500, $diag);
	die $diag;
    }

    if ($trap_exceptions_to_http) {
	# execute the CGI input against the action list
	eval { &match_and_execute($ui); } ; # nb: eval block needs ';'

	if ($@) {		# did we barf?
	    my $diag = "software exception: $@\n";
	    print $ui->printError(500, $diag);
	    warn $diag;
	}
    }
    else {
	&match_and_execute($ui);
    }
}

# done

exit 0;

##################################################################

# error logging routines

sub log {
    my ($file, $tag) = &yyyyLogInfo;
    my $path = "$log_dir/$file";

    my $msg = "@_";
    $msg =~ s/\s+/ /go;

    open(LOG, ">>$path") || die "open: >>$path: $!";
    print LOG "$tag $$ $msg\n";
    close(LOG);
}

###################################################################
# this routine relates to the pseudo-urls in @raw_action_list; the
# uppercase tokens in the pseudo-URL get ripped out and replaced by the
# regular expressions below.

sub smart_token {
    my $token = shift;

    return '(xml|json)' if ($token eq 'FMT'); # xml, json, html, text, atom, ...

    return '\d+' if ($token eq 'OID');
    return '\d+' if ($token eq 'RID');
    return '\d+' if ($token eq 'RVSN');
    return '\d+' if ($token eq 'TID');
    return '\w+' if ($token eq 'COOKIE');

    return '.*'  if ($token eq 'SUFFIX'); # magic names - greedy wildcard
    return '.*?' if ($token eq 'TEXT\d*'); # magic names - conservative wildcard
    return '\d+' if ($token =~ m!NUM\d+!o);    # magic names - NUM001
    return '\w+' if ($token =~ m!WORD\d+!o);   # magic names - WORD001

    return '[\-\.\w]+';
}

##################################################################

# this routine relates to @raw_action_list and generates @action_list

# the pseudo-URLs in the former are compiled into regular expressions,
# where all uppercase tokens of the form FRED or FRED001 (etc) get
# ripped-out and replaced with regexp fragments as returned by
# &smart_token; the tokens are memorised (left to right) and when the
# URL-regexp (anchored at head and tail) is successfully matched
# against a CGI-URL, the substrings will be saved as values in an
# anonymous hash, indexed by tokens as keys.

# further, any members of @args which match a parameter name, will
# be substituted upon execution.

# in short, a raw action that looks like:
#
#   [ '/foo/TEXT1/wibble', 'READ', \&api_foo, 1, 2, 'TEXT1' ],
#
# ...shall end up in the match-execute function and:
#
# 1) match the URL '/foo/bar/wibble'
# 2) create a paramhashref: $phr = { TEXT1 => 'bar' }
# 3) invoke &api_foo($cgi, $info, $phr, 1, 2, 'bar');
#
# It is expected that most access to parameters will be done via
# $phr, but as a convenience to the programmer if a parameter is
# named amongst the list of arguments, it will be substituted so that
# it also appears on the handler argument list
#
# NB: There is a hard limit of 9 tokens enforced by the execution code.
# NB: $phr will be undef if there are no parameters to store/parse

sub compile_action_list {
    foreach my $lref (@raw_action_list) {
	my ($url, $crud_method, $handler, @args) = @{$lref};

	# extract and memorise the url pattern

	my @paramlist = ();
	my $regexp = $url;

	# escape dots
	$regexp =~ s!\.!\\.!go;

	# extract all uppercase words from the url pattern, push them
	# on paramlist replacing them with a regexp token

	while ($regexp =~ s/([A-Z]+\d*)/'(' . &smart_token($1) . ')'/e) {
	    push(@paramlist, $1);
	}

	# compile the new pattern and replace the url pattern with that
	my $pattern = qr!^${regexp}/?$!i;

	# have we any params?
	my $paramlistref = ($#paramlist < 0) ? undef : \@paramlist;

	# translate the crud
	my $method = $crud{$crud_method};

	# stash the compiled action
	push( @action_list, [ $method, $pattern, $paramlistref, $handler, @args ] );
    }
}

###################################################################

# this is the main routine which encodes parameters and calls handlers
# as described in the notes for &compile_action_list

sub match_and_execute {
    my $ui = shift;

    # sanity-check the supplied URL with any query info;
    $ui->assertCanonicalURL;

    # memorise the important stuff
    my $cgi_method = $ui->method;

    # sanity check the method, and provide the PUT/DELETE workaround

    if ($cgi_method eq 'GET' or $cgi_method eq 'POST') {
	my $p;
	my $q = $ui->cgi;

	if (defined($p = $q->param('_method'))) {
	    if ($p eq 'POST' or	# POST->POST is redundant but not a risk
		$p eq 'PUT' or
		$p eq 'DELETE') {
		$cgi_method = $p;
	    }
	    else {
		die "illegal value for _method: $p";
	    }
	}
    }
    elsif ($cgi_method eq 'PUT') {	# TODO: rewrite this
	# $cgi_data = $q->param('POSTDATA');
	# $cgi_datafh = *STDIN;
    }

    my $cgi_url = $ui->path;

    # skim through the action list and find work

    foreach my $action (@action_list) {
	my ($method, $pattern, $paramlistref, $handler, @args) = @{$action};

	next unless ($cgi_method eq $method); # skip if wrong method
	next unless ($cgi_url =~ /$pattern/); # skip if not matching pattern

	# this is where we store key/value pairs from the regular
	# expression substring matcher

	my %paramhash = ();

	# do we need to do argument processing?
	if (defined($paramlistref)) {
	    # build the %paramhash
	    my @paramlist = @{$paramlistref};

	    $paramhash{$paramlist[0]} = $1 if ($#paramlist >= 0);
	    $paramhash{$paramlist[1]} = $2 if ($#paramlist >= 1);
	    $paramhash{$paramlist[2]} = $3 if ($#paramlist >= 2);
	    $paramhash{$paramlist[3]} = $4 if ($#paramlist >= 3);
	    $paramhash{$paramlist[4]} = $5 if ($#paramlist >= 4);
	    $paramhash{$paramlist[5]} = $6 if ($#paramlist >= 5);
	    $paramhash{$paramlist[6]} = $7 if ($#paramlist >= 6);
	    $paramhash{$paramlist[7]} = $8 if ($#paramlist >= 7);
	    $paramhash{$paramlist[8]} = $9 if ($#paramlist >= 8);

	    # check the handler arguments for paramhash variables and
	    # substitute them if you find them

	    for (my $i = 0 ; $i <= $#args; $i++) {
		my $replace = $args[$i];
		if (defined($paramhash{$replace})) {
		    $args[$i] = $paramhash{$replace};
		}
	    }
	}

	# handler takes pattern and url as well as arguments for
	# verbose info; the structured programmer in me would love to
	# take a return value here and print it using a method
	# selected in the table of actions, but in truth there are too
	# many side-effects and "drop back 10 yards and punt"
	# scenarios that frankly i can't be arsed;

	return &{$handler}($ui, [$cgi_method, $cgi_url, $pattern], \%paramhash, @args);
    }

    # if we get here, we fell of the list of regular expressions
    $ui->printError(404, "no handler for $cgi_method $cgi_url");
}

##################################################################

# this is the dummy no-op handler, use it as a template for other
# handlers; it just dumps information to the browser

sub do_noop {
    my ($ui, $info, $phr, @args) = @_;
    $ui->printPage("noop @args");
}

##################################################################

# redirect whatever url to $target

sub do_redirect {
    my ($ui, $info, $phr, $target) = @_;
    print $ui->printRedirect($target);
}

##################################################################

# stub to print whatever a API returns, as a *page*

sub do_apidump {
    my ($ui, $info, $phr, $fn, @rest) = @_;
    $ui->printPage(&{$fn}($ui, $info, $phr, @rest));
}

##################################################################

# stub to print whatever a API returns, as a *result*

sub do_xml {
    my ($ui, $info, $phr, $fn, @rest) = @_;
    $ui->printResult(&{$fn}($ui, $info, $phr, @rest));
}

##################################################################

sub do_feed {
    die "method not yet implemented";
}

##################################################################

# handle an actual proper document request

sub do_document {
    my ($ui, $info, $phr, $root, $cited) = @_;

    my $document = "$root/$cited";

    if (-d $document) {
	$ui->assertTrailingSlash;

	my @page;
	push(@page, $ui->formatDirectory($document));
	$ui->printPage(@page);
    }
    elsif (-f $document) {
	$ui->printFile($document);
    }
    else {
	$ui->printError(404, "cannot do_document $document");
    }
}

##################################################################

# stub for faffing about

sub test_test {
    my ($ui, $info, $phr) = @_;

    my $oids = Object->list;
    my @output;

    push(@output, "<ul>" );
    foreach my $oid (@{$oids}) {
	push(@output, "<li> <b>$oid:</b> " );
	push(@output, { "api/object/$oid/", "[view]" } );
	push(@output, { "api/object/$oid/", "[update]" } );
	push(@output, { "api/object/$oid/", "[view description]" } );
	push(@output, { "api/object/$oid/", "[update description]" } );
	push(@output, { "api/object/$oid/", "[delete]" } );
	push(@output, "</li>\n" );
    }
    push(@output, "</ul>\n" );

    $ui->printPage(\@output);
}

##################################################################

1;
