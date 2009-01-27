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

my %form_size_table = 
    (
     commentBody => 'BOX1',
     commentId => 'SKIP',
     commentSubject => 'LINE1',
     objectDescription => 'BOX1',
     objectId => 'SKIP',
     objectStatus => 'OBJECTSTATUS',
     objectType => 'LINE3',
     relationDescription => 'BOX1',
     relationId => 'SKIP',
     relationInterests => 'LINE1',
     relationURL => 'LINE1',
     relationVersion => 'LINE3',
     tagId => 'SKIP',
     tagImplies => 'LINE1',
    );

sub form_size {
    my $key = shift;
    return $form_size_table{$key} || 'LINE2';
}

sub loopify {			# TODO: put CSS class into arg, embed in template
    my $hashref = shift;
    my %opts = @_;

    my $retval = {};
    my @vector;

    foreach my $key (sort { (&form_size($a) cmp &form_size($b)) || ( $a cmp $b ) } keys %{$hashref}) {
	# would love to cache key/value too, but die_on_bad_params forbids
	# $retval->{$key} = $value;

       	my $element = {};
	$element->{KEY} = $key;
	$element->{VALUE} = $hashref->{$key};

	if ($opts{'dosize'}) {
	    my $size = &form_size($key);
	    next if ($size eq 'SKIP');
	    $element->{$size} = 1;
	}

	push(@vector, $element);
    }

    $retval->{LOOP} = \@vector;

    return $retval;
}

sub formify {
}

##################################################################
##################################################################
##################################################################

# ui_clone_object_oid --
push (@raw_action_list, [ '/ui/clone-object/OID.html', 'GET', \&ui_clone_object_oid, 'OID' ]);

sub ui_clone_object_oid {
}

# ui_create_object --
push (@raw_action_list, [ '/ui/create-object.html', 'GET', \&ui_create_object ]);

sub ui_create_object {
    my ($ctx, $info, $phr) = @_;

    my $p = Page->newHTML("ui/");
    my $thing = {
        objectName => 'required',
        objectStatus => 'required',
        objectType => 'required',
    };
    
    foreach my $key (Object->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, dosize => 1);

    $template->{LINKPAGE} = "create-object.html";
    $template->{TITLE} = "creating a new object";

    $template->{ACTION} = "../api/object.txt";

    $p->addFileTemplate('tmpl-update-thing.html', $template);
    return $p;
}


# ui_create_relation --
push (@raw_action_list, [ '/ui/create-relation.html', 'GET', \&ui_create_relation ]);

sub ui_create_relation {
    my ($ctx, $info, $phr) = @_;

    my $p = Page->newHTML("ui/");
    my $thing = {
	relationName => 'required',
        relationVersion => '1',
    };
    
    foreach my $key (Relation->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, dosize => 1);

    $template->{LINKPAGE} = "create-relation.html";
    $template->{TITLE} = "creating a new relation";

    $template->{ACTION} = "../api/relation.txt";

    $p->addFileTemplate('tmpl-update-thing.html', $template);
    return $p;
}

# ui_create_tag --
push (@raw_action_list, [ '/ui/create-tag.html', 'GET', \&ui_create_tag ]);

sub ui_create_tag {
    my ($ctx, $info, $phr) = @_;

    my $p = Page->newHTML("ui/");
    my $thing = {
	tagName => 'required',
    };
    
    foreach my $key (Tag->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, dosize => 1);

    $template->{LINKPAGE} = "create-tag.html";
    $template->{TITLE} = "creating a new tag";

    $template->{ACTION} = "../api/tag.txt";

    $p->addFileTemplate('tmpl-update-thing.html', $template);
    return $p;
}

# ui_delete_object_oid --
push (@raw_action_list, [ '/ui/delete-object/OID.html', 'GET', \&ui_delete_object_oid, 'OID' ]);

sub ui_delete_object_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my $p = Page->newHTML("ui/");
    my $status = &api_delete_oid(@_);
    $p->addFileTemplate('tmpl-status.html', $status);
    return $p;
}

# ui_delete_relation_rid --
push (@raw_action_list, [ '/ui/delete-relation/RID.html', 'GET', \&ui_delete_relation_rid, 'RID' ]);

