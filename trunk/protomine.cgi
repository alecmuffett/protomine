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

use CGI qw/:standard/;
use CGI::Carp;
use CGI::Pretty;

# standard config for this system
my $execdir = $0;
$execdir =~ s![^/]+$!!g;
require "$execdir/protomine-config.pl";

##################################################################

# stop perl debugger filling the apache logfile about single use variables

if (0) {
    print $main::MINE_DIRECTORY;
    print $main::MINE_HTTP_PATH;
}

# go to the mine home directory

chdir($main::MINE_DIRECTORY) or die "chdir: $main::MINE_DIRECTORY: $!";

# get the extra stuff we need

require 'Context.pl';
require 'Log.pl';
require 'Object.pl';
require 'Page.pl';
require 'Relation.pl';
require 'Tag.pl';
require 'Thing.pl';
require 'pm-api.pl';
require 'pm-atom.pl';
require 'pm-mime.pl';
require 'pm-ui.pl';

# impose a 10Mb ceiling on POST data

$CGI::POST_MAX = 10 * (1024**2);

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

    ###
    # empty / root request
    ###

    [ '', 'GET', \&do_redirect, '/ui/' ],

    ###
    # the /get URL is a special case HTTP
    ###

    [ '/get', 'GET', \&do_remote_get ], # <---- FEED AND OBJECT RETRIEVAL
    [ '/get', 'POST', \&do_remote_post ], # <---- COMMENT SUBMISSION

    ###
    # API calls are safe to fasttrack / out of sequence, since they exact-match
    ###

    [ '/api/object/OID', 'READ', \&api_read_aux_oid, 'OID' ], # <---- SPECIAL, EMITS AUX DATA
    # the following method deleted for security/simplicity reasons;
    # use the API version.  there is simply no point in having TWO
    # urls to rewrite, outbound, when this is all user-facing stuff.
    # [ '/ui/read-data/OID', 'GET', \&api_read_aux_oid, 'OID' ],

    ###
    # public files and documentation
    ###

    [  '/pub',         'GET',  \&do_document,  'database/pub',  '.'       ],
    [  '/pub/SUFFIX',  'GET',  \&do_document,  'database/pub',  'SUFFIX'  ],
    [  '/doc',         'GET',  \&do_document,  'database/doc',  '.'       ],
    [  '/doc/SUFFIX',  'GET',  \&do_document,  'database/doc',  'SUFFIX'  ],

    ###
    # the /ui/ hierarchy lives in HTTP space
    ###

    [  '/ui/version.html',              'GET',   \&ui_version           ],
    [  '/ui/update-tag/TID.html',       'POST',  \&ui_update_tag,       'TID'           ],
    [  '/ui/update-tag/TID.html',       'GET',   \&do_document,         'database/ui',  'update-tag-xxx.html'       ],
    [  '/ui/update-relation/RID.html',  'POST',  \&ui_update_relation,  'RID'           ],
    [  '/ui/update-relation/RID.html',  'GET',   \&do_document,         'database/ui',  'update-relation-xxx.html'  ],
    [  '/ui/update-object/OID.html',    'GET',   \&do_document,         'database/ui',  'update-object-xxx.html'    ],
    [  '/ui/update-object/OID.html',    'POST',  \&ui_update_object,    'OID'           ],
    [  '/ui/update-data/OID.html',      'POST',  \&ui_update_data,      'OID'           ],
    [  '/ui/update-data/OID.html',      'GET',   \&do_document,         'database/ui',  'update-data-xxx.html'      ],
    [  '/ui/update-config.html',        'POST',  \&ui_update_config     ],
    [  '/ui/show-tags.html',            'GET',   \&ui_show_tags         ],
    [  '/ui/show-relations.html',       'GET',   \&ui_show_relations    ],
    [  '/ui/show-objects.html',         'GET',   \&ui_show_objects      ],
    [  '/ui/show-config.html',          'GET',   \&ui_show_config       ],
    [  '/ui/show-clones/OID.html',      'GET',   \&ui_show_clones,      'OID'           ],
    [  '/ui/share/url/RID/OID.html',    'GET',   \&do_noop,             'RID',          'RVSN',                     'OID'  ],
    [  '/ui/share/url/RID.html',        'GET',   \&do_noop,             'RID',          'RVSN',                     'OID'  ],
    [  '/ui/share/redirect/RID/OID',    'GET',   \&do_noop,             'RID',          'RVSN',                     'OID'  ],
    [  '/ui/share/redirect/RID',        'GET',   \&do_noop,             'RID',          'RVSN',                     'OID'  ],
    [  '/ui/share/raw/RID/RVSN/OID',    'GET',   \&do_noop,             'RID',          'RVSN',                     'OID'  ],
    [  '/ui/select/tag.html',           'GET',   \&do_noop              ],
    [  '/ui/select/relation.html',      'GET',   \&do_noop              ],
    [  '/ui/select/object.html',        'GET',   \&do_noop              ],
    [  '/ui/read-tag/TID.html',         'GET',   \&ui_read_tag,         'TID'           ],
    [  '/ui/read-relation/RID.html',    'GET',   \&ui_read_relation,    'RID'           ],
    [  '/ui/read-object/OID.html',      'GET',   \&ui_read_object,      'OID'           ],
    [  '/ui/delete-tag/TID.html',       'GET',   \&ui_delete_tag,       'TID'           ],
    [  '/ui/delete-relation/RID.html',  'GET',   \&ui_delete_relation,  'RID'           ],
    [  '/ui/delete-object/OID.html',    'GET',   \&ui_delete_object,    'OID'           ],
    [  '/ui/create-tag.html',           'POST',  \&ui_create_tag        ],
    [  '/ui/create-relation.html',      'POST',  \&ui_create_relation   ],
    [  '/ui/create-object.html',        'POST',  \&ui_create_object     ],
    [  '/ui/clone-object/OID.html',     'GET',   \&ui_clone_object,     'OID'           ],

    ###
    # catchall/fallthru for the methods above; we may pick up a *file*
    # for "GET" which corresponds with something that is "POST" above.
    ###

    [ '/ui', 'GET', \&do_document, 'database/ui', '.' ],
    [ '/ui/SUFFIX', 'GET', \&do_document, 'database/ui', 'SUFFIX' ],

    ###
    # the /api/ hierarchy lives in REST space
    ##
    [  '/api/config.xml',                  'READ',    \&do_xml,  \&api_read_config           ],
    [  '/api/config.xml',                  'UPDATE',  \&do_xml,  \&api_update_config         ],
    [  '/api/object.xml',                  'CREATE',  \&do_xml,  \&api_create_object         ],
    [  '/api/object.xml',                  'READ',    \&do_xml,  \&api_list_objects          ],
    [  '/api/object/OID',                  'UPDATE',  \&do_xml,  \&api_update_aux_oid,       'OID'   ],
    [  '/api/object/OID.xml',              'DELETE',  \&do_xml,  \&api_delete_oid,           'OID'   ],
    [  '/api/object/OID.xml',              'READ',    \&do_xml,  \&api_read_oid,             'OID'   ],
    [  '/api/object/OID.xml',              'UPDATE',  \&do_xml,  \&api_update_oid,           'OID'   ],
    [  '/api/object/OID/CID.xml',          'DELETE',  \&do_xml,  \&api_delete_oid_cid,       'OID',  'CID'   ],
    [  '/api/object/OID/CID.xml',          'READ',    \&do_xml,  \&api_read_oid_cid,         'OID',  'CID'   ],
    [  '/api/object/OID/CID.xml',          'UPDATE',  \&do_xml,  \&api_update_oid_cid,       'OID',  'CID'   ],
    [  '/api/object/OID/CID/vars.xml',     'CREATE',  \&do_xml,  \&api_create_vars_oid_cid,  'OID',  'CID'   ],
    [  '/api/object/OID/CID/vars.xml',     'DELETE',  \&do_xml,  \&api_delete_vars_oid_cid,  'OID',  'CID'   ],
    [  '/api/object/OID/CID/vars.xml',     'READ',    \&do_xml,  \&api_read_vars_oid_cid,    'OID',  'CID'   ],
    [  '/api/object/OID/CID/vars.xml',     'UPDATE',  \&do_xml,  \&api_update_vars_oid_cid,  'OID',  'CID'   ],
    [  '/api/object/OID/clone.xml',        'CREATE',  \&do_xml,  \&api_create_clone_oid,     'OID'   ],
    [  '/api/object/OID/clone.xml',        'READ',    \&do_xml,  \&api_list_clones_oid,      'OID'   ],
    [  '/api/object/OID/comment.xml',      'CREATE',  \&do_xml,  \&api_create_comment_oid,   'OID'   ],
    [  '/api/object/OID/comment.xml',      'READ',    \&do_xml,  \&api_list_comments_oid ,   'OID'   ],
    [  '/api/object/OID/vars.xml',         'CREATE',  \&do_xml,  \&api_create_vars_oid,      'OID'   ],
    [  '/api/object/OID/vars.xml',         'DELETE',  \&do_xml,  \&api_delete_vars_oid,      'OID'   ],
    [  '/api/object/OID/vars.xml',         'READ',    \&do_xml,  \&api_read_vars_oid,        'OID'   ],
    [  '/api/object/OID/vars.xml',         'UPDATE',  \&do_xml,  \&api_update_vars_oid,      'OID'   ],
    [  '/api/relation.xml',                'CREATE',  \&do_xml,  \&api_create_relation       ],
    [  '/api/relation.xml',                'READ',    \&do_xml,  \&api_list_relations        ],
    [  '/api/relation/RID.xml',            'DELETE',  \&do_xml,  \&api_delete_rid,           'RID'   ],
    [  '/api/relation/RID.xml',            'READ',    \&do_xml,  \&api_read_rid,             'RID'   ],
    [  '/api/relation/RID.xml',            'UPDATE',  \&do_xml,  \&api_update_rid,           'RID'   ],
    [  '/api/relation/RID/vars.xml',       'CREATE',  \&do_xml,  \&api_create_vars_rid,      'RID'   ],
    [  '/api/relation/RID/vars.xml',       'DELETE',  \&do_xml,  \&api_delete_vars_rid,      'RID'   ],
    [  '/api/relation/RID/vars.xml',       'READ',    \&do_xml,  \&api_read_vars_rid,        'RID'   ],
    [  '/api/relation/RID/vars.xml',       'UPDATE',  \&do_xml,  \&api_update_vars_rid,      'RID'   ],
    [  '/api/select/object.xml',           'READ',    \&do_xml,  \&api_select_object         ],
    [  '/api/select/relation.xml',         'READ',    \&do_xml,  \&api_select_relation       ],
    [  '/api/select/tag.xml',              'READ',    \&do_xml,  \&api_select_tag            ],
    [  '/api/share/raw/RID/RVSN/OID.xml',  'READ',    \&do_xml,  \&api_share_raw,            'OID',  'RID',  'RVSN'  ],
    [  '/api/share/redirect/RID.xml',      'READ',    \&do_xml,  \&api_redirect_rid,         'RID'   ],
    [  '/api/share/redirect/RID/OID.xml',  'READ',    \&do_xml,  \&api_redirect_rid_oid,     'OID',  'RID'   ],
    [  '/api/share/url/RID.xml',           'READ',    \&do_xml,  \&api_share_rid,            'RID'   ],
    [  '/api/share/url/RID/OID.xml',       'READ',    \&do_xml,  \&api_share_rid_oid,        'OID',  'RID'   ],
    [  '/api/tag.xml',                     'CREATE',  \&do_xml,  \&api_create_tag            ],
    [  '/api/tag.xml',                     'READ',    \&do_xml,  \&api_list_tags             ],
    [  '/api/tag/TID.xml',                 'DELETE',  \&do_xml,  \&api_delete_tid,           'TID'   ],
    [  '/api/tag/TID.xml',                 'READ',    \&do_xml,  \&api_read_tid,             'TID'   ],
    [  '/api/tag/TID.xml',                 'UPDATE',  \&do_xml,  \&api_update_tid,           'TID'   ],
    [  '/api/tag/TID/vars.xml',            'CREATE',  \&do_xml,  \&api_create_vars_tid,      'TID'   ],
    [  '/api/tag/TID/vars.xml',            'DELETE',  \&do_xml,  \&api_delete_vars_tid,      'TID'   ],
    [  '/api/tag/TID/vars.xml',            'READ',    \&do_xml,  \&api_read_vars_tid,        'TID'   ],
    [  '/api/tag/TID/vars.xml',            'UPDATE',  \&do_xml,  \&api_update_vars_tid,      'TID'   ],
    [  '/api/version.xml',                 'READ',    \&do_xml,  \&api_version               ],

    );

