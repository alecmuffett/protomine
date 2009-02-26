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

sub postwrapper {
    my ($ctx, $info, $phr, $apifunc, $root, $retlink, @rest) = @_;

    my $hashref = &{$apifunc}($ctx, $info, $phr, @rest);

    die "postwrapper: undef hashref\n" unless (defined($hashref));

    my $template = {
	DUMP => &dumpify($hashref, ROOT => $root),
	RETURN => $retlink,
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/status.html', $template);
    return $p;
}

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
     relationDescription => 'BOX3',
     relationId => 'SKIP',
     relationInterests => 'LINE1',
     relationURL => 'LINE1',
     relationVersion => 'LINE3',
     tagId => 'SKIP',
     tagImplies => 'LINE1',
     data => 'UPLOAD',
    );

sub form_size {
    my $key = shift;
    return $form_size_table{$key} || 'LINE2';
}

sub dumpify {
    my $hashref = shift;
    my %opts = @_;

    # if the actual data structure is rooted in a element of the hash
    if (defined($opts{'ROOT'})) {
	$hashref = $hashref->{$opts{'ROOT'}};
    }

    # mugtrap
    die "dumpify: undef hashref\n" unless (defined($hashref));

    my @vector;

    foreach my $key (sort keys %{$hashref}) {
	push(@vector, { A => $key, B => $hashref->{$key} });
    }

    return \@vector;
}

sub statusify {
    my $hashref = shift;
    my %opts = @_;

    if (defined($opts{'ROOT'})) {
	$hashref = $hashref->{$opts{'ROOT'}};
    }

    die "statusify: undef hashref\n" unless (defined($hashref));

    my $retval = {};

    $retval->{RETURN} = $opts{RETURN};
    $retval->{NAME} = $opts{'NAME'};
    $retval->{STATUS} = $hashref->{$retval->{NAME}};

    return $retval;
}

sub loopify {
    my $hashref = shift;
    my %opts = @_;

    # if the actual data structure is rooted in a element of the hash
    if (defined($opts{'ROOT'})) {
	$hashref = $hashref->{$opts{'ROOT'}};
    }

    # mugtrap
    die "loopify: undef hashref\n" unless (defined($hashref));

    my @vector;

    # sort the form objects
    foreach my $key (sort { (&form_size($a) cmp &form_size($b)) || ( $a cmp $b ) } keys %{$hashref}) {
	my $element = {};
	$element->{KEY} = $key;
	$element->{VALUE} = $hashref->{$key};

	if ($opts{'FORM'}) {
	    my $size = &form_size($key);
	    next if ($size eq 'SKIP'); # skip stuff that is unwritable
	    $element->{$size} = 1;
	}

	# push into the form data structure
	push(@vector, $element);
    }

    my @tmpl_list = ( LOOP => \@vector );
    push(@tmpl_list, @{$opts{'EXTRA'}}) if (defined($opts{'EXTRA'}));
    my %tmpl_hash = @tmpl_list;
    return \%tmpl_hash;
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
push (@raw_action_list, [ '/ui/create-object.html', 
			  'POST', \&postwrapper, 
			  \&api_create_object, undef, 'list-objects.html' ]);

sub ui_create_object {
    my ($ctx, $info, $phr) = @_;

    my $thing = {
	objectName => 'required',
	objectStatus => 'required',
	objectType => 'required',
    };

    foreach my $key (Object->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    $thing->{data} = '';

    my $template = &loopify($thing, FORM => 1);

    $template->{LINKPAGE} = "create-object.html";
    $template->{TITLE} = "creating a new object";
    $template->{ACTION} = "create-object.html";

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/update-thing.html', $template);
    return $p;
}


# ui_create_relation --
push (@raw_action_list, [ '/ui/create-relation.html', 'GET', \&ui_create_relation ]);
push (@raw_action_list, [ '/ui/create-relation.html', 
			  'POST', \&postwrapper, 
			  \&api_create_relation, undef, 'list-relations.html' ]);

sub ui_create_relation {
    my ($ctx, $info, $phr) = @_;

    my $thing = {
	relationName => 'required',
	relationVersion => '1',
    };

    foreach my $key (Relation->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, FORM => 1);

    $template->{LINKPAGE} = "create-relation.html";
    $template->{TITLE} = "creating a new relation";
    $template->{ACTION} = "create-relation.html";

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/update-thing.html', $template);
    return $p;
}

# ui_create_tag --
push (@raw_action_list, [ '/ui/create-tag.html', 'GET', \&ui_create_tag ]);
push (@raw_action_list, [ '/ui/create-tag.html', 
			  'POST', \&postwrapper, 
			  \&api_create_tag, undef, 'list-tags.html' ]);

sub ui_create_tag {
    my ($ctx, $info, $phr) = @_;

    my $thing = {
	tagName => 'required',
    };

    foreach my $key (Tag->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, FORM => 1);

    $template->{LINKPAGE} = "create-tag.html";
    $template->{TITLE} = "creating a new tag";
    $template->{ACTION} = "create-tag.html";

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/update-thing.html', $template);
    return $p;
}

# ui_delete_object_oid --
push (@raw_action_list, [ '/ui/delete-object/OID.html', 'GET', \&ui_delete_object_oid, 'OID' ]);

sub ui_delete_object_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my $rval = &api_delete_oid(@_);
    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/status.html',
			&statusify($rval,
				   NAME => 'status',
				   RETURN => 'list-objects.html'));
    return $p;
}

