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

our $MINE_HTTP_FULLPATH;

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

sub yyyy_format {
    my $t = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($t);

    return 
        sprintf "%04d%02d%02d%02%d%02d%02d",
        $year + 1900, $mon+1, $mday, $hour, $min, $sec;
}

##################################################################

sub get_permalink {
    my ($method, $r, $o) = @_;

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

    my $key = Crypto->encodeMineKey($method, $rid, $rvsn, $oid);

    return $MINE_HTTP_FULLPATH . "/get?key=$key";
}

##################################################################

1;
