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

our @raw_action_list;

##################################################################

# stub to print whatever a API returns

sub do_fmt {
    my ($ctx, $info, $phr, $fmt, $fn, @rest) = @_;

    if ($fmt eq 'xml') {
	return Page->newXML(&{$fn}($ctx, $info, $phr, @rest));
    }
    elsif ($fmt eq 'json') {
	return Page->newJSON(&{$fn}($ctx, $info, $phr, @rest));
    }
    elsif ($fmt eq 'txt') {
	return Page->newText(&{$fn}($ctx, $info, $phr, @rest));
    }
    elsif ($fmt eq 'pl') {	# not for public consumption
	return Page->newPerl(&{$fn}($ctx, $info, $phr, @rest));
    }
    else {
	die "do_fmt: this can't happen: fmt=$fmt";
    }
}

# keycrud: cRUD atop get/set for Things
# create == bulk update with a bunch of key/value pairs
# read(key)
# update(key)
# delete(key)

sub keycrud_create {
    my ($ctx, $thing, $prefix) = @_;

    my $q = $ctx->cgi;
    foreach my $key (grep(/^$prefix/, $q->param)) {
	my $value = $q->param($key);
	if (defined($value)) {
	    $thing->set($key, $value);
	}
    }
    return { status => $thing->update };
}

sub keycrud_read {
    my ($ctx, $thing, $key) = @_;
    return { value => $thing->get($key) };
}

sub keycrud_update {
    my ($ctx, $thing, $key) = @_;

    die "error keycrud_update is temporarily banned as potentially unsafe\n";

    my $q = $ctx->cgi;
    my $value = $q->param('POSTDATA'); # TBD: in theory this is correct; in practice?
    $thing->set($key, $value);
    return { status => $thing->update };
}

sub keycrud_delete {
    my ($ctx, $thing, $key) = @_;
    $thing->set($key, '');	# delete == set to empty string
    return { status => $thing->update };
}

##################################################################
##################################################################
##################################################################

# api_read_aux_oid <---- THIS IS A SPECIAL ONE, RETURNS AUX DATA PAGE
push (@raw_action_list, [ '/api/object/OID', 'READ', \&api_read_aux_oid, 'OID' ]);
sub api_read_aux_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my $o = Object->new($oid);
    return Page->newFile($o->auxGetFile, $o->get('objectType'));
}

##################################################################

# api_read_config # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/config.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_config ]);
sub api_read_config {
    my ($ctx, $info, $phr) = @_;
    return { config => 'nyi' };
}

# api_update_config # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/config.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_update_config ]);
sub api_update_config {		# actually a create since it updates multi-values
    my ($ctx, $info, $phr) = @_;
    return { status => 'nyi' };
}

