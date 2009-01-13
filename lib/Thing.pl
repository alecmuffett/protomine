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

package Thing;

my $BUFSIZ = 1024 * 64;         # buffer size for file copying

use strict;
use warnings;
#use diagnostics;

use Fcntl qw(:DEFAULT :flock);

##################################################################
# CONSTRUCTOR
##################################################################

## new -- returns new blank thing

sub new {
    my $class = shift;          # what am i
    my $id = shift;             # who am i?

    if (ref($class)) {          # oops, we're running as an instance method
	$class = ref($class);   # work out what we _really_ are
    }

    my $self = {};              # where i go

    $self->{CLASS} = $class;    # what i am
    $self->{DATA} = {};         # where my data goes
    
    bless $self, $class;        # valid from this point onwards

    $self->boot;                # set up the optional stuff

    if (defined($id)) {
	$self->load($id)        # if we got given an id, load it
    }

    return $self;
}

##################################################################
# CLASS METHODS
##################################################################

## boot -- initialises a blank thing with the key settings; meant to be overridden in subclasses

sub boot {
    my $self = shift;

    # purposely not a valid directory in this example
    $self->{DIRECTORY} = '/dev/null'; # directory where things are stored
    $self->{ENFORCE_UNIQUE_NAMES} = undef; # thing names must be unique
    $self->{NAME_KEY} = undef;  # key for name of thing in %DATA
    $self->{ID_KEY} = undef;    # passive key for id of thing in %DATA
    $self->{VALID_KEYS} = {};    # keys which may be present, ever
    $self->{WRITABLE_KEYS} = {}; # keys which may be present to write
    $self->{REQUIRED_KEYS} = {}; # keys which must be present to write

    die "Thing::boot called, this can't happen";

    return $self;
}

##################################################################
##################################################################
##################################################################
# CLASS-INSTANCE HYBRID METHODS
##################################################################
##################################################################
##################################################################

## list -- returns list of integers, id's of valid things

sub list {
    my $self = shift;

    # patch-up $self if we are a class invocation
    unless (ref($self)) {
	$self = $self->new;
    }

    my $dir = $self->directory;

    opendir(DIR, $dir) or die "list: opendir: $dir: $!\n";
    my @numberlist = sort {$b <=> $a} grep(/^\d+$/o, readdir(DIR));
    closedir(DIR);

    return @numberlist;
}

## existsId -- returns boolean, whether the desired id exists

sub existsId {
    my $self = shift;

    # patch-up $self if we are a class invocation
    unless (ref($self)) {
	$self = $self->new;
    }

    my $id = shift;
    my $file = $self->filepath($id);

    return (-f $file);
}

## selectByName (string) -- returns list of integers

sub selectByName {
    my $self = shift;

    # patch-up $self if we are a class invocation
    unless (ref($self)) {
	$self = $self->new;
    }

    my $name = shift;
    my @hits;

    foreach my $id ($self->list) {
	my $thing = $self->new($id);

	if ($thing->name eq $name) {
	    push(@hits, $id);
	    last if $self->enforce_unique_names; # fast return if names guaranteed unique
	}
    }

    return @hits;
}

## existsName (name) -- return $id||-1 if name exists

sub existsName {
    my $self = shift;

    # patch-up $self if we are a class invocation
    unless (ref($self)) {
	$self = $self->new;
    }

    my $name = shift;
    my @namelist = $self->selectByName($name); # name list

    if ($#namelist > 0) {	# 1+ entries
	if ($self->enforce_unique_names) {
	    die "corrupted database, non-unique name $name\n";
	}
	return -1;
    }
    elsif ($#namelist == 0) { # 1 entry
	if ($self->enforce_unique_names) {
	    return $namelist[0];
	}
	return -1;
    }

    return 0;                   # no entries
}

##################################################################
##################################################################
##################################################################
# INSTANCE METHODS
##################################################################
##################################################################
##################################################################

## enforce_unique_names -- returns boolean whether Thing must have a Name unique in Thing-space

sub enforce_unique_names {
    my $self = shift ;
    return $self->{ENFORCE_UNIQUE_NAMES};
}

## directory -- returns readonly scalar, the thing's directory

sub directory {
    my $self = shift ;
    return $self->{DIRECTORY};
}

