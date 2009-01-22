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

#  $LINT  external  Carp            cgi::module
#  $LINT  external  Pretty          cgi::module
#  $LINT  external  POST_MAX        cgi::scalar
#  $LINT  external  Template        html::template
#  $LINT  external  SUPER           superclass
#  $LINT  external  XS              module
#  $LINT  external  cgi_error       cgi::method
#  $LINT  external  encode          json::xs     method
#  $LINT  external  end_html        cgi::method
#  $LINT  external  header          cgi::method
#  $LINT  external  param           cgi::method
#  $LINT  external  pretty          json::xs     method
#  $LINT  external  redirect        cgi::method
#  $LINT  external  request_method  cgi::method
#  $LINT  external  start_html      cgi::method
#  $LINT  external  upload          cgi::method
#  $LINT  external  url             cgi::method

package main;

use strict;
use warnings;
use diagnostics;

use CGI qw/:standard/;
use CGI::Carp;
use CGI::Pretty;

# global variables

our $MINE_DIRECTORY;      
our $MINE_HTTP_FULLPATH;  
our $MINE_HTTP_PATH;      
our $MINE_HTTP_SERVER;    

# standard config for this system
my $execdir = $0;
$execdir =~ s![^/]+$!!g;
require "$execdir/protomine-config.pl";

# impose a 10Mb ceiling on POST data

$CGI::POST_MAX = 10 * (1024**2);

# go to the mine home directory

chdir($MINE_DIRECTORY) or die "chdir: $MINE_DIRECTORY: $!";

##################################################################

# this is the table of paths and their handlers/arguments; the joy of
# this mechanism is that if we want to create/try an alternative
# almost wholly GET-based API, we can implement it in less than 10
# minutes.

# IMPORTANT: you must factor the METHOD into the match as well as the
# URL, *and* the order of these rules *is* significant; for instance
# performing "GET /foo/bar" will not match "POST /foo/bar" but *will*
# match a subsequent "GET /foo/SUFFIX"; hence the manual addition of
# catchall rules AFTER the "require" statements.

# IMPORTANT: do not use parenthesis in the regex if you are using
# parameters, it will clash with the rule compiler, below; better yet
# do not use them at all, don't treat them as regex.

our @raw_action_list = (	# NOTE: THIS IS 'our' SO IT CAN BE POKED EXTERNALLY
    # empty / root request
    [ '',            'GET',  \&do_redirect, '/ui/' ],

    # feed and object retrieval, comment submission
    [ '/get',        'GET',  \&do_remote_get ],
    [ '/get',        'POST', \&do_remote_post ],

    # public, unprotected documents
    [ '/pub',        'GET',  \&do_document, 'database/pub', '.' ],
    [ '/pub/SUFFIX', 'GET',  \&do_document, 'database/pub', 'SUFFIX' ],

    # mine documentation
    [ '/doc',        'GET',  \&do_document, 'database/doc', '.' ],
    [ '/doc/SUFFIX', 'GET',  \&do_document, 'database/doc', 'SUFFIX' ],

    # more added by ui and api modules
    );

my @compiled_action_list = ();	# where the results go

# extra stuff to go into the Protomine package

require 'pm-api.pl';
require 'pm-atom.pl';
require 'pm-mime.pl';
require 'pm-ui.pl';

# push the final catch-all rules into the raw_action_list

push (@raw_action_list,
      [  '/ui',         'GET',  \&do_document,  'database/ui',  '.'       ],
      [  '/ui/SUFFIX',  'GET',  \&do_document,  'database/ui',  'SUFFIX'  ],
    );

# objects we will need

require 'Context.pl';
require 'Crypto.pl';
require 'Log.pl';
require 'Object.pl';
require 'Page.pl';
require 'Relation.pl';
require 'Tag.pl';
require 'Thing.pl';

##################################################################

# mappings from CRUD to HTTP for readability

my %crud = (
    CREATE => 'POST',           # REST
    READ => 'GET',              # REST
    UPDATE => 'PUT',            # REST
    DELETE => 'DELETE',         # REST/HTTP
    POST => 'POST',             # HTTP
    GET => 'GET',               # HTTP
    PUT => 'PUT',               # HTTP
    );

##################################################################
##################################################################
##################################################################

# compile the action list

&compile_action_list;

# run the query - eventually make this into fast_cgi?

