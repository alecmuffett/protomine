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


#### THIS IS IN THE PROTOMINE WORKING DIRECTORY

UI=database/ui
DOC=database/doc

##################################################################

# top dependency: is there a config file

all: permissions bin/config.pl syntaxcheck webpages

# make the config file

bin/config.pl:
	bin/configure-setup.sh > bin/config.pl
	chmod 755 bin/config.pl

###
# top rule: installs webpages into mine document database
###

webpages: $(UI)/index.html
	for i in LICENSE NOTICE TECHNOTES TODO ; do cp $$i $(DOC)/$$i.txt ; done

###
# generate the mine document database homepage
###

$(UI)/index.html: bin/generate-homepage.pl
	$? > $@

###
# syntaxcheck the CGI script
###

syntaxcheck:
	for i in mine/*.pl bin/protomine.cgi ; do perl -wc $$i || exit 1 ; done

###
# basic setup
###

setup: clobber all
	./bin/sample-data-setup.sh

###
# blow away the environment
###

clobber: clean
	rm -f database/objects/*
	rm -f database/relations/*
	rm -f database/tags/* # leave logs alone
	rm -f bin/config.pl

###
# delete scratch files
###

clean: permissions
	-rm `find . -name '*~'`

###
# coersce the permissions to plausible values for development
###

permissions:
	chmod 0755 `find . -type d -print`
	chmod 0644 `find . -type f -print`
	chmod 0755 bin/*
	( cd database ; chmod 01777 objects tags relations logs )
