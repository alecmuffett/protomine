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

##################################################################

# atomFormat: converts a Unix timestamp into Atom format based on
# Zulu/GMT timezone

sub atom_format {
    my $t = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($t);

    return
	sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ",
	$year + 1900, $mon+1, $mday, $hour, $min, $sec;
}

##################################################################

sub get_permalink {
    my $r = shift;
    my $o = shift;

    my $rid = 0;
    my $rvsn = 0;
    my $oid = 0;

    if (defined($r)) {
	$rid = $r->id;
	$rvsn = $r->get('relationVersion');

	if (defined($o)) {
	    $oid = $o->id;
	}
    }

    my $key = &encode_key($rid, $rvsn, $oid);

    return $main::MINE_HTTP_FULLPATH . "/get?key=$key";
}

##################################################################

sub decode_key {
    my ($encoded) = @_;
    my $magic_number = "mine";	# break out into global setting
    my $packfmt = "H*";		# break out?

    warn "decode_key: encoded=$encoded\n";

    my $key = pack($packfmt, $encoded);
    warn "decode_key: key=$key\n";

    my ($magic, $rid, $rvsn, $oid, $crc);
    unless (($magic, $rid, $rvsn, $oid, $crc) =
	    ($key =~ m!^(\w+),(\d+),(\d+),(\d+),(\d+)$!o)) {
	die "decode_key: bad decode result\n";
    }

    die "decode_key: bad magic $magic vs \n" unless ($magic eq $magic_number);
    die "decode_key: bad rid $rid\n" unless ($rid > 0);
    die "decode_key: bad rvsn $rvsn\n" unless ($rvsn > 0);
    die "decode_key: bad oid $oid\n" unless ($oid >= 0); # probably redundant

    my $prefix2 = "$magic,$rid,$rvsn,$oid";
    warn "decode_key: prefix2=$prefix2\n";

    my $crc2 = unpack("%C*", $prefix2);
    warn "decode_key: crc2=$crc2\n";

    die "decode_key: bad crc check\n" unless ($crc2 eq $crc);
    warn "decode_key: decoded $rid $rvsn $oid\n";

    return ($rid, $rvsn, $oid);
}

##################################################################

sub encode_key {
    my ($rid, $rvsn, $oid) = @_;
    my $magic_number = "mine";	# break out into global setting
    my $packfmt = "H*";		# break out?

    my $magic = $magic_number;

    die "encode_key: bad magic $magic\n" unless ($magic ne '');
    die "encode_key: bad rid $rid\n" unless ($rid > 0);
    die "encode_key: bad rvsn $rvsn\n" unless ($rvsn > 0);
    die "encode_key: bad oid $oid\n" unless ($oid >= 0); # probably redundant

    my $prefix = "$magic,$rid,$rvsn,$oid";
    warn "encode_key: prefix=$prefix\n";

    my $crc = unpack("%C*", $prefix);
    warn "encode_key: crc=$crc\n";

    my $key = "$prefix,$crc";
    warn "encode_key: key=$key\n";

    my $encoded = unpack($packfmt, $key);
    warn "encode_key: encoded=$encoded\n";

    return $encoded;
}

##################################################################

1;
