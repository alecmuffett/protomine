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

sub mime_type {
    my $filesuffix = shift;
    $filesuffix =~ s!^.*\.!!o; # greedy match to destroy as much as possible
    $filesuffix =~ tr/A-Z/a-z/; # force lowercase

    # start by fast-tracking certain extensions
    # approximate order of likliehood
    return "text/html" if ($filesuffix eq 'html');
    return "image/jpeg" if ($filesuffix eq 'jpg');
    return "image/png" if ($filesuffix eq 'png');
    return "text/css" if ($filesuffix eq 'css');
    return "text/plain" if ($filesuffix eq 'txt');
    return "image/gif" if ($filesuffix eq 'gif');
    return "image/jpeg" if ($filesuffix eq 'jpeg');
    return "text/html" if ($filesuffix eq 'htm');

    # insert a mime.types lookup here
    my $mimefile = "database/config/mime.types";

    open(MIME, $mimefile) || die "open: $mimefile: $!\n";
    while (<MIME>) {
	next if m!^\s*(\#.*)?$!o;
	my ($type, @suffixes) = split;
	foreach my $suffix (@suffixes) {
	    if ($suffix eq $filesuffix) {
		return $type;
	    }
	}
    }
    close(MIME);

    # fall through
    return "application/octet-stream";
}

1;