## filepath(file) -- returns scalar, the thing directory suffixed by a filename

sub filepath {
    my $self = shift;
    my $file = shift;
    return $self->directory . "/" . $file;
}

## keysRequired -- returns list, list of keys required to be output

sub keysRequired {
    my $self = shift ;
    my @klist = keys %{$self->{REQUIRED_KEYS}};
    return @klist;
}

## keysValid -- returns list, list of keys that are valid

sub keysValid {
    my $self = shift ;
    my @klist = keys %{$self->{VALID_KEYS}};
    return @klist;
}

## validKey (key) -- returns scalar, whether argument is a valid key;
## if scalar is a reference it is a hashref keyed by valid VALUES for
## the key (ie: an implementation of 'enum')

sub validKey {
    my $self = shift ;
    my $key = shift;
    return $self->{VALID_KEYS}->{$key};
}

## keysWritable -- returns list, list of keys writable to output

sub keysWritable {
    my $self = shift ;
    my @klist = keys %{$self->{WRITABLE_KEYS}};
    return @klist;
}

## writableKey (key) -- returns scalar, whether argument is a writable
## key

sub writableKey {
    my $self = shift ;
    my $key = shift;
    return $self->{WRITABLE_KEYS}->{$key};
}

##################################################################
##################################################################
##################################################################
# ACCESSOR METHODS
##################################################################
##################################################################
##################################################################

## listDataKeys -- returns list, sorted list of data keys

sub listDataKeys {
    my $self = shift ;
    my @klist = sort keys %{$self->{DATA}};
    return @klist;
}

## get (key) -- returns scalar

sub get {
    my $self = shift;
    my $key = shift;

    unless ($self->validKey($key)) {
	die "get($key) however key $key is not valid for this thing\n";
    }

    return $self->{DATA}->{$key};
}

## set (key, value) -- returns value

sub set {
    my $self = shift;
    my ($key, $value) = @_;
    my $val_enum;

    if ($val_enum = $self->validKey($key)) {
	if (ref($val_enum) eq 'ARRAY') {
	    unless (grep { $value eq $_ } @{$val_enum}) {
		die "set($key, $value) however value is not amongst '@{$val_enum}'\n";
	    }
	}

	$value =~ s!\s+! !go;	# kill newlines/extra whitespace
	$value =~ s!^\s!!o;	# kill leading whitespace
	$value =~ s! $!!o;	# kill trailing whitespace

	# this is how we delete params, set them to empty string
	if ($value eq '') {
	    delete($self->{DATA}->{$key});
	}
	else {
	    $self->{DATA}->{$key} = $value;
	}

	return $value;
    }

    die "set($key, $value) however that key is not setable\n";
}

## setFrom (hashref) -- populates thing from a hashref, applying writable validity rules

sub setFrom {
    my $self = shift;
    my $hr = shift;

    foreach my $key (keys %{$hr}) {
	if ($self->writableKey($key)) {
	    $self->set($key, $hr->{$key});
	}
	else {
	    warn "setFrom not copying '$key' which is not writable\n";
	}
    }

    return $hr;
}

##################################################################

## id -- returns readonly integer/id

sub id {
    my $self = shift;
    return $self->get($self->{ID_KEY});
}

## name -- returns string

sub name {
    my $self = shift;
    return $self->get($self->{NAME_KEY});
}

##################################################################
##################################################################
##################################################################
# CRUD
##################################################################
##################################################################
##################################################################

## load (number) -- loads an existing thing into thing

