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

package Object;

use strict;
use warnings;
#use diagnostics;

use vars qw(@ISA);
#require 'mine/Thing.pl';
@ISA = qw( Thing );

use FileHandle;

my $BUFSIZ = 1024 * 64;

##################################################################

sub boot {
    my $self = shift;

    $self->{DIRECTORY} = 'database/objects';

    $self->{ENFORCE_UNIQUE_NAMES} = 0; # false, for Objects

    $self->{ID_KEY} = 'objectId';
    $self->{NAME_KEY} = 'objectName';

    $self->{REQUIRED_KEYS} = {
	objectName => 1,
	objectStatus => 1,
	objectType => 1,
    };

    $self->{VALID_KEYS} = {
	objectDescription => 1,
	objectId => 1,
	objectName => 1,
	objectStatus => [ qw{ draft final public } ],
	objectTags => 1,
	objectType => 1,
    };

    $self->{WRITABLE_KEYS} = {
	objectDescription => 1,
	objectName => 1,
	objectStatus => 1,
	objectTags => 1,
	objectType => 1,
    };

    return $self;
}

##################################################################

sub auxPutFH {
    my $self = shift;
    my $fh = shift;

    my $id = $self->id;
    die "auxPutFH: cannot save aux data without an id for filename\n" unless ($id > 0);
    my $file = $self->filepath("$id.data");
    my $buffer;

    # re/write the new file
    open(AUXPUTFH, ">$file~new") or die "auxPutFH: open: >$file~new: $!\n";
    while (read($fh, $buffer, $BUFSIZ) > 0) {
	print AUXPUTFH $buffer;
    }
    close(AUXPUTFH) or die "auxPutFH: close: $file: $!\n";

    # install the file
    $self->fileRename("$file~new", $file);
}

sub auxPutBlob {
    my $self = shift;
    my $data = shift;

    my $id = $self->id;
    die "auxPut: cannot save aux data without an id for filename\n" unless ($id > 0);
    my $file = $self->filepath("$id.data");

    # re/write the new file
    open(AUXPUT, ">$file~new") or die "auxPut: open: >$file~new: $!\n";
    print AUXPUT $data;
    close(AUXPUT) or die "auxPut: close: $file: $!\n";

    # install the file
    $self->fileRename("$file~new", $file);
}

sub auxGetFile {
    my $self = shift;
    my $retval;

    my $id = $self->id;

    die "auxGetFile: cannot get aux data without an id for filename\n" unless ($id > 0);

    return $self->filepath("$id.data");
}

sub auxGetBlob {
    my $self = shift;
    my $retval;

    my $id = $self->id;

    die "auxGet: cannot get aux data without an id for filename\n" unless ($id > 0);

    my $file = $self->filepath("$id.data");
    my $filesize = (-s $file);

    # read the new file
    open(AUXGET, $file) or die "auxGet: open: $file: $!\n";
    unless (read(AUXGET, $retval, $filesize) == $filesize) {
	die "auxGet: read: short read on $file: $!\n";
    }
    close(AUXGET) or die "auxGet: close: $file: $!\n";

    return $retval;
}

##################################################################

# overrides for get and set

sub set {
    my ($self, $key, $value) = @_;

    if ($key eq 'objectTags') {
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $foo;

	    unless ($src =~ m!^(for:|not:)?(.+)$!o) {
		die "Object: get: bad format for elements of $key: '$src'\n";
	    }

	    if (!defined($1)) { # no "for:" or "not:" prefix
		my $id = Tag->existsName($2);
		$foo = $id;
	    }
	    else {
		my $id = Relation->existsName($2);

		if ($id < 0) {
		    die "Object: multiply-defined relations given in $key: '$src'\n";
		}
		elsif ($id == 0) {
		    die "Object: unknown relations given in $key: '$src'\n";
		}

		if ($1 eq 'for:') {
		    $foo = "r+$id";
		}
		elsif ($1 eq 'not:') {
		    $foo = "r-$id";
		}
	    }

	    push(@dsts, $foo);
	}
	$value = join(" ", @dsts);
    }
    return $self->SUPER::set($key, $value);
}

