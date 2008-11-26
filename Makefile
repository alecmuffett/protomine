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

#### THIS IS IN THE USERS PUBLIC HTML DIRECTORY

CGI=$$HOME/Sites/cgi-bin

#### THIS IS IN THE PROTOMINE WORKING DIRECTORY

UI=database/ui
DOC=database/doc

LIBFILES=mine/MineUI.pl mine/Object.pl mine/Relation.pl \
	mine/Tag.pl mine/Thing.pl mine/pm-time.pl \
	mine/pm-api.pl mine/pm-ui.pl


##################################################################

###
# top rule: installs notes into mine document database
###

all: $(UI)/index.html perms $(CGI)/protomine.cgi
	for i in LICENSE NOTICE TECHNOTES TODO ; do cp $$i database/doc/$$i.txt ; done

###
# mechanically generate the mine document database homepage
###

$(UI)/index.html: bin/generate-homepage.pl
	$? > $@

###
# check and install the CGI script
###

$(CGI)/protomine.cgi: protomine.cgi
	perl -wc $?
	cp $? $(CGI)/protomine.cgi
	chmod 755 $(CGI)/protomine.cgi

###
# check the mine library files for syntax errors
###

protomine.cgi: $(LIBFILES)
	for i in $? ; do perl -wc $$i || exit 1 ; done
	touch $@

###
# basic setup
###

setup: all clobber
	./bin/sample-data-setup.sh

### 
# blow away the environment 
###

clobber: clean
	rm -f database/objects/*
	rm -f database/relations/*
	rm -f database/tags/* # leave logs alone

###
# delete scratch files
###

clean: perms
	-rm `find . -name '*~'`

###
# coersce the permissions to plausible values for development
###

perms:
	chmod 0755 `find . -type d -print`
	chmod 0644 `find . -type f -print`
	chmod 0755 protomine.cgi
	chmod 0755 bin/*
	( cd database ; chmod 01777 objects tags relations logs )

