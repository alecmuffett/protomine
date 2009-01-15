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

##################################################################
##################################################################
##################################################################

sub ui_create_object {
    my ($ctx, $info, $phr) = @_;

    my $result = &api_create_object(@_);
    my $oid = $result->{objectId};

    my $p = Page->newHTML("ui/");
    $p->add("created object $oid");
    return $p;
}

sub ui_create_relation {
    my ($ctx, $info, $phr) = @_;

    my $result = &api_create_relation(@_);
    my $rid = $result->{relationId};

    my $p = Page->newHTML("ui/");
    $p->add("created relation $rid");
    return $p;
}

sub ui_create_tag {
    my ($ctx, $info, $phr) = @_;

    my $result = &api_create_tag(@_);
    my $tid = $result->{tagId};

    my $p = Page->newHTML("ui/");
    $p->add("created tag $tid");
    return $p;
}

sub ui_show_objects {
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

sub ui_show_relations {
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
		 &get_permalink($relation), "[feed]",
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

sub ui_show_tags {
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

push (@main::raw_action_list,
      [ '/ui/version.html', 'GET', \&ui_version ],
      [ '/ui/update-tag/TID.html', 'POST', \&ui_update_tag, 'TID' ],
      [ '/ui/update-tag/TID.html', 'GET', \&do_document, 'database/ui', 'update-tag-xxx.html' ],
      [ '/ui/update-relation/RID.html', 'POST', \&ui_update_relation, 'RID' ],
      [ '/ui/update-relation/RID.html', 'GET', \&do_document, 'database/ui', 'update-relation-xxx.html' ],
      [ '/ui/update-object/OID.html', 'GET', \&do_document, 'database/ui', 'update-object-xxx.html' ],
      [ '/ui/update-object/OID.html', 'POST', \&ui_update_object, 'OID' ],
      [ '/ui/update-data/OID.html', 'POST', \&ui_update_data, 'OID' ],
      [ '/ui/update-data/OID.html', 'GET', \&do_document, 'database/ui', 'update-data-xxx.html' ],
      [ '/ui/update-config.html', 'POST', \&ui_update_config ],
      [ '/ui/show-tags.html', 'GET', \&ui_show_tags ],
      [ '/ui/show-relations.html', 'GET', \&ui_show_relations ],
      [ '/ui/show-objects.html', 'GET', \&ui_show_objects ],
      [ '/ui/show-config.html', 'GET', \&ui_show_config ],
      [ '/ui/show-clones/OID.html', 'GET', \&ui_show_clones, 'OID' ],
      [ '/ui/share/url/RID/OID.html', 'GET', \&do_noop, 'RID', 'RVSN', 'OID' ],
      [ '/ui/share/url/RID.html', 'GET', \&do_noop, 'RID', 'RVSN', 'OID' ],
      [ '/ui/share/redirect/RID/OID', 'GET', \&do_noop, 'RID', 'RVSN', 'OID' ],
      [ '/ui/share/redirect/RID', 'GET', \&do_noop, 'RID', 'RVSN', 'OID' ],
      [ '/ui/share/raw/RID/RVSN/OID', 'GET', \&do_noop, 'RID', 'RVSN', 'OID' ],
      [ '/ui/select/tag.html', 'GET', \&do_noop ],
      [ '/ui/select/relation.html', 'GET', \&do_noop ],
      [ '/ui/select/object.html', 'GET', \&do_noop ],
      [ '/ui/read-tag/TID.html', 'GET', \&ui_read_tag, 'TID' ],
      [ '/ui/read-relation/RID.html', 'GET', \&ui_read_relation, 'RID' ],
      [ '/ui/read-object/OID.html', 'GET', \&ui_read_object, 'OID' ],
      [ '/ui/delete-tag/TID.html', 'GET', \&ui_delete_tag, 'TID' ],
      [ '/ui/delete-relation/RID.html', 'GET', \&ui_delete_relation, 'RID' ],
      [ '/ui/delete-object/OID.html', 'GET', \&ui_delete_object, 'OID' ],
      [ '/ui/create-tag.html', 'POST', \&ui_create_tag ],
      [ '/ui/create-relation.html', 'POST', \&ui_create_relation ],
      [ '/ui/create-object.html', 'POST', \&ui_create_object ],
      [ '/ui/clone-object/OID.html', 'GET', \&ui_clone_object, 'OID' ],
    );

##################################################################

1;
