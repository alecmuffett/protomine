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

package Relation;

use strict;
use warnings;
#use diagnostics;

use vars qw(@ISA);
#require 'mine/Thing.pl';
@ISA = qw( Thing );

##################################################################

sub boot {
    my $self = shift;

    $self->{DIRECTORY} = 'database/relations';

    $self->{ENFORCE_UNIQUE_NAMES} = 1; # true, for Relations

    $self->{ID_KEY} = 'relationId';
    $self->{NAME_KEY} = 'relationName';

    $self->{REQUIRED_KEYS} = {
	relationName => 1,
	relationVersion => 1,
    };

    $self->{VALID_KEYS} = {
	relationDescription => 1,
	relationContact => 1,
	relationId => 1,
	relationName => 1,
	relationNetworkAddress => 1,
	relationInterests => 1,
	relationImageURL => 1,
	relationURL => 1,
	relationVersion => 1,
    };

    $self->{WRITABLE_KEYS} = {
	relationDescription => 1,
	relationContact => 1,
	relationName => 1,
	relationNetworkAddress => 1,
	relationInterests => 1,
        relationImageURL => 1,
	relationURL => 1,
	relationVersion => 1,
    };

    return $self;
}

##################################################################

# overrides for get and set

# relationship name can only be created with names matching /[\-\w]+/
# (ie: alphanumeric plus underscore plus hyphen)

sub set {
    my ($self, $key, $value) = @_;

    if ($key eq $self->{NAME_KEY}) {
	unless ($value =~ m!^[\-\w]+$!o) {
	    die "Relation: cannot set $key=$value as '$value' has illegal format\n";
	}
	$value =~ tr/_A-Z/-a-z/; # force relation names lowercase, force underscore to hyphen
    }
    elsif ($key eq 'relationInterests') {
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $foo;

	    unless ($src =~ m!^(require:|except:)?(.+)$!o) {
		die "Relation: set: bad format for elements of $key: '$src'\n";
	    }

	    my $id = Tag->existsName($2);

	    if ($id < 0) {
		die "Relation: multiply-defined tags given in $key: '$src'\n";
	    }
	    elsif ($id == 0) {
		die "Relation: unknown tags given in $key: '$src'\n";
	    }

	    if (!defined($1)) {
		$foo = $id;
	    }
	    elsif ($1 eq 'require:') {
		$foo = "t+$id";
	    }
	    elsif ($1 eq 'except:') {
		$foo = "t-$id";
	    }
	    else {
		die "this can't happen";
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

    if ($key eq 'relationInterests') {
	my @srcs = split(" ", $value);
	my @dsts;

	foreach my $src (@srcs) {
	    my $foo;

	    unless ($src =~ m!^(t[-+])?(\d+)$!o) {
		die "Relation: get: bad format for elements of $key: '$src'\n";
	    }

	    my $tag = Tag->new($2);

	    if ($1 eq 't+') {
		$foo = 'require:' . $tag->name;
	    }
	    elsif ($1 eq 't-') {
		$foo = 'except:' . $tag->name;
	    }
	    else {
		$foo = $tag->name;
	    }

	    push(@dsts, $foo);
	}
	$value = join(" ", @dsts);
    }
    return $value;
}

sub getInterestsBlob {
    my ($self) = @_;

    # load the raw tags describing this object
    my $rawtags = $self->SUPER::get('relationInterests');

    # split the raw tags on space
    my @tags = split(" ", $rawtags);

    # the iblob is our return value
    my $iblob = {};
    $iblob->{rid} = $self->id; # who this iblob prepresents

    # for each of the tags, file it in the appropriate category
    foreach my $tag (@tags) {
	unless ($tag =~ m!^(t[-+])?(\d+)$!o) {
	    die "Relation: getInterestsBlob: bad format for elements of 'relationInterests': '$tag'\n";
	}

	if (!defined($1)) {
	    push(@{$iblob->{interests}}, $2); # interests
	}
	elsif ($1 eq 't+') {
	    push(@{$iblob->{require}}, $2); # require
	}
	elsif ($1 eq 't-') {
	    push(@{$iblob->{except}}, $2); # except
	}
	else {
	    die "this can't happen";
	}

    }

    # return the reference for the iblob
    return $iblob;
}

##################################################################

sub relationVersion {
    my $self = shift;
    return $self->get('relationVersion');
}

##################################################################

1;
