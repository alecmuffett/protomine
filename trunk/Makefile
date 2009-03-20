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

# pagesize for printing
PAGESIZE=A4

# where stuff goes

DB=database
UI=$(DB)/ui
DOC=$(DB)/doc

# if this file exists, the makefile will (hopefully) avoid doing
# anything that will disturb the database/user, eg: blowing away all
# their objects, or adding to them unnecessarily...

PRODUCTION_LOCKFILE=.this_mine_is_being_used

##################################################################
# METATARGETS

###
# top dependency: is there a protomine-config file
###

setup: permissions protomine-config.pl syntax webpages test
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
	for i in LICENSE NOTICE ; do cp $$i $(DOC)/$$i.txt ; done

###
# syntax the CGI script
###

syntax:
	for i in lib/*.pl protomine.cgi minectl ; do perl -wc $$i || exit 1 ; done

###
# blow away the environment
###

clobber: clean
	test -f $(PRODUCTION_LOCKFILE) || rm -f $(DB)/objects/*
	test -f $(PRODUCTION_LOCKFILE) || rm -f $(DB)/relations/*
	test -f $(PRODUCTION_LOCKFILE) || rm -f $(DB)/tags/*
	test -f $(PRODUCTION_LOCKFILE) || rm -f protomine-config.pl
	rm -f minecode.ps

###
# delete scratch files
###

clean: permissions
	-rm `find . -name '*~'`
	-rm *.tmp

###
# production mode: less likely to blow away database accidentally
###

safe:
	touch $(PRODUCTION_LOCKFILE) 

unsafe:
	rm -f $(PRODUCTION_LOCKFILE) 

###
# coersce the permissions to plausible values for development; we are
# flexible about the files/644 since logfiles may be owned by the
# webserver and therefore may not be chmod-able
###

permissions:
	-chmod 0644 `find . -type f -print`
	chmod 0755 `find . -type d -print`
	chmod 0755 *.pl *.sh minectl protomine.cgi lib/* tools/*
	( cd $(DB) ; chmod 01777 objects tags relations logs )


###
# quickies
###

config: protomine-config.pl

# http://www.codento.com/people/mtr/genscript/ - GNU enscript
print:
	enscript --file-align=2 \
		--mark-wrapped-lines=arrow \
		--media=$(PAGESIZE) \
		--output=minecode.ps \
		--pretty-print=perl \
		protomine.cgi lib/* minectl generate-homepage.pl

lint:
	tools/perllint protomine.cgi lib/*.pl

reset:
	make clobber
	make
	test -f $(PRODUCTION_LOCKFILE) || ./populate-mine.sh

errs:
	tail -f /var/log/apache2/error_log

##################################################################
# PHYSICAL TARGETS

###
# make the protomine-config file
###

protomine-config.pl: generate-config.sh
	test -f $(PRODUCTION_LOCKFILE) || ./generate-config.sh > protomine-config.pl
	chmod 755 protomine-config.pl
	./generate-key.pl

###
# generate the mine document database homepage
###

$(UI)/index.html: generate-homepage.pl
	$? > $@
