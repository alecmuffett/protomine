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

sub ui_clone_object {		# OID
    die "method not yet implemented\n";
}

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

sub ui_delete_object {		# OID
    die "method not yet implemented\n";
}

sub ui_delete_relation {	# RID
    die "method not yet implemented\n";
}

sub ui_delete_tag {		# TID
    die "method not yet implemented\n";
}

sub ui_read_object {		# OID
    die "method not yet implemented\n";
}

sub ui_read_relation {		# RID
    die "method not yet implemented\n";
}

sub ui_read_tag {		# TID
    die "method not yet implemented\n";
}

sub ui_show_clones {		# OID
    die "method not yet implemented\n";
}

sub ui_show_config {
    die "method not yet implemented\n";
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

sub ui_update_config {
    die "method not yet implemented\n";
}

sub ui_update_data {		# OID
    die "method not yet implemented\n";
}

sub ui_update_object {		# OID
    die "method not yet implemented\n";
}

sub ui_update_relation {	# RID
    die "method not yet implemented\n";
}

sub ui_update_tag {		# TID
    die "method not yet implemented\n";
}

sub ui_version {
    die "method not yet implemented\n";
}

##################################################################

1;
