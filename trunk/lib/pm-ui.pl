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
##################################################################
##################################################################

sub XXui_create_object {
    my ($ctx, $info, $phr) = @_;

    my $result = &api_create_object(@_);
    my $oid = $result->{objectId};

    my $p = Page->newHTML("ui/");
    $p->add("created object $oid");
    return $p;
}

sub XXui_create_relation {
    my ($ctx, $info, $phr) = @_;

    my $result = &api_create_relation(@_);
    my $rid = $result->{relationId};

    my $p = Page->newHTML("ui/");
    $p->add("created relation $rid");
    return $p;
}

sub XXui_create_tag {
    my ($ctx, $info, $phr) = @_;

    my $result = &api_create_tag(@_);
    my $tid = $result->{tagId};

    my $p = Page->newHTML("ui/");
    $p->add("created tag $tid");
    return $p;
}

sub XXui_show_objects {
    my ($ctx, $info, $phr) = @_;

    my @oids = Object->list;

    my $p = Page->newHTML("ui/");
    $p->add("<dl>");
    foreach my $oid (@oids) {
	my $object = Object->new($oid);
	my $name = $object->name;

	$p->add("<dt>object $oid: $name</dt>\n");
	$p->add("<dd>");
	$p->addCloud({
	    "delete-object/$oid.html", "[delete]",
	    "../api/object/$oid", "[view]",
	    "read-object/$oid.html", "[info]",
	    "update-data/$oid.html", "[update]",
	    "update-object/$oid.html", "[update info]",
		     });
	$p->add("<br/>\n");
	$p->add($object);
	$p->add("</dd>\n");
	$p->add("<p/>\n");
    }
    $p->add("</dl>\n");
    return $p;
}

sub XXui_show_relations {
    my ($ctx, $info, $phr) = @_;

    my @rids = Relation->list;

    my $p = Page->newHTML("ui/");
    $p->add("<dl>");
    foreach my $rid (@rids) {
	my $relation = Relation->new($rid);
	my $name = $relation->name;

	$p->add("<dt>relation $rid: $name</dt>\n");
	$p->add("<dd>");
	$p->addCloud({
		 &get_permalink("read", $relation), "[feed]",
		 "delete-relation/$rid.html", "[delete]",
		 "read-relation/$rid.html", "[info]",
		 "update-relation/$rid.html", "[update info]",
		     });
	$p->add("<br/>\n");
	$p->add($relation);
	$p->add("</dd>\n");
	$p->add("<p/>\n");
    }
    $p->add("</dl>\n");
    return $p;
}

sub XXui_show_tags {
    my ($ctx, $info, $phr) = @_;

    my @tids = Tag->list;

    my $p = Page->newHTML("ui/");
    $p->add("<dl>");
    foreach my $tid (@tids) {
	my $tag = Tag->new($tid);
	my $name = $tag->name;

	$p->add("<dt>tag $tid: $name</dt>\n");
	$p->add("<dd>");
	$p->addCloud({
	    "delete-tag/$tid.html", "[delete]",
	    "read-tag/$tid.html", "[info]",
	    "update-tag/$tid.html", "[update info]",
		     });
	$p->add("<br/>\n");
	$p->add($tag);
	$p->add("</dd>\n");
	$p->add("<p/>\n");
    }
    $p->add("</dl>\n");
    return $p;
}

##################################################################
##################################################################
##################################################################
##################################################################

# ui_clone_object_oid --
push (@raw_action_list, [ '/ui/clone-object/OID.html', 'GET', \&ui_clone_object_oid, 'OID' ]);

sub ui_clone_object_oid {
}

# ui_create_object --
push (@raw_action_list, [ '/ui/create-object.html', 'POST', \&ui_create_object ]);

sub ui_create_object {
}

# ui_create_relation --
push (@raw_action_list, [ '/ui/create-relation.html', 'POST', \&ui_create_relation ]);

sub ui_create_relation {
}

# ui_create_tag --
push (@raw_action_list, [ '/ui/create-tag.html', 'POST', \&ui_create_tag ]);

sub ui_create_tag {
}

# ui_delete_object_oid --
push (@raw_action_list, [ '/ui/delete-object/OID.html', 'GET', \&ui_delete_object_oid, 'OID' ]);

sub ui_delete_object_oid {
}

# ui_delete_relation_rid --
push (@raw_action_list, [ '/ui/delete-relation/RID.html', 'GET', \&ui_delete_relation_rid, 'RID' ]);

sub ui_delete_relation_rid {
}

# ui_delete_tag_tid --
push (@raw_action_list, [ '/ui/delete-tag/TID.html', 'GET', \&ui_delete_tag_tid, 'TID' ]);