# api_create_object
push (@raw_action_list, [ '/api/object.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_object ]);
sub api_create_object {
    my ($ctx, $info, $phr) = @_;

    my $q = $ctx->cgi;
    my $o = Object->new;
    my @import_list = grep(/^object/o, $q->param);

    # try setting keys
    foreach my $key (@import_list) {
	my $value = $q->param($key);

	if (defined($value)) {
	    $o->set($key, $value);
	}
    }

    my $oid = $o->save;         # now it is in the database

    # install that which is uploaded

    my $dataparam = $q->param('data');
    if (defined($dataparam)) {

	# see if it's an upload
	my $fh = $q->upload('data');

	if (defined($fh)) {
	    # there is a FH, so go with that
	    $o->auxPutFH($fh);
	}
	else { 
	    # assume parameter put
	    $o->auxPutBlob($dataparam);
	}
    }

    return { objectId => $oid };
}

# api_list_objects
push (@raw_action_list, [ '/api/object.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_objects ]);
sub api_list_objects {
    my ($ctx, $info, $phr) = @_;
    my @container = map { +{ objectId => $_ } } Object->list;
    return { objectIds => \@container };
}

# api_update_aux_oid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/object/OID', 'UPDATE', \&do_fmt, 'FMT', \&api_update_aux_oid, 'OID' ]);
sub api_update_aux_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    return { status => 'nyi' };
}

# api_delete_oid
push (@raw_action_list, [ '/api/object/OID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_oid, 'OID' ]);
sub api_delete_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    return { status => Object->new($oid)->delete };
}

# api_read_oid
push (@raw_action_list, [ '/api/object/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_oid, 'OID' ]);
sub api_read_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my $o = Object->new($oid);
    return { object => $o->toDataStructure };
}

# api_delete_oid_cid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/object/OID/CID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_oid_cid, 'OID', 'CID' ]);
sub api_delete_oid_cid {
    my ($ctx, $info, $phr, $oid, $cid) = @_;
    return { status => 'nyi' };
}

# api_read_oid_cid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/object/OID/CID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_oid_cid, 'OID', 'CID' ]);
sub api_read_oid_cid {
    my ($ctx, $info, $phr, $oid, $cid) = @_;
    return { comment => 'nyi' };
}

# api_create_keys_oid_cid
push (@raw_action_list, [ '/api/object/OID/CID/key.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_keys_oid_cid, 'OID', 'CID' ]);
sub api_create_keys_oid_cid {
    my ($ctx, $info, $phr, $oid, $cid) = @_;
    return &keycrud_create($ctx, Comment->new($oid, $cid), 'comment');
}

# api_read_key_oid_cid_key
push (@raw_action_list, [ '/api/object/OID/CID/key/KEY.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_key_oid_cid_key, 'OID', 'CID', 'KEY' ]);
sub api_read_key_oid_cid_key {
    my ($ctx, $info, $phr, $oid, $cid, $key) = @_;
    return &keycrud_read($ctx, Comment->new($oid, $cid), $key);
}

# api_update_key_oid_cid_key
push (@raw_action_list, [ '/api/object/OID/CID/key/KEY.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_key_oid_cid_key, 'OID', 'CID', 'KEY' ]);
sub api_update_key_oid_cid_key {
    my ($ctx, $info, $phr, $oid, $cid, $key) = @_;
    return &keycrud_update($ctx, Comment->new($oid, $cid), $key);
}

# api_delete_key_oid_cid_key
push (@raw_action_list, [ '/api/object/OID/CID/key/KEY.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_key_oid_cid_key, 'OID', 'CID', 'KEY' ]);
sub api_delete_key_oid_cid_key {
    my ($ctx, $info, $phr, $oid, $cid, $key) = @_;
    return &keycrud_delete($ctx, Comment->new($oid, $cid), $key);
}

# api_create_clone_oid
push (@raw_action_list, [ '/api/object/OID/clone.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_clone_oid, 'OID' ]);
sub api_create_clone_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    return { objectId => Object->new($oid)->clone };
}

# api_list_clones_oid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/object/OID/clone.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_clones_oid, 'OID' ]);
sub api_list_clones_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    return { objectIds => 'nyi' };
}

# api_create_comment_oid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/object/OID/comment.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_comment_oid, 'OID' ]);
sub api_create_comment_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    return { commentId => 'nyi' };
}

# api_list_comments_oid
push (@raw_action_list, [ '/api/object/OID/comment.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_comments_oid , 'OID' ]);
sub api_list_comments_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my @container = map { +{ commentId => $_ } } Comment->new($oid)->list;
    return { commentIds => \@container };
}

# api_create_keys_oid
push (@raw_action_list, [ '/api/object/OID/key.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_keys_oid, 'OID' ]);
sub api_create_keys_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    return &keycrud_create($ctx, Object->new($oid), 'object');
}

# api_read_key_oid_key
push (@raw_action_list, [ '/api/object/OID/key/KEY.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_key_oid_key, 'OID', 'KEY' ]);
sub api_read_key_oid_key {
    my ($ctx, $info, $phr, $oid, $key) = @_;
    return &keycrud_read($ctx, Object->new($oid), $key);
}

# api_update_key_oid_key
push (@raw_action_list, [ '/api/object/OID/key/KEY.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_key_oid_key, 'OID', 'KEY' ]);
sub api_update_key_oid_key {
    my ($ctx, $info, $phr, $oid, $key) = @_;
    return &keycrud_update($ctx, Object->new($oid), $key);
}

# api_delete_key_oid_key
push (@raw_action_list, [ '/api/object/OID/key/KEY.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_key_oid_key, 'OID', 'KEY' ]);
sub api_delete_key_oid_key {
    my ($ctx, $info, $phr, $oid, $key) = @_;
    return &keycrud_delete($ctx, Object->new($oid), $key);
}

# api_create_relation
push (@raw_action_list, [ '/api/relation.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_relation ]);
sub api_create_relation {
    my ($ctx, $info, $phr) = @_;

    my $q = $ctx->cgi;
    my $r = Relation->new;
    my @import_list = grep(/^relation/o, $q->param);

    foreach my $key (@import_list ) {
	my $value = $q->param($key);

	if (defined($value)) {
	    $r->set($key, $value);
	}
    }

    return { relationId => $r->save };
}

# api_list_relations
push (@raw_action_list, [ '/api/relation.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_relations ]);
sub api_list_relations {
    my ($ctx, $info, $phr) = @_;
    my @container = map { +{ relationId => $_ } } Relation->list;
    return { relationIds => \@container };
}

# api_delete_rid
push (@raw_action_list, [ '/api/relation/RID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_rid, 'RID' ]);
sub api_delete_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    return { status => Relation->new($rid)->delete };
}

# api_read_rid
push (@raw_action_list, [ '/api/relation/RID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_rid, 'RID' ]);
sub api_read_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    my $r = Relation->new($rid);
    return { relation => $r->toDataStructure };
}

# api_create_keys_rid
push (@raw_action_list, [ '/api/relation/RID/key.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_keys_rid, 'RID' ]);
sub api_create_keys_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    return &keycrud_create($ctx, Relation->new($rid), 'relation');
}

# api_read_key_rid_key
push (@raw_action_list, [ '/api/relation/RID/key/KEY.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_key_rid_key, 'RID', 'KEY' ]);
sub api_read_key_rid_key {
    my ($ctx, $info, $phr, $rid, $key) = @_;
    return &keycrud_read($ctx, Relation->new($rid), $key);
}

# api_update_key_rid_key
push (@raw_action_list, [ '/api/relation/RID/key/KEY.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_key_rid_key, 'RID', 'KEY' ]);
sub api_update_key_rid_key {
    my ($ctx, $info, $phr, $rid, $key) = @_;
    return &keycrud_update($ctx, Relation->new($rid), $key);
}

# api_delete_key_rid_key
push (@raw_action_list, [ '/api/relation/RID/key/KEY.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_key_rid_key, 'RID', 'KEY' ]);
sub api_delete_key_rid_key {
    my ($ctx, $info, $phr, $rid, $key) = @_;
    return &keycrud_delete($ctx, Relation->new($rid), $key);
}

# api_select_object # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/select/object.FMT', 'READ', \&do_fmt, 'FMT', \&api_select_object ]);
sub api_select_object {
    my ($ctx, $info, $phr) = @_;
    return { objectIds => 'nyi' };
}

# api_select_relation # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/select/relation.FMT', 'READ', \&do_fmt, 'FMT', \&api_select_relation ]);
sub api_select_relation {
    my ($ctx, $info, $phr) = @_;
    return { relationIds => 'nyi' };
}

# api_select_tag # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/select/tag.FMT', 'READ', \&do_fmt, 'FMT', \&api_select_tag ]);
sub api_select_tag {
    my ($ctx, $info, $phr) = @_;
    return { tagIds => 'nyi' };
}

# api_share_raw # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/share/raw/RID/RVSN/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_share_raw, 'OID', 'RID', 'RVSN' ]);
sub api_share_raw {
    my ($ctx, $info, $phr, $oid, $rid, $rvsn) = @_;
    return { url => 'nyi' };
}

# api_redirect_rid # <-------- THIS IS SPECIAL
push (@raw_action_list, [ '/api/share/redirect/RID.FMT', 'READ', \&do_fmt, 'FMT', \&api_redirect_rid, 'RID' ]);
sub api_redirect_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    die;
}

# api_redirect_rid_oid # <-------- THIS IS SPECIAL
push (@raw_action_list, [ '/api/share/redirect/RID/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_redirect_rid_oid, 'OID', 'RID' ]);
sub api_redirect_rid_oid {
    my ($ctx, $info, $phr, $oid, $rid) = @_;
    die;
}

# api_share_rid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/share/url/RID.FMT', 'READ', \&do_fmt, 'FMT', \&api_share_rid, 'RID' ]);
sub api_share_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    return { url => 'nyi' };
}

# api_share_rid_oid # <--------------------------------------- TO BE DONE
push (@raw_action_list, [ '/api/share/url/RID/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_share_rid_oid, 'OID', 'RID' ]);
sub api_share_rid_oid {
    my ($ctx, $info, $phr, $oid, $rid) = @_;
    return { url => 'nyi' };
}

# api_create_tag
push (@raw_action_list, [ '/api/tag.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_tag ]);
sub api_create_tag {
    my ($ctx, $info, $phr) = @_;

    my $q = $ctx->cgi;
    my $t = Tag->new;
    my @import_list = grep(/^tag/o, $q->param);

    foreach my $key (@import_list) {
	my $value = $q->param($key);

	if (defined($value)) {
	    $t->set($key, $value);
	}
    }

    return { tagId => $t->save };
}

# api_list_tags
push (@raw_action_list, [ '/api/tag.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_tags ]);
sub api_list_tags {
    my ($ctx, $info, $phr) = @_;
    my @container = map { +{ tagId => $_ } } Tag->list;
    return { tagIds => \@container };
}

# api_delete_tid
push (@raw_action_list, [ '/api/tag/TID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_tid, 'TID' ]);
sub api_delete_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    return { status => Tag->new($tid)->delete };
}

# api_read_tid
push (@raw_action_list, [ '/api/tag/TID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_tid, 'TID' ]);
sub api_read_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    my $t = Tag->new($tid);
    return { tag => $t->toDataStructure };
}

# api_create_keys_tid
push (@raw_action_list, [ '/api/tag/TID/key.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_keys_tid, 'TID' ]);
sub api_create_keys_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    return &keycrud_create($ctx, Tag->new($tid), 'tag');
}

# api_read_key_tid_key
push (@raw_action_list, [ '/api/tag/TID/key/KEY.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_key_tid_key, 'TID', 'KEY' ]);
sub api_read_key_tid_key {
    my ($ctx, $info, $phr, $tid, $key) = @_;
    return &keycrud_read($ctx, Tag->new($tid), $key);
}

# api_update_key_tid_key
push (@raw_action_list, [ '/api/tag/TID/key/KEY.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_key_tid_key, 'TID', 'KEY' ]);
sub api_update_key_tid_key {
    my ($ctx, $info, $phr, $tid, $key) = @_;
    return &keycrud_update($ctx, Tag->new($tid), $key);
}

# api_delete_key_tid_key
push (@raw_action_list, [ '/api/tag/TID/key/KEY.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_key_tid_key, 'TID', 'KEY' ]);
sub api_delete_key_tid_key {
    my ($ctx, $info, $phr, $tid, $key) = @_;
    return &keycrud_delete($ctx, Tag->new($tid), $key);
}

# api_version
push (@raw_action_list, [ '/api/version.FMT', 'READ', \&do_fmt, 'FMT', \&api_version ]);
sub api_version {
    my ($ctx, $info, $phr) = @_;
    return {
	version =>
	{
	    software => 'protomine', # this software
	    revision => '201',	 # software revision (use SVN number?)
	    api => '1.200',	 # api revision
	}
    };
}

##################################################################

1;
