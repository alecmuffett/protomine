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

    my $field;

    # validate allows depth=0, you need to test that elsewhere

    $field = $self->{keyversion};
    die "validate($diag): bad keyversion $field\n"
	unless (($field =~ m!^\d+$!o) and ($field == 1));

    $field = $self->{method};
    die "validate($diag): bad method $field\n"
	unless (($field =~ m!^\d+$!o) and ($field >= 0) and ($field <= 1));

    $field = $self->{depth};
    die "validate($diag): bad depth $field\n"
	unless (($field =~ m!^\d+$!o) and ($field >= 0));

    $field = $self->{rid};
    die "validate($diag): bad rid $field\n"
	unless (($field =~ m!^\d+$!o) and ($field > 0));

    $field = $self->{rvsn};
    die "validate($diag): bad rvsn $field\n"
	unless (($field =~ m!^\d+$!o) and ($field > 0));

    $field = $self->{oid};
    die "validate($diag): bad oid $field\n"
	unless (($field =~ m!^\d+$!o) and ($field >= 0));

    $field = $self->{opt};
    die "validate($diag): bad opt $field\n"
	unless (($field =~ m!^\d+$!o) and ($field >= 0));
}

##################################################################

sub newFromEncoded {
    my ($class, $ciphertext) = @_;

    my $crypto = Crypto->new;

    # decrypt
    my $plaintext = $crypto->decrypt($ciphertext);

    # break out the checksum
    my ($csum, $minekey) = split(/,/, $plaintext, 2);

    # first check pre-parse
    my $computed = $crypto->checksum($minekey);
    die "newFromEncoded: security pre-parse checksum not numeric\n" if ($csum !~ m!^\d+$!o);
    die "newFromEncoded: security pre-parse checksum failed\n" if ($computed != $csum);

    # the parse
    my ($cookie, $keyversion, $method, $depth, $rid, $rvsn, $oid, $opt) = split(/,/, $minekey);

    # check that it's a mine key
    die "newFromEncoded: security bad cookie in $plaintext\n" unless ($cookie eq 'mine');

    # check that it is version 1
    die "newFromEncoded: security bad keyversion in $plaintext\n" unless ($keyversion == 1);

    # check the reconstruct (defeats trimming bugs)
    my $computed2 = $crypto->checksum("mine,$keyversion,$method,$depth,$rid,$rvsn,$oid,$opt");
    die "newFromEncoded: security post-parse checksum failed\n" if ($computed2 != $csum);

    # the instantition (will reflash keyversion to current)
    return $class->new($method, $depth, $rid, $rvsn, $oid, $opt);
}

##################################################################

sub newFromRelation {
    my ($class, $r) = @_;

    my $depth = 3;              # HARDCODED !!!

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

    my $crypto = Crypto->new;

    # compute the checksum
    my $csum = $crypto->checksum($body);

    # make the plaintext
    my $plaintext = "$csum,$body";

    ##################################################################
    # The next bit is quite subtle; normal crypto practice would
    # demand a random IV but the nature of the mine is that minekeys
    # equate to URLs, and thus should be invariant for any given
    # object in any given context.  

    # If you want secrecy, try SSL.

    # But what is an 'object'/'context' in this sense?  Well, it's the
    # tuple which allows someone to access an item, so it is
    # {depthremaining,rid,rvsn,oid} - essentially all of the plaintext
    # for crypto.  Because you don't want the IV for the crypto to be
    # a pure hash of the plaintext, the IV is generated from the salt
    # by appending 256 random bits, taking a SHA256 of the whole and
    # truncating it to the leftmost 128 bits.

    # In an ideal world you would book a random IV against every tuple
    # of {depthremaining,rid,rvsn,oid} and reuse that where need
    # demanded, but the amount of data storage would be immense, thus
    # this mechanism exists.

    # Remember, the point of a minekey is not to afford cryptosecrecy,
    # but instead it affords opacity - it should be hard to forge one,
    # and impractical to deconstruct one from the ciphertext alone.
    # That they are repeated twice as HREFs in a HTML document and
    # therefore refer to the same thing twice, is a given.  You could
    # probably work that sort of thing out from document context.
    # Exposing multiple ciphertexts for evidently the same plaintext,
    # would be *bad*.

    ##################################################################

    # encrypt and encode
    my $salt = sprintf "%s,%s,%s,%s", $self->{depth}, $self->{rid}, $self->{rvsn}, $self->{oid};
    my $ciphertext = $crypto->encrypt($salt, $plaintext);

    # return
    return $ciphertext;
}

##################################################################

sub readable {
    my $self = shift;

    # make the text
    return sprintf("request(%s) method=%s depth=%s relation=%s:%s(%s) oid=%s opt=%s",
		   $self->{keyversion},
		   ($self->{method} == 0) ? "get" : "post",
		   $self->{depth},
		   $self->{rid},
		   $self->{rvsn},
		   Relation->new($self->{rid})->name,
		   $self->{oid},
		   $self->{opt});
}

##################################################################

sub permalink {
    my $self = shift;

    my $encoded = $self->encode;

    return $main::MINE_HTTP_FULLPATH . "/get?key=$encoded";
}

##################################################################

sub spawnOid {
    my $self = shift;
    my $oid = shift;

    return MineKey->new(0,                  # get
			$self->{depth} - 1, # decrement
			$self->{rid},       # inherit
			$self->{rvsn},      # inherit
			$oid,               # argument
			0);                 # empty
}

##################################################################

sub spawnObject {
    my $self = shift;
    my $o = shift;
    return $self->spawnOid($o->id);
}

##################################################################

sub spawnSubmit {
    my $self = shift;

    return MineKey->new(1,                  # post
			$self->{depth} - 1, # decrement
			$self->{rid},       # inherit
			$self->{rvsn},      # inherit
			$self->{oid},       # inherit
			0);                 # empty
}

##################################################################

sub rewrite {
    my ($self, $line) = @_;
    1 while ($line =~ s!(SRC|HREF)\s*=\s*(['"]?(\d+)['"]?)!"$1='".$self->spawnOid($3)->permalink."'" !goie);

    return $line;
}

##################################################################

1;
