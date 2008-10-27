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

my $mimefile = "database/config/mime.types";

die "Usage: $0 filename.ext\n" unless $#ARGV == 0;

my $filesuffix = $ARGV[0];
$filesuffix =~ s!^.*\.!!o;	# greedy match to destroy as much as possible
$filesuffix =~ tr/A-Z/a-z/;

open(MIME, $mimefile) || die "open: $mimefile: $!\n";
while (<MIME>) {
    next if m!^\s*(\#.*)?$!o;
    my ($type, @suffixes) = split;
    foreach my $suffix (@suffixes) {
	if ($suffix eq $filesuffix) {
	    print "$type\n";
	    exit 0;
	}
    }
}
close(MIME);

print "application/octet-stream\n"; # default
exit 0;