# where the compiled actions will reside

my @action_list = ();

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
    my $ctx = Context->new($q, $main::MINE_HTTP_PATH);

    # define the page we will print
    my $page;

    # if there was an error during decoding, fail noisily
    if (my $barf = $q->cgi_error) {
	$page = Page->newError(500, "cgi decoding error: $barf");
    }
    else {
	# execute the CGI input against the action list
	# nb: the "eval" block needs a trailing ';'
	eval { $page = &match_and_execute($ctx); } ;

	# did we barf?
	if ($@) {     
	    $page = Page->newError(500, "software exception: $@\n");
	}
    }

    # one final mugtrap
    unless (defined($page)) {
	$page = Page->newError(500, "match_and_execute returned undefined page");
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

# this is the main routine which encodes parameters and calls handlers
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
		die "illegal value for _method: $p";
	    }
	}
    }
    elsif ($cgi_method eq 'PUT') {      # TODO: rewrite this
	# $cgi_data = $q->param('POSTDATA');
	# $cgi_datafh = *STDIN;
    }

    my $cgi_url = $ctx->path;

    # skim through the action list and find work

    foreach my $action (@action_list) {
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

	# extract all uppercase words from the url pattern, push them
	# on plist replacing them with a regexp token

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
	push( @action_list, [ $method, $pattern, $plistref, $handler, @args ] );
    }
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

