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

# some of this is the sort of stuff I could get by loading POSIX, but
# really do I want that overhead when I can just use zulu?

##################################################################

# yyyyLogInfo: provide filename and tag for logging purposes

sub yyyyLogInfo {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time);
    my $file = sprintf "%04d%02d%02d", $year + 1900, $mon+1, $mday;
    my $tag = sprintf "%02d:%02d:%02d",$hour, $min, $sec;
    return ( $file, $tag );
}

##################################################################

# yyyyFormat: converts a Unix timestamp into YYYY format based on
# Zulu/GMT timezone

sub yyyyFormat {
    my $t = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($t);

    return 
	sprintf "%04d%02d%02d%02%d%02d%02d",
	$year + 1900, $mon+1, $mday, $hour, $min, $sec;
}

##################################################################

1;
