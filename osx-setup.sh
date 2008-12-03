#!/bin/sh

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

# makes bug reports easier in the long term
exec 2>&1
set -x

# let the user know

:
:
: SOME OF THIS SCRIPT REQUIRES AN ADMINISTRATOR PASSWORD TO EXECUTE
: PRESS RETURN TO CONTINUE, CONTROL-C IN ORDER TO QUIT
:
:
read foo

# strip bits off temp files
umask 077

# nice and visible for template substitution, below
__MY__USERNAME__=$USER

# check for apache install

if [ -d "/etc/apache2" ]
then
    APACHEDIR=/etc/apache2 # leopard/10.5
elif [ -d "/etc/httpd" ]
then
    APACHEDIR=/etc/httpd # panther/10.4
else
    :
    : cannot locate apache config directory, aborting.
    exit 1
fi

# Apache per-user config dir
ACFGFILE=$APACHEDIR/users/${__MY__USERNAME__}.conf

# for backups of files
DATESTAMP=`date "+%Y%m%d%H%M%S"`

# go to the home directory

cd

if ls -ld . | grep '^d........x'
then
    : home directory traverse permission is ok
else
    : your home directory is not world-executable, please adjust
    exit 1
fi

# check the HTTP directories

if ls -ld Sites | grep '^d......r.x'
then
    : Sites read/traverse permission is ok
else
    : your Sites directory is not world-read/executable, please adjust
    exit 1
fi

# set up cgi-bin

cd Sites || exit 1

test -d cgi-bin || mkdir cgi-bin || exit 1

chmod 755 cgi-bin || exit 1

# backup old .htaccess file

if [ -f .htaccess ]
then
    BKUP=.htaccess,$DATESTAMP
    cp .htaccess $BKUP || exit 1
    :
    :
    :
    :
    : there is already a .htaccess file in your Sites directory
    : it has been backed up to $BKUP
    :
    :
    :
    :
fi

# create the .htaccess file

cat > .htaccess <<EOF
# $DATESTAMP
# AccessFileName  .htaccess
RewriteEngine   On
RewriteBase     /~${__MY__USERNAME__}
RewriteRule     ^mine(.*)              cgi-bin/protomine.cgi$1
EOF

chmod 644 .htaccess

: installing symlinks

cd cgi-bin || exit 1

rm protomine.cgi protomine-config.pl

ln -s ../../protomine/protomine.cgi || exit 1
ln -s ../../protomine/protomine-config.pl || exit 1 # for the benefit of $0 in the cgi script, kludge


##################################################################

# go home

cd

# backup old apache config

:
:
:
:
: backing up old per-user apache config file.
: it will be backed up to $ACFGFILE,$DATESTAMP
: this requires administrator privilege.
:
:
:
:

sudo cp $ACFGFILE $ACFGFILE,$DATESTAMP || exit 1

# install privileged apache config

cat <<EOF | sudo dd of=$ACFGFILE
# $DATESTAMP
<Directory "/Users/${__MY__USERNAME__}/Sites/">
    Options Indexes FollowSymlinks MultiViews
    AllowOverride All
    Order allow,deny
    Allow from all
    # AuthName "${__MY__USERNAME__} mine"
    # AuthType Digest
    # AuthUserFile /Users/${__MY__USERNAME__}/.htpasswd
    # require valid-user
</Directory>
<Directory "/Users/${__MY__USERNAME__}/Sites/cgi-bin/">
    Options ExecCGI FollowSymLinks
    SetHandler cgi-script
</Directory>
EOF

sudo chmod 644 $ACFGFILE

: restarting apache

sudo apachectl graceful

# done

:
:
: osx protomine installation completed. 
: please ensure that you have enabled web-page sharing.
:
: now please do "make" and "populate-mine.sh"
:
:

exit 0