# ui_delete_relation_rid --
push (@raw_action_list, [ '/ui/delete-relation/RID.html', 'GET', \&ui_delete_relation_rid, 'RID' ]);

sub ui_delete_relation_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    my $rval = &api_delete_rid(@_);
    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/status.html',
			&statusify($rval,
				   NAME => 'status',
				   RETURN => 'list-relations.html'));
    return $p;
}

# ui_delete_tag_tid --
push (@raw_action_list, [ '/ui/delete-tag/TID.html', 'GET', \&ui_delete_tag_tid, 'TID' ]);

sub ui_delete_tag_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    my $rval = &api_delete_tid(@_);
    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/status.html',
			&statusify($rval,
				   NAME => 'status',
				   RETURN => 'list-tags.html'));
    return $p;
}

# ui_read_object_oid --
push (@raw_action_list, [ '/ui/get-object/OID.html', 'GET', \&ui_read_object_oid, 'OID' ]);

sub ui_read_object_oid {
    my ($ctx, $info, $phr, $oid) = @_;
    my $hashref = &api_read_oid($ctx, $info, $phr, $oid);
    my $p = Page->newHTML("ui/");

    my $body;
    my $link;
    my $selector;
    my $type = $hashref->{object}->{objectType};

    $link = "../api/object/$oid"; # invariant

    if ($type eq 'text/plain') {
	$selector = 'BODY_TEXT_PLAIN';
	$body = Object->new($oid)->auxGetBlob;
	$body =~ s!&!&amp;!go;
	$body =~ s!>!&gt;!go;
	$body =~ s!<!&lt;!go;
    }
    elsif ($type eq 'text/html') {
	$selector = 'BODY_TEXT_HTML';
	$body = Object->new($oid)->auxGetBlob;
    }
    elsif ($type =~ m!^image/(gif|png|jpeg)$!o) {
	$selector = 'BODY_IMAGE';
	$body = $hashref->{object}->{objectName} || "unnamed image";
    }
    else {
	$selector = 'BODY_OTHER';
	$body = $hashref->{object}->{objectName} || "unnamed object";
    }

    $p->addFileTemplate('template/get-thing.html',
			&loopify($hashref, 
				 ROOT => 'object',
				 EXTRA => [ IS_OBJECT => 1,
					    BODY => $body,
					    LINK => $link,
					    $selector, 1 ]));
    return $p;
}

# ui_read_relation_rid --
push (@raw_action_list, [ '/ui/get-relation/RID.html', 'GET', \&ui_read_relation_rid, 'RID' ]);

sub ui_read_relation_rid {
    my ($ctx, $info, $phr, $rid) = @_;
    my $hashref = &api_read_rid($ctx, $info, $phr, $rid);
    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/get-thing.html',
			&loopify($hashref, ROOT => 'relation'));
    return $p;
}

# ui_read_tag_tid --
push (@raw_action_list, [ '/ui/get-tag/TID.html', 'GET', \&ui_read_tag_tid, 'TID' ]);

sub ui_read_tag_tid {
    my ($ctx, $info, $phr, $tid) = @_;
    my $hashref = &api_read_tid($ctx, $info, $phr, $tid);
    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/get-thing.html',
			&loopify($hashref, ROOT => 'tag'));
    return $p;
}

##################################################################

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
	LINKPAGE => 'list-objects.html',
	TITLE => 'list objects',
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/list-objects.html', $template);
    return $p;
}


# ui_list_relations --
push (@raw_action_list, [ '/ui/list-relations.html', 'GET', \&ui_list_relations ]);

