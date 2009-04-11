#!/usr/bin/perl

# Populate your Mine! with photos from Flickr
# Mathias Baert (who doesn't know perl and shopped around in protomine for reusable code)

# package ImportFlickr;

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use LWP;
use File::Temp;

# standard config for this system
require "../protomine-config.pl"; # try to get my config

our $MINE_HTTP_FULLPATH;

my $FLICKR_API_KEY = "0b0db7ba72b1af41826c5ee8a13cf931";

my $FLICKR_BASE_URL = "http://www.flickr.com/services/rest/";

my $FLICKR_PEOPLE_FIND_BY_USERNAME  = "$FLICKR_BASE_URL?method=flickr.people.findByUsername&username=%s&api_key=$FLICKR_API_KEY";
my $FLICKR_PEOPLE_GET_PUBLIC_PHOTOS = "$FLICKR_BASE_URL?method=flickr.people.getPublicPhotos&user_id=%s&api_key=$FLICKR_API_KEY&per_page=%s&extras=tags";
my $FLICKR_PHOTOS_GET_INFO          = "$FLICKR_BASE_URL?method=flickr.photos.getInfo&photo_id=%s&api_key=$FLICKR_API_KEY";
my $FLICKR_PHOTO_URL                = "http://www.flickr.com/photos/%s/%s/sizes/%s/";

my $MINE_LIST_TAGS  = "$MINE_HTTP_FULLPATH/api/tag.xml";
my $MINE_GET_TAG    = "$MINE_HTTP_FULLPATH/api/tag/%s.xml";
my $MINE_CREATE_TAG = "$MINE_HTTP_FULLPATH/api/tag.xml?_method=POST&tagName=%s";

my %FLAG;
$FLAG{'amount'} = 10;

while ($ARGV[0] =~ m!^-(\w+)!o) {
    my $switches = $1;

    foreach my $switch (split(//o, $switches)) {
		if ($switch eq 'v') {
		    $FLAG{'verbose'}++;
		}
		elsif ($switch eq 'a') {
		    shift(@ARGV); # dump the -a
		    $FLAG{'amount'} = $ARGV[0];
		}
		elsif ($switch eq 'o') {
		    $FLAG{'original'} = 1;
		}
		elsif ($switch eq 'u') {
		    shift(@ARGV); # dump the -u
		    $FLAG{'username'} = $ARGV[0];
		}
		else {
		    die "$0: unknown option $switch (fatal)\n";
		}
    }

    shift;
}

# verify the given options are valid
if ( !$FLAG{username} ) {
	die "Required argument 'username' missing";
}
if ( $FLAG{amount} > 100 ) {
	die "Argument 'amount' cannot be larger than 100";
	# above 100, you have to use paging, which I didn't implement yet
}


my $browser = LWP::UserAgent->new;
my $tags = getExistingTags();


doImport();


# below only functions

sub doImport {
    my $userId = getUserId();
    my $photos = getPublicPhotos($userId);

    while ( my ($key, $value) = each %$photos ) {
	savePhoto($key, $value);
    }
}

sub getUserId {
    my $url = sprintf($FLICKR_PEOPLE_FIND_BY_USERNAME, $FLAG{username});
    my $result = performQuery($url);
    return $result->{user}->{nsid};
}

sub getPublicPhotos {
    my $userId = shift;

    my $url = sprintf($FLICKR_PEOPLE_GET_PUBLIC_PHOTOS, $userId, $FLAG{amount});
    my $result = performQuery($url, 1);
    return $result->{photos}->{photo};
}

sub getPhotoInfo {
    my $photoId = shift;

    my $url = sprintf($FLICKR_PHOTOS_GET_INFO, $photoId);
    my $result = performQuery($url);

    return $result->{photo}->{$photoId};
}

sub getPhotoUrl {
	my $photoId = shift;

	my $size = "m";
	if ($FLAG{original}) {
		$size = "o";
	}

	my $url = sprintf($FLICKR_PHOTO_URL, $FLAG{username}, $photoId, $size);

	my $response = $browser->get($url);

	die "Can't get $url -- ", $response->status_line
	    unless $response->is_success;

    if ($response->content =~ /http:\/\/farm[^"]+_[a-z]\.jpe?g+/) {
	return $&;
    }
    die "Couldn't find url for image \"$photoId\" at $url\n";
}

sub getExistingTags {
    my $result = performQuery($MINE_LIST_TAGS);

	my $tags;

	foreach my $tagId (@{$result->{tagId}}) {
		$tags->{getTagValue($tagId)} = $tagId;
	}

    return $tags;
}

sub getTagValue {
	my $tagId = shift;

	my $url = sprintf($MINE_GET_TAG, $tagId);
    my $result = performQuery($url);

	return $result->{tagName};
}

sub createTag {
	my $tag = shift;

	my $url = sprintf($MINE_CREATE_TAG, $tag);

    my $result = performQuery($url);

	return $result;
}

sub performQuery {
    my $url = shift;

    my $response = $browser->get($url);

	die "Can't get $url -- ", $response->status_line
	    unless $response->is_success;

	my $result = XMLin($response->content, KeyAttr=>"id", ForceArray=>['photo']);

    return $result;
}

sub downloadFile {
	my $url = shift;

	my $filename = tmpnam();

    my $response = $browser->get($url, ':content_file'=>$filename);

	die "Can't get $url -- ", $response->status_line
	    unless $response->is_success;

    return $filename;
}

sub savePhoto {
	my $photoId = shift;
    my $data = shift;

	foreach my $tag (split(" ", $data->{tags})) {
		$tags->{$tag} = createTag($tag) if !exists $tags->{$tag};
	}


	my $info = getPhotoInfo($photoId);

    my $filename = downloadFile(getPhotoUrl($photoId));

    system ("../minectl create-object ".
			"objectName=".safeArgument($data->{title})." ".
			"data=".safeArgument("@".$filename)." ".
			"objectDescription=".safeArgument($info->{description})." ".
						"objectTags=".safeArgument($data->{tags})." ".
			"objectStatus=draft ".
			"objectType=image/jpeg");

	# print "saved photo \"".$data->{title}."\"\n";
}

sub safeArgument {
	my $value = shift;

	return "" if !defined $value;

	$value =~ s/'/'\\''/g;
	return "'".$value."'";
}
