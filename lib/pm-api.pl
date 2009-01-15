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

# api_version --
sub api_version {
    my ($ctx, $info, $phr) = @_;

    return { version => { api => '1.001',
			  mine => '1.001' } };
}

# api_create_clone --
sub api_create_clone {          # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $object = Object->new($id);
    return { objectId => $object->clone };
}

# api_create_object --
sub api_create_object {         # -- DONE --
    my ($ctx, $info, $phr) = @_;

    my $q = $ctx->cgi;
    my $object = Object->new;
    my @import_list = grep(/^object/o, $q->param);

    foreach my $key (@import_list) {
	my $value = $q->param($key);

	if (defined($value)) {
	    $object->set($key, $value);
	}
    }

    my $oid = $object->save;    # now it is in the database

    if (defined($q->param('data'))) { # install that which is uploaded
	my $fh = $q->upload('data');
	unless (defined($fh)) {
	    die "api_create_object: bad fh passed back from cgi";
	}
	$object->auxPutFH($fh);
    }

    return { objectId => $oid };
}

# api_create_relation --
sub api_create_relation {       # -- DONE --
    my ($ctx, $info, $phr) = @_;

    my $q = $ctx->cgi;
    my $relation = Relation->new;
    my @import_list = grep(/^relation/o, $q->param);

    foreach my $key (@import_list ) {
	my $value = $q->param($key);

	if (defined($value)) {
	    $relation->set($key, $value);
	}
    }

    return { relationId => $relation->save };
}

# api_create_tag --
sub api_create_tag {            # -- DONE --
    my ($ctx, $info, $phr) = @_;

    my $q = $ctx->cgi;
    my $tag = Tag->new;
    my @import_list = grep(/^tag/o, $q->param);

    foreach my $key (@import_list) {
	my $value = $q->param($key);

	if (defined($value)) {
	    $tag->set($key, $value);
	}
    }

    return { tagId => $tag->save };
}

# api_delete_oid --
sub api_delete_oid {            # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $object = Object->new($id);
    return { status => $object->delete };
}

# api_delete_rid --
sub api_delete_rid {            # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $relation = Relation->new($id);
    return { status => $relation->delete };
}

# api_delete_tid --
sub api_delete_tid {            # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $tag = Tag->new($id);
    return { status => $tag->delete };
}

# api_list_objects --
sub api_list_objects {          # -- DONE --
    my ($ctx, $info, $phr) = @_;
    my @structure;
    foreach my $oid (Object->list) {
	push(@structure, { objectId => $oid });
    }
    return { objectIds => \@structure };
}

# api_list_relations --
sub api_list_relations {        # -- DONE --
    my ($ctx, $info, $phr) = @_;
    my @structure;
    foreach my $rid (Relation->list) {
	push(@structure, { relationId => $rid });
    }
    return { relationIds => \@structure };
}

# api_list_tags --
sub api_list_tags {             # -- DONE --
    my ($ctx, $info, $phr) = @_;
    my @structure;
    foreach my $tid (Tag->list) {
	push(@structure, { tagId => $tid });
    }
    return { tagIds => \@structure };
}

# api_read_oid_aux --
sub api_read_oid_aux {          # -- DONE -- *** AUX DATA, NOT RETURN STRUCTURE ***
    my ($ctx, $info, $phr, $id) = @_;

    my $q = $ctx->cgi;
    my $object = Object->new($id);
    return Page->newFile($object->auxGetFile, $object->get('objectType'));
}

# api_read_oid --
sub api_read_oid {              # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $object = Object->new($id);
    return { object => $object->toDataStructure };
}

# api_read_rid --
sub api_read_rid {              # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $relation = Relation->new($id);
    return { relation => $relation->toDataStructure };
}

# api_read_tid --
sub api_read_tid {              # -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $tag = Tag->new($id);
    return { tag => $tag->toDataStructure };
}

##################################################################
##################################################################
##################################################################
##################################################################

