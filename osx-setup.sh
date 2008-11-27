#!/bin/sh

# makes bug reports easier in the long term
exec 2>&1
set -x

# strip bits off temp files
umask 077

# nice and visible for template substitution, below
__MY__USERNAME__=$USER

# Apache per-user config dir
ACFGFILE=/etc/apache2/users/${__MY__USERNAME__}.conf

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

: installing symlink
cd cgi-bin || exit 1
rm protomine.cgi
ln -s ../../protomine/protomine.cgi || exit 1

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
</Directory>
<Directory "/Users/${__MY__USERNAME__}/Sites/cgi-bin/">
    Options ExecCGI FollowSymLinks
    SetHandler cgi-script
</Directory>
EOF

sudo chmod 644 $ACFGFILE

# done

:
:
:
:
: completed. please ensure that you have enabled web-page sharing.
:
:
:
:

exit 0