sub ui_delete_relation_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    my $p = Page->newHTML("ui/");
    my $status = &api_delete_rid(@_);
    $p->addFileTemplate('tmpl-status.html', $status);
    return $p;
}

# ui_delete_tag_tid --
push (@raw_action_list, [ '/ui/delete-tag/TID.html', 'GET', \&ui_delete_tag_tid, 'TID' ]);

sub ui_delete_tag_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    my $p = Page->newHTML("ui/");
    my $status = &api_delete_tid(@_);
    $p->addFileTemplate('tmpl-status.html', $status);
    return $p;
}

# ui_read_object_oid --
push (@raw_action_list, [ '/ui/get-object/OID.html', 'GET', \&ui_read_object_oid, 'OID' ]);

sub ui_read_object_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my $p = Page->newHTML("ui/");
    my $wrapper = &api_read_oid($ctx, $info, $phr, $oid);
    $p->addFileTemplate('tmpl-get-thing.html', &loopify($wrapper->{object}));
    return $p;
}

# ui_read_relation_rid --
push (@raw_action_list, [ '/ui/get-relation/RID.html', 'GET', \&ui_read_relation_rid, 'RID' ]);

sub ui_read_relation_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    my $p = Page->newHTML("ui/");
    my $wrapper = &api_read_rid($ctx, $info, $phr, $rid);
    $p->addFileTemplate('tmpl-get-thing.html', &loopify($wrapper->{relation}));
    return $p;
}

# ui_read_tag_tid --
push (@raw_action_list, [ '/ui/get-tag/TID.html', 'GET', \&ui_read_tag_tid, 'TID' ]);

sub ui_read_tag_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    my $p = Page->newHTML("ui/");
    my $wrapper = &api_read_tid($ctx, $info, $phr, $tid);
    $p->addFileTemplate('tmpl-get-thing.html', &loopify($wrapper->{tag}));
    return $p;
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

##################################################################

# ui_list_clones_oid --
push (@raw_action_list, [ '/ui/list-clones/OID.html', 'GET', \&ui_list_clones_oid, 'OID' ]);

sub ui_list_clones_oid {
}

# ui_list_objects --
push (@raw_action_list, [ '/ui/list-objects.html', 'GET', \&ui_list_objects ]);

