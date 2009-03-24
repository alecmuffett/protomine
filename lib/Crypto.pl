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
use Digest::SHA;

use strict;
use warnings;

##################################################################

sub reset { 			# **** CLASS METHOD
    my $keyfile = "database/config/key.txt";

    my $nonce = Crypt::CBC->random_bytes(32);
    my $key = Crypt::CBC->random_bytes(32);

    my $nonce_hex = unpack("H*", $nonce);
    my $key_hex = unpack("H*", $key);

    die "Crypto: reset: $keyfile already exists, will not clobber.\n" if (-f $keyfile);

    open(KEY, ">$keyfile") or die "open: >$keyfile: $!\n";
    print KEY "$nonce_hex\n$key_hex\n";
    close(KEY);
}

##################################################################

sub new {
    my $class = shift;

    my $self = { };
    my $keyfile = "database/config/key.txt";

    my $nonce_hex;
    my $key_hex;

    open(KEY, $keyfile) or die "open: $keyfile: $!\n";
    chomp($nonce_hex = <KEY>);
    chomp($key_hex = <KEY>);
    close(KEY);

    my $nonce = pack("H*", $nonce_hex);
    die "corrupt hex nonce '$nonce_hex'\n" unless (length($nonce) == 32);
    $self->{nonce} = $nonce;

    my $key = pack("H*", $key_hex);
    die "corrupt hex key '$key_hex'\n" unless (length($key) == 32);
    $self->{key} = $key;

    bless $self, $class;
    return $self;
}

##################################################################

sub encrypt {
    my ($self, $salt, $plaintext) = @_;

    my $iv_pre_digest = $salt . ',' . $self->{nonce};
    my $iv_allbits = $self->digest($iv_pre_digest);
    my $iv = substr($iv_allbits, 0, 16); # AES IV takes 128 bits / 16 bytes

    my $cipher =
	Crypt::CBC->new(
	    -cipher => "Crypt::Rijndael",
	    -key => $self->{key},
	    -literal_key => 1,
	    -iv => $iv,
	    -header => 'none',
	);

    my $iv_hex = unpack("H*", $iv);
    my $ciphertext = $cipher->encrypt_hex($plaintext);

    return sprintf "%s:%s", $iv_hex, $ciphertext;
}

##################################################################

sub decrypt {
    my ($self, $ciphertext) = @_;

    my ($iv_hex, $ct_hex) = split(/:/, $ciphertext);

    my $iv = pack("H*", $iv_hex);
    die "corrupt hex iv '$iv_hex'\n" unless (length($iv) == 16);

    my $cipher =
	Crypt::CBC->new(
	    -cipher => "Crypt::Rijndael",
	    -key => $self->{key},
	    -literal_key => 1,
	    -iv => $iv,
	    -header => 'none',
	);

    return $cipher->decrypt_hex($ct_hex);
}

##################################################################

sub digest {
    my ($self, $plaintext) = @_;

    my $ctx = Digest::SHA->new(256)->add($plaintext);
    return $ctx->digest;
}

##################################################################

sub checksum {
    my ($self, $plaintext) = @_;

    my $checksum = unpack("%16C*", $plaintext);
    return $checksum;
}

##################################################################

1;
