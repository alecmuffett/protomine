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
push(@curlopts, '--fail') if (1);
push(@curlopts, '--verbose') if (0);
push(@curlopts, '--digest') if (0);
push(@curlopts, '--user', 'alecm:sesame') if (0);

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
	$arg =~ s!,! !go;	# hack, remap comma to space, remove on GA
        push(@curlargs, '-F', $arg);
    }

    @cmd = ("curl", @curlopts, "$root$api$query", @curlargs); 

    # warn "@cmd\n";
    system(@cmd);
}

##################################################################

my $minecmd = shift;
my @help = ();
my $hit = 0;


while (<DATA>) {
    next if (/^\s*(\#.*)?$/o);	# skip comment lines and blanks

    s/\#.*$//o;			# strip comments

    my ($cmd, $call_how, $method, $api) = split(" ");

    push(@help, $cmd);

    next unless ($minecmd eq $cmd);

    $hit = 1;

    if ($call_how eq 'ARGS') {
	&Mine($method, $api, @ARGV);
    }
    elsif ($call_how eq 'ITERATE') {
	foreach $arg (@ARGS) {
	    &Mine($method, $api, $arg);
	}
    }
    elsif ($call_how eq 'SUB1') {
	my $arg = shift;
	$api =~ s![ROT]ID!$arg!go;
	&Mine($method, $api, @ARGV);
    }
    elsif ($call_how eq 'SUB*') {
	foreach $arg (@ARGS) {
	    my $api2 = $api;
	    $api2 =~ s![RIT]ID!$arg!go;
	    &Mine($method, $api2);
	}
    }
    else {
	die "how?";
    }
}

unless ($hit) {
    warn "usage:    $0 [command] [args ... ]\n";
    warn "commands: @help\n";
    exit 1;
}

exit 0;

##################################################################
__END__;
#read-share       ARGS  read    /api/share/raw/RID/RVSN/OID.xml
#read-share       ARGS  read    /api/share/redirect/RID.xml
#read-share       ARGS  read    /api/share/redirect/RID/OID.xml
#read-share       ARGS  read    /api/share/url/RID.xml
#read-share       ARGS  read    /api/share/url/RID/OID.xml
clone-object      SUB1  create  /api/object/OID/clone.xml
create-object     ARGS  create  /api/object.xml
create-relation   ARGS  create  /api/relation.xml
create-tag        ARGS  create  /api/tag.xml
delete-object     SUB1  delete  /api/object/OID.xml
delete-relation   SUB1  delete  /api/relation/RID.xml
delete-tag        SUB1  delete  /api/tag/TID.xml
list-clones       SUB1  read    /api/object/OID/clone.xml
list-objects      ARGS  read    /api/object.xml
list-relations    ARGS  read    /api/relation.xml
list-tags         ARGS  read    /api/tag.xml
read-config       ARGS  read    /api/config.xml
read-object       SUB1  read    /api/object/OID.xml
read-data         SUB1  read    /api/object/OID
read-relation     SUB1  read    /api/relation/RID.xml
read-tag          SUB1  read    /api/tag/TID.xml
select-objects    ARGS  read    /api/select/object.xml
select-relations  ARGS  read    /api/select/relation.xml
select-tags       ARGS  read    /api/select/tag.xml
test              ARGS  read    /test/
update-config     ARGS  update  /api/config.xml
update-object     SUB1  update  /api/object/OID.xml
update-data       SUB1  update  /api/object/OID
update-relation   SUB1  update  /api/relation/RID.xml
update-tag        SUB1  update  /api/tag/TID.xml
version           ARGS  read    /api/version.xml
