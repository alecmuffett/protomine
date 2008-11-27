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
#use diagnostics;

use vars qw(@ISA);
#require 'mine/Thing.pl';
@ISA = qw( Thing );

##################################################################

sub boot {
    my $self = shift;

    $self->{DIRECTORY} = 'database/comments'; # NEEDS FIXING FOR COMMENTS; OVERRIDE new()

    $self->{ENFORCE_UNIQUE_NAMES} = 0;	# false, for comments
    $self->{ID_KEY} = 'commentId';
    $self->{NAME_KEY} = 'commentSubject';

    $self->{REQUIRED_KEYS} = {
	commentBody => 1,
	commentRelationID => 1,	# from infrastructure, not user supplied
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

    return $self;
}


##################################################################

1;
