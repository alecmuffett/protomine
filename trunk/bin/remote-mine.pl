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

$root = 'http://localhost/~alecm/mine';

require "mine/pm-mime.pl";

my $debug = 1;
push(@curlopts, '--fail') if (1); # curl dies silently on failure
push(@curlopts, '--digest') if (0);  # curl http digest authentication
push(@curlopts, '--user', 'alecm:sesame') if (0); # user and pw for authentication
push(@curlopts, '--verbose') if (0); # curl acts verbosely

sub Mine {
    my ($method, $api, @args) = @_;
    my $query;
    my @curlargs;

    if ($method eq 'create') {
	$query = "";
    }
    elsif ($method eq 'read') {
	$query = "";
    }
    elsif ($method eq 'update') {
	$query = "?_method=UPDATE";
    }
    elsif ($method eq 'delete') {
	$query = "?_method=DELETE";
    }
    else {
	die "$0: unrecognised method $method\n";
    }

    foreach $arg (@args) {
	push(@curlargs, '-F', $arg);
    }

    @cmd = ("curl", @curlopts, "$root$api$query", @curlargs);

    warn "> exec: @cmd\n" if ($debug);
    system(@cmd);
}

##################################################################

my $minecmd = shift;
my @cmdlist = ();
my $we_did_something = 0;

while (<DATA>) {
    next if (/^\s*(\#.*)?$/o);  # skip comment lines and blanks
    s/\#.*$//go;		# strip comments
    s/\s+/ /go;			# strip multi-whitespace
    s/\s$//o;;			# strip trailing whitespace

    # split on spaces
    my ($cmd, $call_how, $method, $api, $doc) = split(" ", $_, 5);

    # for use in the help string, below; self-documenting code my arse
    push(@cmdlist, "\t$cmd $doc\n");

    # if this is not it, then skip to next
    next unless ($minecmd eq $cmd);

    # remember we tried to do something
    $we_did_something = 1;

    # PASSARGS: apply all foo=bar parameters to single API call

    if ($call_how eq 'PASSARGS') {
	&Mine($method, $api, @ARGV);
    }

    # ITERARGS: apply each foo=bar parameter to individual API calls

    elsif ($call_how eq 'ITERARGS') {
	foreach $arg (@ARGV) {
	    &Mine($method, $api, $arg);
	}
    }

    # SUB1PASS: strip the first arg and interpolate into API URL; pass
    # all subsequent foo=bar parameters to it ; ALSO IS PROBABLY
    # SAFEST CASE FOR SINGLE-ARGUMENT COMMANDLINES.

    elsif ($call_how eq 'SUB1PASS') {
	my $arg = shift;
	$api =~ s![ROT]ID!$arg!g;
	&Mine($method, $api, @ARGV);
    }

    # SUB1ITER: strip the first arg and interpolate into API URL;
    # apply each subsequent foo=bar parameter to it individually

    elsif ($call_how eq 'SUB1ITER') {
	my $arg = shift;
	$api =~ s![ROT]ID!$arg!g;
	foreach $arg (@ARGV) {
	    &Mine($method, $api, $arg);
	}
    }

    # SUBEVERY: strip each arg and interpolate it into an API URL, and
    # call that without parameters

    elsif ($call_how eq 'SUBEVERY') {
	foreach $arg (@ARGV) {
	    my $api2 = $api;
	    $api2 =~ s![RIT]ID!$arg!g;
	    &Mine($method, $api2);
	}
    }

    # UPLOAD: magic special case for uploading files
    elsif ($call_how eq 'UPLOAD') {

	foreach my $filename (@ARGV) {
	    my $filetype = &mime_type($filename);

	    &Mine($method,
		  $api,
		  "data=\@$filename",
		  "objectName=$filename",
		  "objectType=$filetype",
		  "objectStatus=draft",
		  "objectDescription=bulk-uploaded, sourced from $filename");
	}
		  
    }


    # THIS CAN'T HAPPEN

    else {
	die "LOL WHUT?\n";
    }
}

# did the user goof?

unless ($we_did_something) {
    warn "usage:\t$0 [command] [args ... ]\n";
    warn "commands:\n";
    warn join ('',  @cmdlist);
    exit 1;
}

# done

exit 0;

##################################################################
__END__;

#read-share       PASSARGS  read    /api/share/raw/RID/RVSN/OID.xml
#read-share       PASSARGS  read    /api/share/redirect/RID.xml
#read-share       PASSARGS  read    /api/share/redirect/RID/OID.xml
#read-share       PASSARGS  read    /api/share/url/RID.xml
#read-share       PASSARGS  read    /api/share/url/RID/OID.xml
#select-objects    PASSARGS  read    /api/select/object.xml
#select-relations  PASSARGS  read    /api/select/relation.xml
#select-tags       PASSARGS  read    /api/select/tag.xml
upload           UPLOAD    create  /api/object.xml            filename    ...
clone-object     SUB1PASS  create  /api/object/OID/clone.xml  42
create-object    PASSARGS  create  /api/object.xml            data=@file  a=b         c=d  ...
create-relation  PASSARGS  create  /api/relation.xml          a=b         c=d         ...
create-tag       PASSARGS  create  /api/tag.xml               a=b         c=d         ...
delete-object    SUBEVERY  delete  /api/object/OID.xml        1           2           3    ...
delete-relation  SUBEVERY  delete  /api/relation/RID.xml      1           2           3    ...
delete-tag       SUBEVERY  delete  /api/tag/TID.xml           1           2           3    ...
list-clones      SUB1PASS  read    /api/object/OID/clone.xml  42
list-objects     PASSARGS  read    /api/object.xml
list-relations   PASSARGS  read    /api/relation.xml
list-tags        PASSARGS  read    /api/tag.xml
read-config      PASSARGS  read    /api/config.xml
read-data        SUB1PASS  read    /api/object/OID            42
read-object      SUB1PASS  read    /api/object/OID.xml        42
read-relation    SUB1PASS  read    /api/relation/RID.xml      42
read-tag         SUB1PASS  read    /api/tag/TID.xml           42
test             PASSARGS  read    /test/                     a=b         c=d         ...
update-config    PASSARGS  update  /api/config.xml            a=b         c=d         ...
update-data      SUB1PASS  update  /api/object/OID            42          data=@file  a=b  c=d  ...
update-object    SUB1PASS  update  /api/object/OID.xml        42          a=b         c=d  ...
update-relation  SUB1PASS  update  /api/relation/RID.xml      42          a=b         c=d  ...
update-tag       SUB1PASS  update  /api/tag/TID.xml           42          a=b         c=d  ...
version          PASSARGS  read    /api/version.xml