if (1) {
    # log it using the environment variables for safety
    Log->msg(sprintf "env %s %s %s",
	 $ENV{REMOTE_ADDR},
	 $ENV{REQUEST_METHOD},
	 $ENV{REQUEST_URI});

    # rip the CGI query
    my $q = CGI->new;

    # create a context from it
    my $ctx = Context->new($q, $MINE_HTTP_PATH);

    # define the page we will print
    my $page;

    # if there was an error during decoding, fail noisily
    if (my $barf = $q->cgi_error) {
	$page = Page->newError(500, "protomine.cgi: cgi decoding error: $barf");
    }
    else {
	# execute the CGI input against the action list
	# nb: the "eval" block needs a trailing ';'
	eval { $page = &match_and_execute($ctx); } ;

	# did we barf?
	if ($@) {     
	    $page = Page->newError(500, "protomine.cgi: software exception: $@");
	}
    }

    # one final mugtrap
    unless (defined($page)) {
	$page = Page->newError(500, "protomine.cgi: match_and_execute returned undefined page");
    }

    # print the resulting page here - $ctx supplies context and CGI
    # object references, other meta information...
    $page->printUsing($ctx);
}

# done

exit 0;

###################################################################
###################################################################
###################################################################

# this is the routine which encodes parameters and calls handlers
# as described in the notes for &compile_action_list

