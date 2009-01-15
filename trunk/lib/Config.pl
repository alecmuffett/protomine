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

package Config;

use strict;
use warnings;

use vars qw(@ISA);
#require 'mine/Thing.pl';
@ISA = qw( Thing );

##################################################################

sub boot {
    my $self = shift;
    $self->{DIRECTORY} = 'database/config';
    $self->{ENFORCE_UNIQUE_NAMES} = 0;
    $self->{ID_KEY} = 'configId';
    $self->{NAME_KEY} = 'configData';
    $self->{REQUIRED_KEYS} = {};
    $self->{VALID_KEYS} = {};
    $self->{WRITABLE_KEYS} = {};
    return $self;
}

##################################################################

sub keysValid {
    my $self = shift;
    return grep { $_ ne 'configId'} keys %{$self->{DATA}};
}

sub validKey {
    return 1;
}

sub keysWritable {
    my $self = shift;
    return grep { $_ ne 'configId'} keys %{$self->{DATA}};
}

sub writableKey {
    return 1;
}

sub list {
    return (1);
}

1;
