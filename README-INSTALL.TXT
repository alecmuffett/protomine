General installation: (ALL PLATFORMS)

Protomine requires the following Perl modules, which are probably most
easily installed by performing the following as root:

	sudo perl -MCPAN -e 'install Crypt::CBC'
	sudo perl -MCPAN -e 'install Crypt::DES'
	sudo perl -MCPAN -e 'install Digest::SHA'
	sudo perl -MCPAN -e 'install Crypt::OpenSSL::AES'
	sudo perl -MCPAN -e 'install Crypt::Rijndael'
	sudo perl -MCPAN -e 'install HTML::Template'
	sudo perl -MCPAN -e 'install JSON::XS'

(Use "su" and skip using "sudo" on platforms where that's inappropriate)

On OSX I had to go repermission some of the contents of
/Library/Perl/5.8.8/ (and subdirectories) because the CPAN build set
up JSON::XS and HTML::Template set no group- or world read/execute
permissions.  

This bug manifested itself as protomine failing to run as an Apache
CGI script, claiming that (eg:) JSON::XS did not exist / could not be
found, when in fact it *was* installed but running as the "www" user
(as a CGI script launched by Apache) it was unable to access

  /Library/Perl/5.8.8/JSON/darwin-thread-multi-2level/JSON/XS

...which was owned by "alecm" and mode 0700

I presume other platforms risk the same problem.


------------------------------------------------------------------

OSX installation:

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

Ubuntu installation:

Subversion
GNU Make
curl
perl
apache2

apt-get install subversion make curl perl apache2

------------------------------------------------------------------

OpenSolaris installation:

note: CPAN installation of Crypt::Rijndael barfs badly, with an error
that looks like:

#     Failed test (t/cbc.t at line 7)
#     Tried to require '/root/.cpan/build/Crypt-Rijndael-1.07/t/lib/mode.pl'.
#     Error:  Bareword "cpan" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "build" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "Crypt" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "Rijndael" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "t" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "lib" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "mode" not allowed while "strict subs" in use at (eval 1) line 2.
# Bareword "pl" not allowed while "strict subs" in use at (eval 1) line 2.
Undefined subroutine &main::crypt_decrypt called at t/cbc.t line 16.
# Looks like you failed 1 tests of 3.
# Looks like your test died just after 3.


The issue is hinted at by 'Bareword "cpan" not allowed'; something in
the Crypt::Rijndael test script suite is trying to require() on a
bareword, not expecting that the filename contains a dot (ie: '.cpan')
and thereby barfs badly.

The solution? 

	cd /root/.cpan/build/Crypt-Rijndael-1.07
	make install

...since the code actually works OK.

------------------------------------------------------------------

