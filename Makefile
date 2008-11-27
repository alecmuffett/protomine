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
# METATARGETS

###
# top dependency: is there a protomine-config file
###

all: permissions protomine-config.pl syntaxcheck webpages test
	echo done.

###
# does the thing work
###

test:
	minectl version

###
# install webpages into mine document database
###

webpages: $(UI)/index.html
	for i in LICENSE NOTICE TECHNOTES TODO ; do cp $$i $(DOC)/$$i.txt ; done

###
# syntaxcheck the CGI script
###

syntaxcheck:
	for i in lib/*.pl protomine.cgi minectl ; do perl -wc $$i || exit 1 ; done

###
# blow away the environment
###

clobber: clean
	rm -f database/objects/*
	rm -f database/relations/*
	rm -f database/tags/* # leave logs alone
	rm -f protomine-config.pl

###
# delete scratch files
###

clean: permissions
	-rm `find . -name '*~'` 
	-rm *.tmp

###
# coersce the permissions to plausible values for development
###

permissions:
	chmod 0755 `find . -type d -print`
	chmod 0644 `find . -type f -print`
	chmod 0755 *.pl *.sh minectl protomine.cgi
	( cd database ; chmod 01777 objects tags relations logs )


###
# quickie
###

config: protomine-config.pl

errs:
	tail -128 /var/log/apache2/error_log

##################################################################
# PHYSICAL TARGETS

###
# make the protomine-config file
###

protomine-config.pl: generate-config.sh
	generate-config.sh > protomine-config.pl
	chmod 755 protomine-config.pl

###
# generate the mine document database homepage
###

$(UI)/index.html: generate-homepage.pl
	$? > $@

