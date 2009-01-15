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

package Comment;

use strict;
use warnings;

use vars qw(@ISA);
#require 'mine/Thing.pl';
@ISA = qw( Thing );

# Comments can be dealt with pretty easily by just wholly overriding
# the Thing constructor to make use of the necessary second argument

sub new {
    my $class = shift;
    my $oid = shift;
    my $cid = shift;

    if (ref($class)) {
        $class = ref($class);
    }

    my $self = {};

    $self->{CLASS} = $class;
    $self->{DATA} = {};

    bless $self, $class;

    $self->{DIRECTORY} = 'database/objects/$oid';
    $self->{ENFORCE_UNIQUE_NAMES} = 0;
    $self->{ID_KEY} = 'commentId';
    $self->{NAME_KEY} = 'commentSubject';

    $self->{REQUIRED_KEYS} = {
	commentBody => 1,
	commentRelationID => 1,
    };

    $self->{VALID_KEYS} = {
	commentId => 1,
	commentSubject => 1,
	commentBody => 1,
	commentRelationId => 1,
    };

    $self->{WRITABLE_KEYS} = {
	commentSubject => 1,
	commentBody => 1,
	commentRelationId => 1,
    };

    if (defined($cid)) {
        $self->load($cid)
    }

    return $self;
}

##################################################################

1;
