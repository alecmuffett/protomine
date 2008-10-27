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

UI=database/ui
DOC=database/doc
CGI=/Users/alecm/Sites/cgi-bin

BACKUPHOST=inet-luther

LIBFILES=mine/MineUI.pl mine/Object.pl mine/Relation.pl \
	mine/Tag.pl mine/Thing.pl mine/pm-time.pl \
	mine/pm-api.pl mine/pm-ui.pl


##################################################################

all: $(UI)/index.html perms $(CGI)/protomine.cgi
	for i in LICENSE NOTICE TECHNOTES TODO ; do cp $$i database/doc/$$i.txt ; done

$(UI)/index.html: bin/generate-homepage.pl
	$? > $@

perms:
	find . | closeperm > /dev/null 2>&1
	find . | openperm > /dev/null
	( cd database ; chmod 01777 objects tags relations logs )

$(CGI)/protomine.cgi: protomine.cgi
	perl -wc $?
	cp $? $@
	chmod 755 $@

protomine.cgi: $(LIBFILES)
	for i in $? ; do perl -wc $$i || exit 1 ; done
	touch $@

##################################################################

clean: perms
	sync # macos
	-rm `find . -name '*~'`
	-rm MANIFEST

# not doing: rm -f database/logs/* - because i like logs
clobber: clean
	rm -f database/objects/*
	rm -f database/relations/*
	rm -f database/tags/*

setup: all clobber
	./bin/sample-data-setup.sh

backup: clobber
	rsync -av --delete /Users/alecm/protomine/ $(BACKUPHOST):protomine/

MANIFEST:
	find . ! -type l | \
		egrep -v 'database/(logs|objects|relations|tags)/.' | \
		egrep -vi 'slideware/' | \
		egrep -vi '\.(jpg|png)$$' | \
		sort > $@

tarball: clean MANIFEST
	cpio -ovH ustar < MANIFEST | gzip -9 > ../protomine-`date "+%Y%m%d.%H%M%S"`.tar.gz