sub match_and_execute {
    my $ctx = shift;

    # sanity-check the supplied URL with any query info;
    $ctx->assertCanonicalURL;

    # memorise the important stuff
    my $cgi_method = $ctx->method;

    # sanity check the method, and provide the PUT/DELETE workaround
    if ($cgi_method eq 'GET' or $cgi_method eq 'POST') {
	my $p;
	my $q = $ctx->cgi;

	if (defined($p = $q->param('_method'))) {
	    if ($p eq 'POST' or # POST->POST is redundant but not a risk
		$p eq 'PUT' or
		$p eq 'DELETE') {
		$cgi_method = $p;
	    }
	    else {
		die "match_and_execute: illegal value for _method: $p\n"
	    }
	}
    }
    elsif ($cgi_method eq 'PUT') {      # TODO: rewrite this
	# $cgi_data = $q->param('POSTDATA');
	# $cgi_datafh = *STDIN;
    }

    my $cgi_url = $ctx->path;

    # skim through the action list and find work

    foreach my $action (@compiled_action_list) {
	my ($method, $pattern, $plistref, $handler, @args) = @{$action};

	# skip if wrong method

	next unless ($cgi_method eq $method); 

	# skip if not matching pattern

	next unless ($cgi_url =~ /$pattern/);

	# this is where we store key/value pairs from the 
	# regular expression substring matcher

	my %phash = ();

	# do we need to do argument processing?

	if (defined($plistref)) {

	    # build the %phash

	    my @plist = @{$plistref};

	    $phash{$plist[0]} = $1 if ($#plist >= 0);
	    $phash{$plist[1]} = $2 if ($#plist >= 1);
	    $phash{$plist[2]} = $3 if ($#plist >= 2);
	    $phash{$plist[3]} = $4 if ($#plist >= 3);
	    $phash{$plist[4]} = $5 if ($#plist >= 4);
	    $phash{$plist[5]} = $6 if ($#plist >= 5);
	    $phash{$plist[6]} = $7 if ($#plist >= 6);
	    $phash{$plist[7]} = $8 if ($#plist >= 7);
	    $phash{$plist[8]} = $9 if ($#plist >= 8);

	    # check the handler arguments for phash variables and
	    # substitute them if you find them

	    for (my $i = 0 ; $i <= $#args; $i++) {
		my $replace = $args[$i];

		if (defined($phash{$replace})) {
		    $args[$i] = $phash{$replace};
		}
	    }
	}

	# handler takes pattern and url as well as arguments for
	# verbose info; the structured programmer in me would love to
	# take a return value here and print it using a method
	# selected in the table of actions, but in truth there are too
	# many side-effects and "drop back 10 yards and punt"
	# scenarios that frankly i can't be arsed;

	Log->msg("run method $cgi_method url $cgi_url ", %phash);
	return &{$handler}($ctx, [$cgi_method, $cgi_url, $pattern], \%phash, @args);
    }

    # if we get here, we fell off the list of regular expressions

    return Page->newError(404, "no handler for method $cgi_method url $cgi_url");
}

##################################################################

# this routine relates to @raw_action_list and generates @compiled_action_list

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
# 2) create a phashref: $phr = { TEXT1 => 'bar' }
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
	my @plist = ();
	my $regexp = $url;

	# escape dots
	$regexp =~ s!\.!\\.!go;

	# extract all uppercase words (with optional numeric suffixes)
	# from the url pattern, push them on plist replacing them with
	# a regexp token

	while ($regexp =~ s/([A-Z]+\d*)/'(' . &smart_token($1) . ')'/e) {
	    push(@plist, $1);
	}

	# compile the new pattern and replace the url pattern with that
	my $pattern = qr!^${regexp}/?$!i;

	# have we any params?
	my $plistref = ($#plist < 0) ? undef : \@plist;

	# translate the crud
	my $method = $crud{$crud_method};

	# stash the compiled action
	push( @compiled_action_list, [ $method, $pattern, $plistref, $handler, @args ] );
    }
}

###################################################################

# this routine relates to the pseudo-urls in @raw_action_list; the
# uppercase tokens in the pseudo-URL get ripped out and replaced by the
# regular expressions below.

sub smart_token {
    my $token = shift;
    return '(xml|json|txt)' if ($token eq 'FMT');
    return '\d+' if ($token eq 'OID');
    return '\d+' if ($token eq 'RID');
    return '\d+' if ($token eq 'TID');
    return '\d+' if ($token eq 'CID');
    return '\d+' if ($token eq 'RVSN');
    return '\w+' if ($token eq 'COOKIE');
    return '.*'  if ($token eq 'SUFFIX'); # magic names - greedy wildcard
    return '.*?' if ($token eq 'TEXT\d*'); # magic names - conservative wildcard
    return '\d+' if ($token =~ m!NUM\d+!o);    # magic names - NUM001
    return '\w+' if ($token =~ m!WORD\d+!o);   # magic names - WORD001
    return '[\-\.\w]+';
}

##################################################################

# this is the dummy no-op handler, use it as a template for other
# handlers; it just dumps information to the browser

sub do_noop {
    my ($ctx, $info, $phr, @args) = @_;
    return Page->newText("do_noop @args");
}

##################################################################

# redirect whatever url to $target

sub do_redirect {
    my ($ctx, $info, $phr, $target) = @_;
    return $ctx->forceRedirect($target);
}

##################################################################

# handle an actual proper document request

sub do_document {
    my ($ctx, $info, $phr, $root, $cited) = @_;

    my $document = "$root/$cited";

    if (-d $document) {
	$ctx->assertTrailingSlash;
	Log->msg("dir $document");
	return Page->newDirectory($document);
    }
    elsif (-f $document) {
	Log->msg("file $document");
	return Page->newFile($document);
    }
    else {
	return Page->newError(404, "do_document: file not found: $document");
    }
}

##################################################################

sub do_remote_get {
    my ($ctx, $info, $phr, $fn, @rest) = @_;

    # extract the key

    my $q = $ctx->cgi;
    my $key = $q->param('key');

    # decrypt the key
    # TBD: better security audit trail here

    my ($meth, $rid, $rvsn, $oid) = Crypto->decodeMineKey($key);

    # load the relation
    # TBD: trap this better so you log a security exception

    my $r = Relation->new($rid); # will abort if not exist

    # check the relationship validity 
    # (rvsn, date, time-of-day, ipaddress, ...)
    # TBD: replace this with a Relation method call

    my $rvsn2 = $r->relationVersion;

    unless ($rvsn eq $rvsn2) {		    
	die "do_remote_get: bad rvsn $key; supplied=$rvsn real=$rvsn2";
    }

    # get his interests blob
    
    my $ib = $r->getInterestsBlob;

    # analyse the request

    if ($oid > 0) {		    # it's an object-get 
	# pull in the object metadata
	my $o = Object->new($oid) ; # will abort if not exist

	# check if the object wants to be seen by him
	unless ($o->matchInterestsBlob($ib)) {
	    die "do_remote_get: bad object-get oid=$oid rid=$rid failed matchInterestsBlob";
	}

	# punt to api_read_aux_oid
	return &api_read_aux_oid($ctx, $info, $phr, $oid);
    }
    elsif ($oid == 0) {		# it's a feed-get
	my $page = Page->newAtom;

	my $feed_owner = "alec";

	my $feed_title = 
	    sprintf "%s for %s (%s)", 
	    $feed_owner, 
	    $r->name, 
	    $r->get('relationInterests');

	my $feed_link = &get_permalink("read", $r);
	my $feed_updated = &atom_format(time);
	my $feed_author_name = $feed_owner;
	my $feed_id = $feed_link;

	$page->add("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
	$page->add("<feed xmlns=\"http://www.w3.org/2005/Atom\">\n");
	$page->add("<title>$feed_title</title>\n");
	$page->add("<link href=\"$feed_link\" rel=\"self\"/>\n");
	$page->add("<updated>$feed_updated</updated>\n");
	$page->add("<author><name>$feed_author_name</name></author>\n");
	$page->add("<id>$feed_id</id>\n");

	# consider each object in the mine; TBD: this should be the
	# latest 50 in most-recently-modified order

	foreach $oid (Object->list) {
	    my $o = Object->new($oid);

	    next unless ($o->matchInterestsBlob($ib));

	    my $obj_link = &get_permalink($r, $o);

	    $page->add($o->toAtom($obj_link));
	}

	$page->add("</feed>\n");

	return $page;
    }

    # fall off the end?
    die "do_remote_get: this can't happen";
}

##################################################################

sub do_remote_post {
    die "not yet implemented";
}

##################################################################

1;
