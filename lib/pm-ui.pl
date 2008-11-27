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

##################################################################
##################################################################
##################################################################

sub ui_clone_object {		# OID
    die "method not yet implemented\n";
}

sub ui_create_object {
    my ($ui, $info, $phr) = @_;
    $ui->setBase("ui/");
    my $result = &api_create_object(@_);
    my $oid = $result->{objectId};
    my @output;
    push(@output, "created object $oid");
    $ui->printPage(\@output);
}

sub ui_create_relation {
    my ($ui, $info, $phr) = @_;
    $ui->setBase("ui/");
    my $result = &api_create_relation(@_);
    my $rid = $result->{relationId};
    my @output;
    push(@output, "created relation $rid");
    $ui->printPage(\@output);
}

sub ui_create_tag {
    my ($ui, $info, $phr) = @_;
    $ui->setBase("ui/");
    my $result = &api_create_tag(@_);
    my $tid = $result->{tagId};
    my @output;
    push(@output, "created tag $tid");
    $ui->printPage(\@output);
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

sub ui_select {			# takes 3 semi-optional arguments
    die "method not yet implemented\n";
}

sub ui_share_raw {
    die "method not yet implemented\n";
}

sub ui_share_redirect {
    die "method not yet implemented\n";
}

sub ui_share_url {
    die "method not yet implemented\n";
}

sub ui_show_clones {		# OID
    die "method not yet implemented\n";
}

sub ui_show_config {
    die "method not yet implemented\n";
}

sub ui_show_objects {
    my ($ui, $info, $phr) = @_;
    $ui->setBase("ui/");	# everything will be relative to this
    my $oids = Object->list;
    my @output;
    push(@output, "<dl>" );
    foreach my $oid (@{$oids}) {
	my $thing = Object->new($oid);
	my $name = $thing->name;

	push(@output, "<dt>object $oid: $name</dt>\n");
	push(@output, "<dd>");
	push(@output, 
	     $ui->formatCloud({
		 "delete-object/$oid.html", "[delete]",
		 "read-data/$oid", "[view]",
		 "read-object/$oid.html", "[info]",
		 "update-data/$oid.html", "[update]",
		 "update-object/$oid.html", "[update info]",
				       }));
	push(@output, "<br/>\n" );
	push(@output, $thing->toString);
	push(@output, "</dd>\n" );
	push(@output, "<p/>\n" );
    }
    push(@output, "</dl>\n" );
    $ui->printPage(\@output);
}

sub ui_show_relations {
    my ($ui, $info, $phr) = @_;
    $ui->setBase("ui/");	# everything will be relative to this
    my $rids = Relation->list;
    my @output;
    push(@output, "<dl>" );
    foreach my $rid (@{$rids}) {
	my $thing = Relation->new($rid);
	my $name = $thing->name;

	push(@output, "<dt>relation $rid: $name</dt>\n");
	push(@output, "<dd>");
	push(@output, 
	     $ui->formatCloud({
		 "delete-relation/$rid.html", "[delete]",
		 "read-relation/$rid.html", "[info]",
		 "update-relation/$rid.html", "[update info]",
				       }));
	push(@output, "<br/>\n" );
	push(@output, $thing->toString);
	push(@output, "</dd>\n" );
	push(@output, "<p/>\n" );
    }
    push(@output, "</dl>\n" );
    $ui->printPage(\@output);
}

sub ui_show_tags {
    my ($ui, $info, $phr) = @_;
    $ui->setBase("ui/");	# everything will be relative to this
    my $rids = Tag->list;
    my @output;
    push(@output, "<dl>" );
    foreach my $rid (@{$rids}) {
	my $thing = Tag->new($rid);
	my $name = $thing->name;

	push(@output, "<dt>tag $rid: $name</dt>\n");
	push(@output, "<dd>");
	push(@output, 
	     $ui->formatCloud({
		 "delete-tag/$rid.html", "[delete]",
		 "read-tag/$rid.html", "[info]",
		 "update-tag/$rid.html", "[update info]",
				       }));
	push(@output, "<br/>\n" );
	push(@output, $thing->toString);
	push(@output, "</dd>\n" );
	push(@output, "<p/>\n" );
    }
    push(@output, "</dl>\n" );
    $ui->printPage(\@output);
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
##################################################################
##################################################################

1;
