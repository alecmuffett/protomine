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

package Tag;

use strict;
use warnings;
#use diagnostics;

use vars qw(@ISA);
#require 'mine/Thing.pl';
@ISA = qw( Thing );

##################################################################

sub boot {
    my $self = shift;

    $self->{DIRECTORY} = 'database/tags';

    $self->{ENFORCE_UNIQUE_NAMES} = 1;	# true, for tags
    $self->{ID_KEY} = 'tagId';
    $self->{NAME_KEY} = 'tagName';

    $self->{REQUIRED_KEYS} = {
	tagName => 1,
    };

    $self->{VALID_KEYS} = {
	tagId => 1,
	tagName => 1,
	tagParents => 1,
    };

    $self->{WRITABLE_KEYS} = {
	tagName => 1,
	tagParents => 1,
    };

    return $self;
}

##################################################################

# overrides for get and set

my $MAGIC_TAG_KEY = 'tagParents';

# tags can only be created with names matching /[\-\w]+/ (ie:
# alphanumeric plus underscore plus hyphen)

sub set {
    my ($self, $key, $value) = @_;

    if ($key eq $self->{NAME_KEY}) {
	unless ($value =~ m!^[\-\w]+$!o) {
	    die "Tag: cannot set $key=$value as '$value' has illegal format\n";
	}
    }
    elsif ($key eq $MAGIC_TAG_KEY) { 
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $id = Tag->existsName($src);

	    if ($id < 0) {
		die "Tag: multiply-defined parent tags of $key: '$src'\n";
	    }
	    elsif ($id == 0) {
		die "Tag: unknown parent tags of $key: '$src'\n";
	    }

	    push(@dsts, $id);
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
	    unless ($src =~ m!^\d+$!o) {
		die "Tag: bad format for elements of $key: '$src'\n";
	    }

	    my $tag = Tag->new($src);
	    push(@dsts, $tag->name);
	}
	$value = join(" ", @dsts);
    }
    return $value;
}

##################################################################

1;
