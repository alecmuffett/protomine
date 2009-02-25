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

package MineKey;

use strict;
use warnings;

##################################################################

# MINE KEY STRUCTURE

# csum,"mine",keyversion,method,depth,rid,rvsn,oid,opt
# csum = hash(keyversion,method,depth,rid,rvsn,oid,opt)
# "mine" = fixed string
# keyversion = key version number
# method: 0 = get/read, 1 = write/post, other = error
# depth: depth of this URL fetch; if depth = 0, fails elsewhere
# rid: relation id
# rvsn: relation version
# oid: object id
# opt: optional argument (eg: comment id)

sub new {
    my $class = shift;

    my ($method, $depth, $rid, $rvsn, $oid, $opt) = @_;

    warn "MineKey new($method, $depth, $rid, $rvsn, $oid, $opt)\n";

    my $self = {};

    bless $self, $class;

    $self->{keyversion} = 1;
    $self->{method} = $method;
    $self->{depth} = $depth;
    $self->{rid} = $rid;
    $self->{rvsn} = $rvsn;
    $self->{oid} = $oid;
    $self->{opt} = $opt;

    $self->validate('MineKey constructor');


    return $self;
}

sub validate {
    my ($self, $diag) = @_;

    # validate allows depth=0, you need to test that elsewhere

    unless ($self->{keyversion} == 1) {
	die "validate($diag): bad keyversion $self->{keyversion}\n";
    }
    unless (($self->{method} >= 0) and ($self->{method} <= 1)) {
	die "validate($diag): bad method $self->{method}\n";
    }
    unless ($self->{depth} >= 0) {
	die "validate($diag): bad depth $self->{depth}\n";
    }
    unless ($self->{rid} > 0) {
	die "validate($diag): bad rid $self->{rid}\n";
    }
    unless ($self->{rvsn} > 0) {
	die "validate($diag): bad rvsn $self->{rvsn}\n";
    }
    unless ($self->{oid} >= 0) {
	die "validate($diag): bad oid $self->{oid}\n";
    }
    unless ($self->{opt} >= 0) {
	die "validate($diag): bad opt $self->{opt}\n";
    }
}

##################################################################

sub newFromEncoded {
    my ($class, $ciphertext) = @_;

    # decrypt
    my $plaintext = Crypto->decrypt($ciphertext);

    # break out the checksum
    my ($csum, $minekey) = split(/,/, $plaintext, 2);

    # first check pre-parse
    my $check1 = Crypto->hashify($minekey);
    die "newFromEncoded($ciphertext): security pre-parse checksum failed\n" if ($check1 != $csum);

    # the parse
    my ($cookie, $keyversion, $method, $depth, $rid, $rvsn, $oid, $opt) = split(/,/, $minekey);

    # check the field that validate does not cover
    die "newFromEncoded($ciphertext): security bad cookie in $plaintext\n" unless ($cookie eq 'mine');

    # the reconstruct
    my $check2 = Crypto->hashify("mine,$keyversion,$method,$depth,$rid,$rvsn,$oid,$opt");
    die "newFromEncoded($ciphertext): security post-parse checksum failed\n" if ($check2 != $csum);

    # the instantition (will reflash keyversion to current)
    return $class->new($method, $depth, $rid, $rvsn, $oid, $opt);
}

##################################################################

sub newFromRelation {
    my ($class, $r) = @_;

    my $depth = 3;		# HARDCODED !!!

    return $class->new(0,
		       $depth,
		       $r->id,		  
		       $r->relationVersion,
		       0,
		       0);
}

# not doing a newFromRid() method to encourage optimisation

##################################################################

sub encode {
    my $self = shift;

    # check the data for consistency
    $self->validate;

    # make the text
    my $body = sprintf("mine,%s,%s,%s,%s,%s,%s,%s",
		       $self->{keyversion},
		       $self->{method},
		       $self->{depth},
		       $self->{rid},
		       $self->{rvsn},
		       $self->{oid},
		       $self->{opt});

    # compute the checksum
    my $csum = Crypto->hashify($body);

    # make the plaintext
    my $plaintext = "$csum,$body";

    # encrypt and encode
    my $ciphertext = Crypto->encrypt($plaintext);

    # return
    return $ciphertext;
}

sub permalink {
    my $self = shift;

    my $encoded = $self->encode;

    return $main::MINE_HTTP_FULLPATH . "/get?key=$encoded";
}

sub spawnOid {
    my $self = shift;
    my $oid = shift;

    return MineKey->new(0,		    # get
			$self->{depth} - 1, # decrement
			$self->{rid},	    # inherit
			$self->{rvsn},	    # inherit
			$oid,		    # argument
			0);		    # empty
}

sub spawnObject {
    my $self = shift;
    my $o = shift;
    return $self->spawnOid($o->id);
}

sub spawnSubmit {
    my $self = shift;

    return MineKey->new(1,		    # post
			$self->{depth} - 1, # decrement
			$self->{rid},	    # inherit
			$self->{rvsn},	    # inherit
			$self->{oid},	    # inherit
			0);		    # empty
}

##################################################################

1;
