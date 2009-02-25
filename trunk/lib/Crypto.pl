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

package Crypto;

use strict;
use warnings;

##################################################################

sub new {
    my $class = shift;
    my $self = { };
    bless $self, $class;
    return $self;
}

##################################################################

sub encrypt {
    my ($class, $plaintext) = @_;
    my $ciphertext = unpack("H*", $plaintext); # coersce scalar context
    # warn "encrypt $plaintext -> $ciphertext\n";
    return $ciphertext;
}

##################################################################

sub decrypt {
    my ($class, $ciphertext) = @_;
    my $plaintext = pack("H*", $ciphertext); # coersce scalar context
    # warn "decrypt $ciphertext -> $plaintext\n";
    return $plaintext;
}

##################################################################

sub hashify {
    my ($class, $plaintext) = @_;
    my $hashify = unpack("%C*", $plaintext);
    # warn "hash $plaintext -> $hashify\n";
    return $hashify;
}

##################################################################

sub resetPrivateKey {
    die "resetPrivateKey not yet implemented";
}

##################################################################

1;
