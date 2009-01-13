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
#use diagnostics;

##################################################################

## api_version --
sub api_version {
    my ($ctx, $info, $phr) = @_;

    return { version => { api => '1.001', 
			  mine => '1.001' } };
}
##################################################################}

## api_create_clone --
sub api_create_clone {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $object = Object->new($id);
    return { objectId => $object->clone };
}

##################################################################

## api_create_object --
sub api_create_object {		# -- DONE --
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

    my $oid = $object->save;	# now it is in the database

    if (defined($q->param('data'))) { # install that which is uploaded
	my $fh = $q->upload('data');
	unless (defined($fh)) {
	    die "api_create_object: bad fh passed back from cgi";
	}
	$object->auxPutFH($fh);
    }

    return { objectId => $oid };
}

##################################################################

## api_create_relation --
sub api_create_relation {	# -- DONE --
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

##################################################################

## api_create_tag --
sub api_create_tag {		# -- DONE --
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

##################################################################

## api_delete_oid --
sub api_delete_oid {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $object = Object->new($id);
    return { status => $object->delete };
}

##################################################################

## api_delete_rid --
sub api_delete_rid {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $relation = Relation->new($id);
    return { status => $relation->delete };
}

##################################################################

## api_delete_tid --
sub api_delete_tid {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $tag = Tag->new($id);
    return { status => $tag->delete };
}

##################################################################

## api_list_clones --
sub api_list_clones {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_list_objects --
sub api_list_objects {		# -- DONE --
    my ($ctx, $info, $phr) = @_;
    my @structure;
    foreach my $oid (Object->list) {
	push(@structure, { objectId => $oid });
    }    
    return { objectIds => \@structure };
}

##################################################################

## api_list_relations --
sub api_list_relations {	# -- DONE --
    my ($ctx, $info, $phr) = @_;
    my @structure;
    foreach my $rid (Relation->list) {
	push(@structure, { relationId => $rid });
    }    
    return { relationIds => \@structure };
}

##################################################################

## api_list_tags --
sub api_list_tags {		# -- DONE --
    my ($ctx, $info, $phr) = @_;
    my @structure;
    foreach my $tid (Tag->list) {
	push(@structure, { tagId => $tid });
    }    
    return { tagIds => \@structure };
}

##################################################################

## api_read_config --
sub api_read_config {
    my ($ctx, $info, $phr) = @_;
    die "method not yet implemented";
}

##################################################################

## api_read_oid_aux --
sub api_read_oid_aux {		# -- DONE -- *** AUX DATA, NOT RETURN STRUCTURE ***
    my ($ctx, $info, $phr, $id) = @_;

    my $q = $ctx->cgi;
    my $object = Object->new($id);
    $ctx->printFile($object->auxGetFile, $object->get('objectType'));
}

##################################################################

## api_read_oid --
sub api_read_oid {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $object = Object->new($id);
    return { object => $object->toDataStructure };
}

##################################################################

## api_read_rid --
sub api_read_rid {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $relation = Relation->new($id);
    return { relation => $relation->toDataStructure };
}

##################################################################

## api_read_tid --
sub api_read_tid {		# -- DONE --
    my ($ctx, $info, $phr, $id) = @_;
    my $tag = Tag->new($id);
    return { tag => $tag->toDataStructure };
}

##################################################################

## api_update_config --
sub api_update_config {
    my ($ctx, $info, $phr) = @_;
    die "method not yet implemented";
}

##################################################################

## api_update_oid --
sub api_update_oid {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_update_oid_aux --
sub api_update_oid_aux {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_update_rid --
sub api_update_rid {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_update_tid --
sub api_update_tid {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_object_create_param --
sub api_object_create_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_object_delete_param --
sub api_object_delete_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_object_read_param --
sub api_object_read_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_object_update_param --
sub api_object_update_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_relation_create_param --
sub api_relation_create_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_relation_delete_param --
sub api_relation_delete_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_relation_read_param --
sub api_relation_read_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_relation_update_param --
sub api_relation_update_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_tag_create_param --
sub api_tag_create_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_tag_delete_param --
sub api_tag_delete_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_tag_read_param --
sub api_tag_read_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

## api_tag_update_param --
sub api_tag_update_param {
    my ($ctx, $info, $phr, $id) = @_;
    die "method not yet implemented";
}

##################################################################

1;
