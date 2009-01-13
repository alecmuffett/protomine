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

##################################################################

package Context;

use strict;
use warnings;

##################################################################
# CONSTRUCTOR
##################################################################

## the Context object holds all the messy pathnames and URLs and other
## things, providing a container for all that stuff plus a fast way to
## sanith-check a request which you know (eg) will require a trailing
## slash *before* you get around to instantiating a Page object
## (relatively expensive)

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    # CGI object, provided by user
    my $q = $self->{CGI} = shift;

    # the URL path as provided by user, eg: /cgi-bin/mine.cgi
    $self->{URL_DECLARED} = shift; # ---- NO TRAILING SLASH ----

    # the request method, eg: GET, PUT, POST, DELETE, ...
    $self->{METHOD} = $q->request_method;

    # the base, eg: http://foo
    $self->{URL_BASE} = $q->url(-base => 1);

    # the body, eg: /cgi-bin/mine.cgi/path/file.ext
    $self->{URL_BODY} = $q->url(-absolute => 1, -path => 1);

    # the full url,
    # eg: http://foo/cgi-bin/mine.cgi/path/file.ext?foo=bar
    my $full = $self->{URL_FULL} = $q->url(-path => 1, -query => 1);

    # store the query elsewhere, for diagnostics
    if ($full =~ m!(\?.*)$!o) {
	$self->{URL_QUERY} = $1; # $foo=bar
    }
    else {
	$self->{URL_QUERY} = ''; # no query
    }

    # note where the UI bits are
    $self->{FILE_CSS} = "database/ui/bits/mine.css";
    $self->{FILE_FOOTER} = "database/ui/bits/footer.html";
    $self->{FILE_HEADER} = "database/ui/bits/header.html";

    # hyperlinks to same
    my $baseurl = $self->{URL_BASE} . $self->{URL_DECLARED};
    $self->{URL_CSS}    = $baseurl . "/ui/bits/mine.css";
    $self->{URL_FOOTER} = $baseurl . "/ui/bits/footer.html";
    $self->{URL_HEADER} = $baseurl . "/ui/bits/header.html";

    # done
    return $self;
}

##################################################################

sub cgi {                       # return my CGI object
    my $self = shift;
    return $self->{CGI};
}

sub method {                    # return my method
    my $self = shift;
    return $self->{METHOD};
}

sub path {			# return the intra-mine URL path, eg: /api/foo.xml
    my $self = shift;
    my $body = $self->{URL_BODY};
    my $declared = $self->{URL_DECLARED};

    die "path: fatal error stripping '$declared' from '$body'\n"
	unless ($body =~ s!^$declared!!);

    return $body;
}

##################################################################

# this routine takes the accessed URL and canonicalises it, which
# should get us past most of the common sorts of security bugs; if
# there is a failure to match, a redirect is issued.

sub assertCanonicalURL {
    my $self = shift;

    # fetch the appropriate fragment
    my $clean = $self->{URL_BODY};

    # if different, issue a redirect
    $clean =~ s!/\./!/!go;      # squash "/./" -> "/"
    1 while ($clean =~ s!/[^/]+/\.\./!/!o); # squash "/foo/../" into "/"
    $clean =~ s!//+!/!go;       # squash "//" (or more) into "/"

    # redirect, if any change occured
    if ($clean ne $self->{URL_BODY}) {
	my $reconstruct =
	    $self->{URL_BASE} . # http://foo
	    $clean .            # /cgi-bin/mine.cgi/dir/foo.xml
	    $self->{URL_QUERY}; # ?foo=bar

	my $q = $self->cgi;
	print $q->redirect(-uri => $reconstruct, -status => 301);
	exit 0;
    }
}

##################################################################

# this routine is a no-op if the url for the query originally
# contained a trailing slash; otherwise it issues a HTTP redirect to
# the page *with* a trailing slash, for use in directory displays.

sub assertTrailingSlash {
    my $self = shift;

    # fetch the appropriate fragment
    my $path = $self->{URL_BODY};

    # if no trailing slash, issue a redirect
    unless ($path =~ m!/$!o) {
	my $reconstruct =
	    $self->{URL_BASE} . # http://foo
	    $self->{URL_BODY} . # /cgi-bin/mine.cgi/foo
	    "/" .               # add a trailing "/"
	    $self->{URL_QUERY}; # ?foo=bar

	my $q = $self->cgi;
	print $q->redirect(-uri => $reconstruct, -status => 301);
	exit 0;
    }
}

##################################################################

1;