sub ui_delete_tag_tid {
}

# ui_read_object_oid --
push (@raw_action_list, [ '/ui/read-object/OID.html', 'GET', \&ui_read_object_oid, 'OID' ]);

sub ui_read_object_oid {
}

# ui_read_relation_rid --
push (@raw_action_list, [ '/ui/read-relation/RID.html', 'GET', \&ui_read_relation_rid, 'RID' ]);

sub ui_read_relation_rid {
}

# ui_read_tag_tid --
push (@raw_action_list, [ '/ui/read-tag/TID.html', 'GET', \&ui_read_tag_tid, 'TID' ]);

sub ui_read_tag_tid {
}

# ui_select_object --
push (@raw_action_list, [ '/ui/select/object.html', 'GET', \&ui_select_object ]);

sub ui_select_object {
}

# ui_select_relation --
push (@raw_action_list, [ '/ui/select/relation.html', 'GET', \&ui_select_relation ]);

sub ui_select_relation {
}

# ui_select_tag --
push (@raw_action_list, [ '/ui/select/tag.html', 'GET', \&ui_select_tag ]);

sub ui_select_tag {
}

# ui_share_raw_rid_rvsn_oid --
push (@raw_action_list, [ '/ui/share/raw/RID/RVSN/OID', 'GET', \&ui_share_raw_rid_rvsn_oid, 'RID', 'RVSN', 'OID' ]);

sub ui_share_raw_rid_rvsn_oid {
}

# ui_share_redirect_rid --
push (@raw_action_list, [ '/ui/share/redirect/RID', 'GET', \&ui_share_redirect_rid, 'RID' ]);

sub ui_share_redirect_rid {
}

# ui_share_redirect_rid_oid --
push (@raw_action_list, [ '/ui/share/redirect/RID/OID', 'GET', \&ui_share_redirect_rid_oid, 'RID', 'OID' ]);

sub ui_share_redirect_rid_oid {
}

# ui_share_url_rid --
push (@raw_action_list, [ '/ui/share/url/RID.html', 'GET', \&ui_share_url_rid, 'RID' ]);

sub ui_share_url_rid {
}

# ui_share_url_rid_oid --
push (@raw_action_list, [ '/ui/share/url/RID/OID.html', 'GET', \&ui_share_url_rid_oid, 'RID', 'OID' ]);

sub ui_share_url_rid_oid {
}

# ui_show_clones_oid --
push (@raw_action_list, [ '/ui/show-clones/OID.html', 'GET', \&ui_show_clones_oid, 'OID' ]);

sub ui_show_clones_oid {
}

# ui_show_config --
push (@raw_action_list, [ '/ui/show-config.html', 'GET', \&ui_show_config ]);

sub ui_show_config {
}

# ui_show_objects --
push (@raw_action_list, [ '/ui/show-objects.html', 'GET', \&ui_show_objects ]);

sub ui_show_objects {
}

# ui_show_relations --
push (@raw_action_list, [ '/ui/show-relations.html', 'GET', \&ui_show_relations ]);

sub ui_show_relations {
}

# ui_show_tags --
push (@raw_action_list, [ '/ui/show-tags.html', 'GET', \&ui_show_tags ]);

sub ui_show_tags {
}

##################################################################

# ui_update_config --
push (@raw_action_list, [ '/ui/update-config.html', 'GET', \&ui_update_config ]);

sub ui_update_config {
}

##################################################################

# ui_update_data_oid --
push (@raw_action_list, [ '/ui/update-data/OID.html', 'GET', \&ui_update_data_oid, 'database/ui', 'update-data-xxx.html' ]);

sub ui_update_data_oid {
}

##################################################################

# ui_update_object_oid --
push (@raw_action_list, [ '/ui/update-object/OID.html', 'GET', \&ui_update_object_oid, 'database/ui', 'update-object-xxx.html' ]);

sub ui_update_object_oid {
}

##################################################################

# ui_update_relation_rid --
push (@raw_action_list, [ '/ui/update-relation/RID.html', 'GET', \&ui_update_relation_rid, 'database/ui', 'update-relation-xxx.html' ]);

sub ui_update_relation_rid {
}

##################################################################

# ui_update_tag_tid --
push (@raw_action_list, [ '/ui/update-tag/TID.html', 'GET', \&ui_update_tag_tid, 'database/ui', 'update-tag-xxx.html' ]);

sub ui_update_tag_tid {
}

##################################################################

# ui_version --
push (@raw_action_list, [ '/ui/version.html', 'GET', \&ui_version ]);

sub ui_version {
}


##################################################################

1;
