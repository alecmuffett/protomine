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

my $MINEKEY_MAGIC = "mine";
my $CRYPTFMT = "%H*";
my $HASHFMT = "%C*";
my $METHODRX = qr!(read|post)!;

##################################################################

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

##################################################################

sub resetPrivateKey {
}

##################################################################

sub encrypt {
    my ($class, $plaintext) = @_;
    return unpack($CRYPTFMT, $plaintext);
}

sub decrypt {
    my ($class, $ciphertext) = @_;
    return pack($CRYPTFMT, $ciphertext);
}

sub hashify {
    my ($class, $plaintext) = @_;
    return unpack($HASHFMT, $plaintext);
}

##################################################################

sub encodeMineKey {
    my ($self, $method, $rid, $rvsn, $oid) = @_;

    die "encodeMineKey: bad method $method\n" unless ($method =~ m!^$METHODRX$!o);
    die "encodeMineKey: bad rid $rid\n" unless ($rid > 0);
    die "encodeMineKey: bad rvsn $rvsn\n" unless ($rvsn > 0);
    die "encodeMineKey: bad oid $oid\n" unless ($oid >= 0);

    my $prefix = "$MINEKEY_MAGIC,$method,$rid,$rvsn,$oid";
    my $crc = Crypto->hashify($prefix);
    my $plaintext = "$prefix,$crc";
    my $minekey = Crypto->encrypt($plaintext);

    return $minekey;
}

##################################################################

sub decodeMineKey {
    my ($self, $minekey) = @_;

    my $plaintext = Crypto->decrypt($minekey);

    my ($magic, $method, $rid, $rvsn, $oid, $crc);

    unless (($magic, $method, $rid, $rvsn, $oid, $crc) =
	    ($plaintext =~ m!^(\w+),$METHODRX,(\d+),(\d+),(\d+),(\d+)$!o)) {
	die "decodeMineKey: bad decode result\n";
    }

    die "decodeMineKey: bad magic $magic\n" unless ($magic eq $MINEKEY_MAGIC);
    # $method is typechecked in the regexp
    die "decodeMineKey: bad rid $rid\n" unless ($rid > 0);
    die "decodeMineKey: bad rvsn $rvsn\n" unless ($rvsn > 0);
    die "decodeMineKey: bad oid $oid\n" unless ($oid >= 0);

    # try to recreate the hash, and check
    my $prefix2 = "$MINEKEY_MAGIC,$method,$rid,$rvsn,$oid";
    my $crc2 = Crypto->hashify($prefix2);
    die "decodeMineKey: bad crc check\n" unless ($crc2 eq $crc);

    return ($method, $rid, $rvsn, $oid);
}

##################################################################

1;