sub ui_list_objects {
    my ($ctx, $info, $phr) = @_;

    my @thingvec;

    foreach my $oid (Object->list) {
	my $o = Object->new($oid);
	push(@thingvec,
	     {
		 ID => $oid,
		 NAME => $o->get('objectName'),
		 TYPE => $o->get('objectType'),
		 TAGS => $o->get('objectTags'),
		 DESCRIPTION => $o->get('objectDescription'),
		 LINKREAD => "get-object/$oid.html",
		 LINKUPDATE => "update-object/$oid.html",
		 LINKDELETE => "delete-object/$oid.html",
		 LINKGET => "../api/object/$oid",
	     });
    }

    my $template = {
	LOOP => \@thingvec,
	LINKPAGE => 'list-object.html',
	TITLE => 'list objects',
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('tmpl-list-objects.html', $template);
    return $p;
}


# ui_list_relations --
push (@raw_action_list, [ '/ui/list-relations.html', 'GET', \&ui_list_relations ]);

sub ui_list_relations {
    my ($ctx, $info, $phr) = @_;

    my @thingvec;

    foreach my $oid (Relation->list) {
	my $o = Relation->new($oid);
	push(@thingvec,
	     {
		 ID => $oid,
		 NAME => $o->get('relationName'),
		 TAGS => $o->get('relationInterests'),
		 LINKFEED => "feed url goes here",
		 DESCRIPTION => $o->get('relationDescription'),
		 LINKREAD => "get-relation/$oid.html",
		 LINKUPDATE => "update-relation/$oid.html",
		 LINKDELETE => "delete-relation/$oid.html",
	     });
    }

    my $template = {
	LOOP => \@thingvec,
	LINKPAGE => 'list-relations.html',
	TITLE => 'list relations',
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('tmpl-list-relations.html', $template);
    return $p;
}

# ui_list_tags --
push (@raw_action_list, [ '/ui/list-tags.html', 'GET', \&ui_list_tags ]);

sub ui_list_tags {
    my ($ctx, $info, $phr) = @_;

    my @thingvec;

    foreach my $oid (Tag->list) {
	my $o = Tag->new($oid);
	push(@thingvec,
	     {
		 ID => $oid,
		 NAME => $o->get('tagName'),
		 TAGS => $o->get('tagImplies'),
		 LINKREAD => "get-tag/$oid.html",
		 LINKUPDATE => "update-tag/$oid.html",
		 LINKDELETE => "delete-tag/$oid.html",
	     });
    }

    my $template = {
	LOOP => \@thingvec,
	LINKPAGE => 'list-tags.html',
	TITLE => 'list tags',
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('tmpl-list-tags.html', $template);
    return $p;
}

##################################################################

# ui_show_config --
push (@raw_action_list, [ '/ui/show-config.html', 'GET', \&ui_show_config ]);

sub ui_show_config {
}

# ui_update_config --
push (@raw_action_list, [ '/ui/update-config.html', 'GET', \&ui_update_config ]);

sub ui_update_config {
}

##################################################################

# ui_update_data_oid --
push (@raw_action_list, [ '/ui/update-data/OID.html', 'GET', \&ui_update_data_oid, 'OID' ]);

sub ui_update_data_oid {
}

# ui_update_object_oid --
push (@raw_action_list, [ '/ui/update-object/OID.html', 'GET', \&ui_update_object_oid, 'OID' ]);

sub ui_update_object_oid {
    my ($ctx, $info, $phr, $oid) = @_;

    my $p = Page->newHTML("ui/");
    my $thing = (&api_read_oid($ctx, $info, $phr, $oid))->{object};

    foreach my $key (Object->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, dosize => 1);

    $template->{LINKPAGE} = "../api/object/$oid.txt";
    $template->{TITLE} = "editing object $oid";

    $template->{LINKAUX} = "../api/object/$oid";
    $template->{AUXTITLE} = "(data)";

    $template->{ACTION} = "../api/object/$oid/key.txt";

    $p->addFileTemplate('tmpl-update-thing.html', $template);
    return $p;
}

# ui_update_relation_rid --
push (@raw_action_list, [ '/ui/update-relation/RID.html', 'GET', \&ui_update_relation_rid, 'RID' ]);

sub ui_update_relation_rid {
    my ($ctx, $info, $phr, $rid) = @_;

    my $p = Page->newHTML("ui/");
    my $thing = (&api_read_rid($ctx, $info, $phr, $rid))->{relation};

    foreach my $key (Relation->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, dosize => 1);

    $template->{LINKPAGE} = "../api/relation/$rid.txt";
    $template->{TITLE} = "editing relation $rid";

    $template->{ACTION} = "../api/relation/$rid/key.txt";

    $p->addFileTemplate('tmpl-update-thing.html', $template);
    return $p;
}

# ui_update_tag_tid --
push (@raw_action_list, [ '/ui/update-tag/TID.html', 'GET', \&ui_update_tag_tid, 'TID' ]);

sub ui_update_tag_tid {
    my ($ctx, $info, $phr, $tid) = @_;

    my $p = Page->newHTML("ui/");
    my $thing = (&api_read_tid($ctx, $info, $phr, $tid))->{tag};

    foreach my $key (Tag->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, dosize => 1);

    $template->{LINKPAGE} = "../api/tag/$tid.txt";
    $template->{TITLE} = "editing tag $tid";

    $template->{ACTION} = "../api/tag/$tid/key.txt";

    $p->addFileTemplate('tmpl-update-thing.html', $template);
    return $p;
}

##################################################################

# ui_version --
push (@raw_action_list, [ '/ui/version.html', 'GET', \&ui_version ]);

sub ui_version {
    my $p = Page->newHTML("ui/");
    my $wrapper = &api_version(@_); # fast way to send args
    $p->addFileTemplate('tmpl-version.html', $wrapper->{version});
    return $p;
}


##################################################################

1;
