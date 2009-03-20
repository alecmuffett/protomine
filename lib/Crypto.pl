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

use Crypt::CBC;

use strict;
use warnings;

##################################################################

sub reset { 			# **** CLASS METHOD
    my $keyfile = "database/config/key.txt";

    my $iv = Crypt::CBC->random_bytes(16);
    my $key = Crypt::CBC->random_bytes(32);

    my $iv_hex = unpack("H*", $iv);
    my $key_hex = unpack("H*", $key);
    
    die "Crypto: reset: $keyfile already exists, will not clobber.\n" if (-f $keyfile);

    open(KEY, ">$keyfile") or die "open: >$keyfile: $!\n";
    print KEY "$iv_hex\n$key_hex\n";
    close(KEY); 
}

##################################################################

sub new {
    my $class = shift;

    my $self = { };

    my $keyfile = "database/config/key.txt";

    my $iv_hex;
    my $key_hex;

    open(KEY, $keyfile) or die "open: $keyfile: $!\n";
    chomp($iv_hex = <KEY>); 
    chomp($key_hex = <KEY>);
    close(KEY);

    my $iv = pack("H*", $iv_hex);
    my $key = pack("H*", $key_hex);

    die "corrupt hex iv '$iv_hex'\n" unless (length($iv) == 16);
    die "corrupt hex key '$key_hex'\n" unless (length($key) == 32);

    my $cipher = Crypt::CBC->new( 
	-iv => $iv,
	-key => $key,
	-literal_key => 1, 
	-cipher => "Crypt::Rijndael",
	-header => 'none',
	);

    $self->{cipher} = $cipher;

    bless $self, $class;
    return $self;
}

##################################################################

sub encrypt {
    my ($self, $plaintext) = @_;
    return $self->{cipher}->encrypt_hex($plaintext);
}

##################################################################

sub decrypt {
    my ($self, $ciphertext) = @_;
    return $self->{cipher}->decrypt_hex($ciphertext);
}

##################################################################

sub hashify {
    my ($self, $plaintext) = @_;
    my $hashify = unpack("%C*", $plaintext);
    return $hashify;
}

##################################################################

1;
