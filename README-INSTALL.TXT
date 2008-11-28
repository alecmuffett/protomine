------------------------------------------------------------------

Administrator priviliges for your account *will* be required; this
pokes the /etc/apache2/users/USERNAME.conf file to enable CGI to be
served from your ~/Sites directory.

Installation will be in "protomine" directory in your homedir.

Enable "Personal Web Sharing" before proceeding.


Commands:
---------

  cd

  svn checkout http://protomine.googlecode.com/svn/trunk/ protomine

  cd protomine

  ./osx-setup.sh

  make

  ./populate-mine.sh

  ./open-browser.pl

------------------------------------------------------------------