sub get {
    my ($self, $key) = @_;
    my $value = $self->SUPER::get($key);

    if ($key eq 'objectTags') {
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $foo;

	    unless ($src =~ m!^(r[-+])?(\d+)$!o) {
		die "Object: get: bad format for elements of $key: '$src'\n";
	    }

	    if (!defined($1)) {
		my $tag = Tag->new($2);
		$foo = $tag->name;
	    }
	    elsif ($1 eq 'r+') {
		my $relation = Relation->new($2);
		$foo = 'for:' . $relation->name;
	    }
	    elsif ($1 eq 'r-') {
		my $relation = Relation->new($2);
		$foo = 'not:' . $relation->name;
	    }
	    else {
		die "this can't happen";
	    }

	    push(@dsts, $foo);
	}
	$value = join(" ", @dsts);
    }
    return $value;
}

##################################################################

# returns non-zero on match, 0 on fail

sub matchInterestsBlob {
    my $self = shift;
    my $iblob = shift;

    # verbose debugging switch in this code
    # bitmask: 0x01 = debug FAILs, 0x02 = debug PASSes
    my $mdebug = 0x02;

    # upon whose we are checking
    my $rid = $iblob->{rid};
    my $oid = $self->id;

    # load the raw tags describing this object
    my $rawtags = $self->SUPER::get('objectTags');

    # no tags -> fast fail
    unless (defined($rawtags)) {
	warn "FAIL: oid=$oid/rid=$rid object has no tags\n" if ($mdebug & 0x01);
	return 0;
    }

    # split the raw tags on space
    my @tags = split(" ", $rawtags);
    my $tag;

    # first sweep: fail fast if "not:RELATION"
    foreach $tag (@tags) {
	if ($tag eq "r-$rid") { # is marked not:RELATION
	    warn "FAIL: oid=$oid/rid=$rid object is marked not:$rid\n" if ($mdebug & 0x01);
	    return 0;
	}
    }

    # second sweep: succeed fast if "for:RELATION"

    foreach $tag (@tags) {
	if ($tag eq "r+$rid") { # is marked for:RELATION
	    warn "PASS: oid=$oid/rid=$rid object is marked for:$rid\n" if ($mdebug & 0x02);
	    return 1;
	}
    }

    # expand the tagImplies to permit implicit matching

    my %tobedone;
    my @tbd;

    # states in %tobedone :=
    # state 0/undef - not known
    # state 1 - known but not expanded
    # state 2 - known and expanded

    # populate %tobedone with initial tags

    foreach $tag (grep(/^\d+$/, @tags)) {
	$tobedone{$tag} = 1;
    }

    # repeatedly scan over the members of %tobedone looking for
    # anything with keys where state==1; the list of those keys (tags)
    # is then expanded to retreive their PARENT TAGS who are then
    # populated into %tobedone iff they have not already been expanded
    # (ie: iff state==2)

    # OBVIOUS FUTURE OPTIMISATION: add the exclude/require code into
    # this expansion, for fast tracking...

    while (@tbd = grep { $tobedone{$_} == 1 } keys %tobedone) {
	foreach $tag (@tbd) {
	    my $x = Tag->new($tag);
	    my $xrawtags = $x->SUPER::get('tagImplies');

	    if (defined($xrawtags)) {
		my @xtags = grep(/^\d+$/, split(" ", $xrawtags));

		foreach my $xtag (@xtags) {
		    if (defined($tobedone{$xtag}) and $tobedone{$xtag} == 2) {
			next;   # already done, so skip
		    }
		    $tobedone{$xtag} = 1; # mark it to be done
		}
	    }
	    $tobedone{$tag} = 2; # mark it done
	}
    }

    # flatten the keys of %tobedone to provide the expanded tag list

    my @expanded_tags = keys %tobedone;

    # third sweep: fail fast for for exclude:TAG

    my %user_excepts;

    map { $user_excepts{$_}++ } @{$iblob->{except}};

    foreach $tag (@expanded_tags) {
	if ($user_excepts{$tag}) {
	    warn "FAIL: oid=$oid/rid=$rid relation marked as except:$tag (in: @expanded_tags)\n" if ($mdebug & 0x01);
	    return 0;
	}
    }

    # fourth (inverse) sweep: check for presence of all
    # user_requirements in @expanded_tags; fail fast if ANY
    # user_requirements are missing

    my $reqctr = 0;

    foreach my $user_requirement (@{$iblob->{require}}) {
	unless (grep { $_ eq $user_requirement } @expanded_tags) {
	    warn "FAIL: oid=$oid/rid=$rid object fails require:$user_requirement (in: @expanded_tags)\n" if ($mdebug & 0x01);
	    return 0;
	}

	$reqctr++;
    }

    # fast track: succeed fast if all user_requirements (and of which
    # there are more than zero) have been met

    if ($reqctr) {
	warn "PASS: oid=$oid/rid=$rid object satisfies all require: tags (in: @expanded_tags)\n" if ($mdebug & 0x02);
	return 2;
    }

    # final sweep: check for tag overlap, for any remaining reason to
    # match it

    foreach my $interest (@{$iblob->{interests}}) {

	if (grep { $_ eq $interest } @expanded_tags) {
	    warn "PASS: oid=$oid/rid=$rid object $oid overlaps relation's interests (in: @expanded_tags)\n" if ($mdebug & 0x02);
	    return 3;
	}
    }

    # we didnae find reason to share this one
    warn "FAIL: oid=$oid/rid=$rid relation not interested in object\n" if ($mdebug & 0x01);

    return 0;
}