sub load {
    my $self = shift;

    my $id = shift;
    my $old_id = $self->id;

    if (defined($old_id)) {
	die "load: trying to re-read thing $id atop thing $old_id\n";
    }

    my $file = $self->filepath($id);

    open(INPUT, $file) or die "load: open: $file: $!\n";

    while (<INPUT>) {
	# reject blank lines or ones leading with '#' character
	next if /^\s*(\#.*)?$/o;

	# trim newline
	chomp;

	# parse or die
	# we are using .+ for $3 to ensure non-emptiness
	unless (/(\w+)(\s*=\s*|:\s*|\s+)(.+)/o) {
	    die "load: bad record in '$file' line $.: $_\n";
	}

	# SET THE VALUE; CANNOT USE $self->set($1, $3) TO DO THIS ELSE
	# WE GET INTO HORRIBLE RECURSION WHEN WE START PARSING-OUT TAG
	# GROUPS; INSTEAD WE MUST ASSUME THAT WHAT IS IN THE FILE IS
	# CORRECT, AND JUST GO WITH IT...
	$self->{DATA}->{$1} = $3;
    }

    close(INPUT) or die "load: close: $file: $!\n";

    $self->set($self->{ID_KEY}, $id); # THIS IS CURRENTLY SAFE
}

## save -- saves an otherwise unsaved thing to disk, returns a new id
## SEE THE NOTE ON toSavedForm

sub save {
    my $self = shift;

    my $id = $self->id;
    my $name = $self->name;

    if (defined($id)) {
	die "save: trying to re-save thing $id\n" . $self->toString . "\n";
    }

    if ($self->enforce_unique_names) {
	if ($self->existsName($name)) {
	    die "save: trying to save a second thing with name $name\n" . $self->toString . "\n";
	}
    }

    $self->lock;
    $id = $self->bump;
    $self->fileWrite($id, $self->toSavedForm);
    $self->unlock;

    $self->set($self->{ID_KEY}, $id);

    return $id;
}

## clone -- returns integer/id
## SEE THE NOTE ON toSavedForm

sub clone {
    my $self = shift;
    my $other = $self->new;
    $other->setFrom($self->{DATA});
    return $other->save;
}

## update -- returns boolean
## SEE THE NOTE ON toSavedForm

sub update {
    my $self = shift;

    my $id = $self->id;

    unless (defined($id)) {
	die "update: trying to update something without id:\n" . $self->toString . "\n";
    }

    $self->lock;
    $self->fileWrite($id, $self->toSavedForm);
    $self->unlock;

    return $id;
}

## delete -- returns boolean

sub delete {
    my $self = shift;

    my $id = $self->id;

    unless (defined($id)) {
	die "delete: trying to delete something without id:\n" . $self->toString . "\n";
    }

    $self->fileDelete($id);

    return 1;
}

##################################################################

## toDataStructure -- returns hashref

sub toDataStructure {
    my $self = shift;
    my %ds;

    foreach my $key ($self->listDataKeys) {
	my $value = $self->get($key);
	$ds{$key} = $value;
    }

    return \%ds;
}

##################################################################

## toHTML -- returns listref

sub toHTML {
    my $self = shift;
    my @page;

    push(@page, "<UL>\n");
    foreach my $key ($self->listDataKeys) {
	my $value = $self->get($key);
	$value =~ s!\n+! !go; # purge newlines
	push(@page, "<LI><EM>$key:</EM> $value</LI>\n");
    }
    push(@page, "</UL>\n");

    return \@page;
}

##################################################################

## toString -- returns string
# is like toSavedForm with the safety checks turned off

sub toString {
    my $self = shift;
    my @page;

    foreach my $key ($self->listDataKeys) {
	my $value = $self->{DATA}->{$key};

	unless ($self->writableKey($key)) {
	    push(@page, "# $key: $value # is unwritable\n");
	    next;
	}

	# skip if blank
	push(@page, "$key: $value\n");
    }

    return join('', @page);
}

##################################################################

## toSavedForm -- returns string; more sanity checking than toString

## NOTE: WE CANNOT USE THE RESULT OF get() FOR toSavedForm SINCE THAT
## WILL DO BIDIRECTIONAL TAG TRANSLATION THEREBY DEFEATING THE WHOLE
## POINT; THIS WOULD BE THE CONVERSE OF THE RECURSION PROBLEM INHERENT
## WITH get() IN THE load() ROUTINE

sub toSavedForm {
    my $self = shift;
    my @page;

    # safety check: have we got all the required keys?
    foreach my $key ($self->keysRequired) {
	unless (defined($self->{DATA}->{$key})) {
	    die "toSavedForm: require undefined key $key\n";
	}

	unless ($self->{DATA}->{$key} !~ m!^\s*$!o) {
	    die "toSavedForm: require non-empty key $key\n";
	}
    }

    # print them all...
    foreach my $key ($self->listDataKeys) {
	# this one is
	my $value = $self->{DATA}->{$key};

	# ...so long as they are writable
	unless ($self->writableKey($key)) {
	    push(@page, "# $key: $value # is unwritable\n");
	    next;
	}

	# sanitise in the same way as set()
	$value =~ s!\s+! !go;	# kill newlines/extra whitespace
	$value =~ s!^\s!!o;	# kill leading whitespace
	$value =~ s! $!!o;	# kill trailing whitespace

	# skip if blank
	push(@page, "$key: $value\n") unless ($value eq '');
    }

    return join('', @page);
}

##################################################################

sub lock {
    my $self = shift;
    my $file = $self->filepath("lockinfo.txt");
    open(BIG_LOCK, ">$file") or die "lock: open: $file: $!\n";
    flock(BIG_LOCK, LOCK_EX) or die "lock: flock LOCAL_EX: $file: $!\n";
    select((select(BIG_LOCK), $| = 1)[0]); # make unbuffered
    print BIG_LOCK $$, " ", time, "\n";    # pid and time
}

##################################################################

sub unlock {
    my $self = shift;
    my $file = $self->filepath("lockinfo.txt");
    flock(BIG_LOCK, LOCK_UN) or die "unlock: flock LOCAL_UN: $file: $!\n";
    close(BIG_LOCK) or die "unlock: close: $file: $!\n";
}

##################################################################

sub fileRename {
    my $self = shift;
    my ($old, $new) = @_;
    rename($old, $new) or die "rename: from '$old' to '$new': $!\n";
}

##################################################################

sub fileDelete {
    my $self = shift;
    my $file = shift;

    $file = $self->filepath($file);

    $self->fileRename($file, "$file~deleted");
}

##################################################################

sub fileWrite {
    my $self = shift;
    my $file = shift;
    my $data = shift;

    $file = $self->filepath($file);

    if (open(FILE, $file)) {
	my $buffer;
	my $oldfile = "$file~old";

	open(COPY, ">$oldfile") or die "fileWrite: open: $oldfile: $!\n";

	while (read(FILE, $buffer, $BUFSIZ) > 0) {
	    print COPY $buffer;
	}

	close(COPY) or die "fileWrite: close: $oldfile: $!\n";
	close(FILE) or die "fileWrite: close: $file: $!\n";
    }

    # re/write the new file
    open(FILE, ">$file~new") or die "fileWrite: open: >$file~new: $!\n";
    my $fh = select(FILE);
    print $data;
    select($fh);
    close(FILE) or die "fileWrite: close: $file: $!\n";

    # install the file
    $self->fileRename("$file~new", $file);
}

##################################################################

sub max {
    my $self = shift;

    my $lastused = 0;
    my $calculated = 0;

    my $file = $self->filepath("lastused.txt");

    if (open(LASTUSED, $file)) {
	$lastused = <LASTUSED>;
	chomp($lastused);
	close(LASTUSED);
	return $lastused;
    }

    my @thinglist = $self->list;

    if (defined($thinglist[0])) {
	$calculated = $thinglist[0];
    }

    # we could cache $calculated here but frankly that's a bit
    # pointless, since any occasion where lastused.txt does not exist
    # is likely to be in an empty directory where the process of
    # computation is quite cheap; and in any case the directory is not
    # likely to remain empty for long because bump() will populate it
    # soon enough.

    return $calculated;
}

##################################################################

sub bump {
    my $self = shift;

    my $retval = $self->max + 1; # increment number here
    my $file = $self->filepath("lastused.txt");

    open(LASTUSED, ">$file~new") or die "bump: open: >$file~new: $!\n";
    print LASTUSED $retval, "\n";
    close(LASTUSED);

    $self->fileRename("$file~new", $file);
#   warn "bump called, returning $retval\n";

    return $retval;
}

##################################################################

sub lastModified {
    my $self = shift;
    my $id = $self->id;
    my $file = $self->filepath($id);
    my $date = (stat($file))[9];
    die "lastModified: stat: $file: $!\n" unless (defined($date));
    return $date;
}

##################################################################

sub lastAccessed {
    my $self = shift;
    my $id = $self->id;
    my $file = $self->filepath($id);
    my $date = (stat($file))[8];
    die "lastAccessed: stat: $file: $!\n" unless (defined($date));
    return $date;
}

##################################################################

1;
