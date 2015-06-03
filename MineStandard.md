# Introduction #

A first stab at a list of structural and technical qualities that are necessary for a Mine to be called a Mine.


# Mine Technical Requirements #

## Definitions ##

  * _user_ - the person with autocracy over their mine
  * _owner_ - synonym for user
  * _subscriber_ - those who receive feeds from an user's mine

  * _minekey_
  * _browser_
  * _uploader_
  * _scraper_
  * _backup_

## A Mine exists for the benefit of its User ##

Rule zero.

## If it's not yours, it's not a Mine ##

This is the guiding principle of a Mine; a user's Mine _must_ be under his control for creation, reading, updating, deleting (in part or entirety), duplication, and access-management.

## The Mine root URL must be user-distinct ##

Any given Mine _must_ have a distinct "root" URL (hostname and path) to separate it from the mines of other users; eg: where _alec_ represents an given user...

> GOOD
  * http://alec.domain.com/
  * http://alec.domain.com/mine/
  * http://www.alec.com/
  * http://www.alec.com/mine/
  * http://www.domain.com/alec/
  * http://www.domain.com/alec/mine/
  * http://www.domain.com/mine/alec/

> BAD
  * http://www.domain.com/
  * http://www.domain.com/mine/
  * http://www.domain.com/mine/?user=alec
  * _anything involving cookies for identity_

## Minekey Separation ##

Separate mines _must_ have separate global crypto keys for separate minekey protection.

## Control of Data at Rest ##

The data it stores _should_ be under the user's physical control, or otherwise somehow kept beyond seizure.

## Control of Data in Motion ##

All user access to/from a Mine _must_ be authenticated, eg: passworded; this includes browser, uploader, scraper and backup applications.

All data shared from a Mine to subscribers _must_ be authenticated by minekey.

## Secrecy of Data at Rest ##

All data (and metadata) stored in a Mine _must_ by default be private to the user, and remains so unless the user elects to share items to subscribers.

## Secrecy of Data in Motion ##

All user access to/from a Mine _must_ be encrypted (eg: SSL); this includes browser, uploader, scraper and backup applications.

All data shared from a Mine to mine-subscribers, ie: feeds, _should_ be encrypted (eg: SSL). We expect this requirement to become a "_must_" by 2012.

## Subscriber access to depth ##

## Next? ##