##################################################################

sub toAtom {
    my $self = shift;
    my $permalink = shift; # how the recipient of this feed will refer to this object

    # <entry>
    # <title>Atom-Powered Robots Run Amok</title>
    # <link href="http://example.org/2003/12/13/atom03"/>
    # <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
    # <updated>2003-12-13T18:30:02Z</updated>
    # <summary>Some text.</summary>
    # </entry>

    # TODO: the ID field needs to be a GUID of some sort, or a URL;
    # but the private permalink should not be exposed, and the
    # per-user shared permalink is too changable... so we should
    # probably HMAC the private permalink with a nonce which is NOT
    # the same as the mine's cryptokey.  For the moment, though, we'll
    # fake something up.

    my $rid = shift;            # on behalf of whom this is being prepared

    my $oid = $self->id;        # the object number

    my @atom;                   # where the results are stored

    my $title = $self->get('objectName') || "(title undefined)";

    my $id = $permalink;        # this needs to be generated/permanent?

    my $updated = &main::atom_format($self->lastModified);

    my $summary = $self->get('objectDescription') || "(summary undefined)";

    my $objectType = $self->get('objectType');
    my $objectDescription = $self->get('objectDescription');

    my $content;

    $content = $objectDescription . "\n";

    if ($objectType eq 'text/html') { # include verbatim
	$content .= "[html content of object $oid]";
    }
    elsif ($objectType eq 'text/plain') { # do HTML escaping
	$content .= "[html-escaped plain text content of object $oid]";
    }
    else {			# generate a stub
	$content .= "[synthetic stub for object of type $objectType]";
    }

    push(@atom, "<entry xml:base='$main::MINE_HTTP_FULLPATH'>\n");
    push(@atom, "<title>$title</title>\n");
    push(@atom, "<link href='$permalink'/>\n");
    push(@atom, "<id>$id</id>\n");
    push(@atom, "<updated>$updated</updated>\n");
    push(@atom, "<summary>$summary</summary>\n");
    push(@atom, "<content>$content</content>\n");
    push(@atom, "</entry>\n");

    return \@atom;
}

1;