sub ui_list_relations {
    my ($ctx, $info, $phr) = @_;

    my @thingvec;

    foreach my $rid (Relation->list) {
	my $r = Relation->new($rid);
	push(@thingvec,
	     {
		 NAME => $r->get('relationName'),
		 DUMP => &dumpify($r->toDataStructure),
		 LINKFEED => MineKey->newFromRelation($r)->permalink,
		 LINKREAD => "get-relation/$rid.html",
		 LINKUPDATE => "update-relation/$rid.html",
		 LINKDELETE => "delete-relation/$rid.html",
	     });
    }

    my $template = {
	LOOP => \@thingvec,
	LINKPAGE => 'list-relations.html',
	TITLE => 'list relations',
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/list-relations.html', $template);
    return $p;
}

# ui_list_tags --
push (@raw_action_list, [ '/ui/list-tags.html', 'GET', \&ui_list_tags ]);

sub ui_list_tags {
    my ($ctx, $info, $phr) = @_;

    my @thingvec;

    foreach my $tid (Tag->list) {
	my $t = Tag->new($tid);
	push(@thingvec,
	     {
		 NAME => $t->get('tagName'),
		 DUMP => &dumpify($t->toDataStructure),
		 LINKREAD => "get-tag/$tid.html",
		 LINKUPDATE => "update-tag/$tid.html",
		 LINKDELETE => "delete-tag/$tid.html",
	     });
    }

    my $template = {
	LOOP => \@thingvec,
	LINKPAGE => 'list-tags.html',
	TITLE => 'list tags',
    };

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/list-tags.html', $template);
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
push (@raw_action_list, [ '/ui/update-object/OID.html', 
			  'POST', \&postwrapper, 
			  \&api_create_keys_oid, undef, 'list-objects.html', 
			  'OID']);

sub ui_update_object_oid {
    my ($ctx, $info, $phr, $oid) = @_;

    my $thing = (&api_read_oid($ctx, $info, $phr, $oid))->{object};

    foreach my $key (Object->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, FORM => 1);

    $template->{TITLE} = "editing object $oid";
    $template->{LINKPAGE} = "get-object/$oid.html";
    $template->{ACTION} = "update-object/$oid.html";

    $template->{LINKAUX} = "../api/object/$oid";
    $template->{AUXTITLE} = "(data)";

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/update-thing.html', $template);
    return $p;
}

# ui_update_relation_rid --
push (@raw_action_list, [ '/ui/update-relation/RID.html', 'GET', \&ui_update_relation_rid, 'RID' ]);
push (@raw_action_list, [ '/ui/update-relation/RID.html', 
			  'POST', \&postwrapper, 
			  \&api_create_keys_rid, undef, 'list-relations.html', 
			  'RID']);

sub ui_update_relation_rid {
    my ($ctx, $info, $phr, $rid) = @_;

    my $thing = (&api_read_rid($ctx, $info, $phr, $rid))->{relation};

    foreach my $key (Relation->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, FORM => 1);

    $template->{TITLE} = "editing relation $rid";
    $template->{LINKPAGE} = "get-relation/$rid.html";
    $template->{ACTION} = "update-relation/$rid.html";

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/update-thing.html', $template);
    return $p;
}

# ui_update_tag_tid --
push (@raw_action_list, [ '/ui/update-tag/TID.html', 'GET', \&ui_update_tag_tid, 'TID' ]);
push (@raw_action_list, [ '/ui/update-tag/TID.html', 
			  'POST', \&postwrapper, 
			  \&api_create_keys_tid, undef, 'list-tags.html', 
			  'TID']);

sub ui_update_tag_tid {
    my ($ctx, $info, $phr, $tid) = @_;

    my $thing = (&api_read_tid($ctx, $info, $phr, $tid))->{tag};

    foreach my $key (Tag->new->keysWritable) {
	$thing->{$key} = '' unless defined($thing->{$key});
    }

    my $template = &loopify($thing, FORM => 1);

    $template->{TITLE} = "editing tag $tid";
    $template->{LINKPAGE} = "get-tag/$tid.html";
    $template->{ACTION} = "update-tag/$tid.html";

    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/update-thing.html', $template);
    return $p;
}

##################################################################

# ui_version --
push (@raw_action_list, [ '/ui/version.html', 'GET', \&ui_version ]);

sub ui_version {
    my $hashref = &api_version(@_); # fast way to send args
    my $p = Page->newHTML("ui/");
    $p->addFileTemplate('template/version.html', $hashref->{version});
    return $p;
}


##################################################################

1;
