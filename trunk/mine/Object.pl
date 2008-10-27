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

sub auxPut {
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

sub auxGetFH {
    my $self = shift;
    my $retval;

    my $id = $self->id;
    die "auxGet: cannot get aux data without an id for filename\n" unless ($id > 0);
    my $file = $self->filepath("$id.data");

    my $fh = FileHandle->new;
    unless ($fh->open($file)) {
	die "auxGetFH: open: $file: $!\n";
    }

    return $fh;
}

sub auxGet {
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

my $MAGIC_TAG_KEY = 'objectTags';

sub set {
    my ($self, $key, $value) = @_;

    if ($key eq $MAGIC_TAG_KEY) {
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $foo;

	    unless ($src =~ m!^(for:|not:)?(.+)$!o) {
		die "Object: get: bad format for elements of $key: '$src'\n";
	    }

	    if ($1 eq '') {
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

    if ($key eq $MAGIC_TAG_KEY) {
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $foo;

	    unless ($src =~ m!^(r[-+])?(\d+)$!o) {
		die "Object: get: bad format for elements of $key: '$src'\n";
	    }

	    if ($1 eq 'r+') {
		my $relation = Relation->new($2);
		$foo = 'for:' . $relation->name;
	    }
	    elsif ($1 eq 'r-') {
		my $relation = Relation->new($2);
		$foo = 'not:' . $relation->name;
	    }
	    else {
		my $tag = Tag->new($2);
		$foo = $tag->name;
	    }

	    push(@dsts, $foo);
	}
	$value = join(" ", @dsts);
    }
    return $value;
}

##################################################################

1;