push (@raw_action_list,
      [ '/api/object/OID', 'READ', \&api_read_aux_oid, 'OID' ], # <---- SPECIAL, EMITS AUX DATA
      [ '/api/config.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_config ],
      [ '/api/config.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_config ],
      [ '/api/object.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_object ],
      [ '/api/object.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_objects ],
      [ '/api/object/OID', 'UPDATE', \&do_fmt, 'FMT', \&api_update_aux_oid, 'OID' ],
      [ '/api/object/OID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_oid, 'OID' ],
      [ '/api/object/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_oid, 'OID' ],
      [ '/api/object/OID.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_oid, 'OID' ],
      [ '/api/object/OID/CID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/CID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/CID.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/CID/vars.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_vars_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/CID/vars.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_vars_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/CID/vars.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_vars_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/CID/vars.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_vars_oid_cid, 'OID', 'CID' ],
      [ '/api/object/OID/clone.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_clone_oid, 'OID' ],
      [ '/api/object/OID/clone.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_clones_oid, 'OID' ],
      [ '/api/object/OID/comment.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_comment_oid, 'OID' ],
      [ '/api/object/OID/comment.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_comments_oid , 'OID' ],
      [ '/api/object/OID/vars.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_vars_oid, 'OID' ],
      [ '/api/object/OID/vars.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_vars_oid, 'OID' ],
      [ '/api/object/OID/vars.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_vars_oid, 'OID' ],
      [ '/api/object/OID/vars.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_vars_oid, 'OID' ],
      [ '/api/relation.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_relation ],
      [ '/api/relation.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_relations ],
      [ '/api/relation/RID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_rid, 'RID' ],
      [ '/api/relation/RID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_rid, 'RID' ],
      [ '/api/relation/RID.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_rid, 'RID' ],
      [ '/api/relation/RID/vars.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_vars_rid, 'RID' ],
      [ '/api/relation/RID/vars.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_vars_rid, 'RID' ],
      [ '/api/relation/RID/vars.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_vars_rid, 'RID' ],
      [ '/api/relation/RID/vars.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_vars_rid, 'RID' ],
      [ '/api/select/object.FMT', 'READ', \&do_fmt, 'FMT', \&api_select_object ],
      [ '/api/select/relation.FMT', 'READ', \&do_fmt, 'FMT', \&api_select_relation ],
      [ '/api/select/tag.FMT', 'READ', \&do_fmt, 'FMT', \&api_select_tag ],
      [ '/api/share/raw/RID/RVSN/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_share_raw, 'OID', 'RID', 'RVSN' ],
      [ '/api/share/redirect/RID.FMT', 'READ', \&do_fmt, 'FMT', \&api_redirect_rid, 'RID' ],
      [ '/api/share/redirect/RID/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_redirect_rid_oid, 'OID', 'RID' ],
      [ '/api/share/url/RID.FMT', 'READ', \&do_fmt, 'FMT', \&api_share_rid, 'RID' ],
      [ '/api/share/url/RID/OID.FMT', 'READ', \&do_fmt, 'FMT', \&api_share_rid_oid, 'OID', 'RID' ],
      [ '/api/tag.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_tag ],
      [ '/api/tag.FMT', 'READ', \&do_fmt, 'FMT', \&api_list_tags ],
      [ '/api/tag/TID.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_tid, 'TID' ],
      [ '/api/tag/TID.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_tid, 'TID' ],
      [ '/api/tag/TID.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_tid, 'TID' ],
      [ '/api/tag/TID/vars.FMT', 'CREATE', \&do_fmt, 'FMT', \&api_create_vars_tid, 'TID' ],
      [ '/api/tag/TID/vars.FMT', 'DELETE', \&do_fmt, 'FMT', \&api_delete_vars_tid, 'TID' ],
      [ '/api/tag/TID/vars.FMT', 'READ', \&do_fmt, 'FMT', \&api_read_vars_tid, 'TID' ],
      [ '/api/tag/TID/vars.FMT', 'UPDATE', \&do_fmt, 'FMT', \&api_update_vars_tid, 'TID' ],
      [ '/api/version.FMT', 'READ', \&do_fmt, 'FMT', \&api_version ],
    );

##################################################################

1;