# stub to print whatever a API returns

sub do_apidump {
    my ($ctx, $info, $phr, $fn, @rest) = @_;
    return Page->newText(&{$fn}($ctx, $info, $phr, @rest));
}

##################################################################

# stub to print whatever a API returns

sub do_xml {
    my ($ctx, $info, $phr, $fn, @rest) = @_;
    return Page->newXML(&{$fn}($ctx, $info, $phr, @rest));
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
	return Page->newError(404, "cannot do_document $document");
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

    my ($rid, $rvsn, $oid) = &decode_key($key);

    # load the relation
    # TBD: trap this better so you log a security exception

    my $r = Relation->new($rid); # will abort if not exist

    # check the relationship validity 
    # (rvsn, date, time-of-day, ipaddress, ...)
    # TBD: replace this with a Relation method call

    my $rvsn2 = $r->relationVersion;

    unless ($rvsn eq $rvsn2) {		    
	my $diag = "bad rvsn $key; supplied=$rvsn real=$rvsn2";
	Log->msg("security $diag");
	die "do_remote_get: $diag\n";
    }

    # get his interests blob
    
    my $ib = $r->getInterestsBlob;

    # analyse the request

    if ($oid > 0) {		    # it's an object-get 
	# pull in the object metadata
	my $o = Object->new($oid) ; # will abort if not exist

	# check if the object wants to be seen by him
	unless ($o->matchInterestsBlob($ib)) {
	    my $diag = "bad object-get oid=$oid rid=$rid failed matchInterestsBlob";
	    Log->msg("security $diag");
	    die "do_remote_get: $diag\n";
	}

	# punt to api_read_aux_oid
	return &api_read_aux_oid($ctx, $info, $phr, $oid);
    }
    elsif ($oid == 0) {		# it's a feed-get
	my @ofeed;		# the atom feed document

	# consider each object in the mine
	# TBD: this should be the latest 50 in most-recently-modified order

	my $feed_owner = "alec";

	my $feed_title = sprintf "%s for %s (%s)", $feed_owner, $r->name, $r->get('relationInterests');
	my $feed_link = &get_permalink($r);
	my $feed_updated = &atom_format(time);
	my $feed_author_name = $feed_owner;
	my $feed_id = $feed_link;

	push(@ofeed, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
	push(@ofeed, "<feed xmlns=\"http://www.w3.org/2005/Atom\">\n");
	push(@ofeed, "<title>$feed_title</title>\n");
	push(@ofeed, "<link href=\"$feed_link\" rel=\"self\"/>\n");
	push(@ofeed, "<updated>$feed_updated</updated>\n");
	push(@ofeed, "<author><name>$feed_author_name</name></author>\n");
	push(@ofeed, "<id>$feed_id</id>\n");

	foreach $oid (Object->list) {
	    my $o = Object->new($oid);

	    next unless ($o->matchInterestsBlob($ib));

	    my $obj_link = &get_permalink($r, $o);

	    push(@ofeed, $o->toAtom($obj_link));
	}

	push(@ofeed, "</feed>\n");

	return return Page->newAtom(  \@ofeed );
    }

    # fall off the end?
    die "do_remote_get: this can't happen";
}

##################################################################

1;
