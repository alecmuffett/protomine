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

sub do_remote_get {
    my ($ctx, $info, $phr, $fn, @rest) = @_;

    # extract the key

    my $q = $ctx->cgi;
    my $key = $q->param('key');

    # decrypt the key
    my $req_mk = MineKey->newFromEncoded($key);

    # debug
    Log->msg($req_mk->readable);

    # check for posting
    if ($req_mk->{method} == 1) {
	die "cannot submit POST mine key via a GET method\n";
    }

    # check the request depth
    unless ($req_mk->{depth} > 0) {
	die "do_remote_get: you've strayed too far from your feed\n";
    }

    # load the relation
    my $r = Relation->new($req_mk->{rid}); # will abort if not exist; better log security exception

    # check the relationship validity: relation version
    unless ($r->relationVersion eq $req_mk->{rvsn}) {		    
	my $reqrv = $req_mk->{rvsn};
	my $currv = $r->relationVersion;
	die "do_remote_get: security bad rvsn $key; cur=$currv req=$reqrv\n";
    }

    # check the relationship validity: embargos
    # XXX TBD

    # check the relationship validity: ip address
    # XXX TBD

    # check the relationship validity: time of day
    # XXX TBD

    # get his interests blob
    my $ib = $r->getInterestsBlob;

    # analyse the request
    if ($req_mk->{oid} > 0) {		    # it's an object-get 
	# pull in the object metadata
	my $o = Object->new($req_mk->{oid}) ; # will abort if not exist

	# check if the object wants to be seen by him
	# FALLTHRU PASS ON THIS, AS IS OBJECT-GET
	unless ($o->matchInterestsBlob($ib, 1)) {
	    die "do_remote_get: bad object-get oid=$req_mk->{oid} rid=$req_mk->{rid} failed matchInterestsBlob\n";
	}

	my $otype = $o->get('objectType');

	if ($otype eq 'text/html') {
	    return Page->newFileRewrite($req_mk, $o->auxGetFile, $o->get('objectType'));
	}
	else {
	    return Page->newFile($o->auxGetFile, $o->get('objectType'));
	}
    }
    elsif ($req_mk->{oid} == 0) {		# it's a feed-get
	my $page = Page->newAtom;


	my $feed_title = sprintf "feed for %s (debug: %s)", $r->name, $r->get('relationInterests');
	my $feed_mk = MineKey->newFromRelation($r);
	my $feed_link = $feed_mk->permalink;
	my $feed_updated = &atom_format(time);
	my $feed_author_name = "some.body";
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

	foreach my $oid (Object->list) {
	    my $o = Object->new($oid);

	    # FALLTHRU-FAIL ON THIS, AS IS FILTER
	    next unless ($o->matchInterestsBlob($ib, 0));

	    my $obj_mk = $feed_mk->spawnObject($o);

	    $page->add($o->toAtom($obj_mk));
	}

	$page->add("</feed>\n");

	return $page;
    }

    # fall off the end?
    die "do_remote_get: this can't happen";
}

##################################################################

1;
