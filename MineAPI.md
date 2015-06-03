# Introduction #

API calls are handled in REST space, with CRUD (create/read/update/delete) nomenclature:

  * CREATE = HTTP POST
  * READ = HTTP GET
  * UPDATE = HTTP PUT
  * DELETE = HTTP DELETE

In addition, HTTP POST, HTTP PUT and HTTP DELETE requests to support
the above can be faked by submitting GET or POST requests to the URL
and setting the "_method" parameter to the uppercase request method
name:_

```
  GET /api/config.json?_method=POST # equivalent to HTTP POST
```

This must be implemented to work even if the requests uses POSTDATA
(multipart upload, etc) for transfer; a URI-attached fake method must
take precedence over post-data.

# Notes #

  * **the terms _object/oid_ are to be replaced by _item/iid_ throughout, in pymine v1.0 and onwards**
  * flag **TODO** denotes work in progress as of april 2009
  * flag **RO** denotes read-only key
  * flag **GT0** denotes "greater than zero"
  * flag **RAW** denotes a function returning raw HTTP object data, rather than a data structure

# Non-API URLs #

  * `/pub` (get)
  * `/pub/*` (get)

> - where unprotected, public-access files live, eg: flash player binaries

  * `/doc` (get)
  * `/doc/*` (get)

> - authenticated access to documentation for this mine

  * `/ui` (get)
  * `/ui/*` (get)

> - root directory for user interface pages

  * `/v/*` (get) (post) **TODO**

> - vanity naming space, maps /v/FOO(/BAR) to minekey of a public relationship for traditional blog-type one-to-many communication; also acts as a tinyurl clone

  * `/r/*` (get) (post) **TODO**

> - rendezvous naming space, space to hook plugin listeners, eg: OAuth Identica subscriber server URLs.

# Minekey URLs #

  * `/get?key=MINEKEY` (get)
  * `/get?key=MINEKEY` (post) **TODO**

> - the only "public" URLs in a mine are either those under `/pub`, or those accessed via the Minekey interface `/get`; minekeys are opaque blobs referring to tuples of OID and RID, which may or may not yield data retreival.  All `/get` retreivals are audited.

# API Nomenclature #

  * FMT - `xml` or `json`; the format in which to return status, or data
  * KEY - string name one of the relevant keys (eg: `objectName`) being accessed or manipulated
  * OID - decimal index number of an object, range 1..bignum
  * CID - decimal index number of a comment for a given OID, range 1..bignum
  * RID - decimal index number of a relation, range 1..bignum
  * TID - decimal index number of a tag, range 1..bignum.

# API call return values #

> non-zero == success (either a useful number, or integer 1)

# API URLs #

## core API ##

  * `/api/version.FMT` (read)
> _returns:_ version information as a structure

## config and directory API ##

  * `/api/config.FMT` (read) **TODO**
> _returns:_ a list of configuration keys
  * `/api/config/KEY.FMT` (create) **TODO**
> _action:_ updates multiple keys from valid config keys supplied in postdata
> _returns:_ number of successful updates
  * `/api/config/KEY.FMT` (delete) **TODO**
> _action:_ deletes KEY from configuration
> _returns:_ status
  * `/api/config/KEY.FMT` (read) **TODO**
> _action:_ reads KEY from configuration
> _returns:_ value
  * `/api/config/KEY.FMT` (update) **TODO**
> _action:_ updates KEY in configuration
> _returns:_ status

## object API ##

  * `/api/object.FMT` (create)
> _action:_ creates an object from valid object keys supplied in postdata
> _returns:_ oid
  * `/api/object.FMT` (read)
> _returns:_ a list of oids, sorted most-recently-interesting-first
  * `/api/object/OID` (read) **NOTE1**
> _returns:_ the data associated with OID, eg: a JPEG file
  * `/api/object/OID.FMT` (delete)
> _action:_ deletes OID
> _returns:_ status
  * `/api/object/OID.FMT` (read)
> _returns:_ all metadata associated with OID
  * `/api/object/OID/key.FMT` (create)
> _action:_ updates multiple keys for OID from valid object keys supplied in postdata
> _returns:_ number of successful updates
  * `/api/object/OID/key/KEY.FMT` (delete)
> _action:_ deletes KEY from OID
> _returns:_ status
  * `/api/object/OID/key/KEY.FMT` (read) **NOTE1**
> _action:_ reads KEY from OID
> _returns:_ value
  * `/api/object/OID/key/KEY.FMT` (update)
> _action:_ updates KEY in OID
> _returns:_ status

## comment API ##

  * `/api/object/OID/comment.FMT` (create) **TODO**
> _action:_ creates a comment (for OID) from valid comment keys supplied in postdata
> _returns:_ cid
  * `/api/object/OID/comment.FMT` (read) **TODO**
> _returns:_ a list of cids (for OID) sorted most-recently-interesting-first
  * `/api/object/OID/CID.FMT` (delete) **TODO**
> _action:_ deletes CID (for OID)
> _returns:_ status
  * `/api/object/OID/CID.FMT` (read) **TODO**
> _returns:_ all metadata associated with CID
  * `/api/object/OID/CID/key.FMT` (create) **TODO**
> _action:_ updates multiple keys for CID (of OID) from valid comment keys supplied in postdata
> _returns:_ number of successful updates
  * `/api/object/OID/CID/key/KEY.FMT` (delete) **TODO**
> _action:_ deletes KEY from CID (of OID)
> _returns:_ status
  * `/api/object/OID/CID/key/KEY.FMT` (read) **TODO**
> _action:_ reads KEY from CID (of OID)
> _returns:_ value
  * `/api/object/OID/CID/key/KEY.FMT` (update) **TODO**
> _action:_ updates KEY in CID (of OID)
> _returns:_ status

## clone API ##

  * `/api/object/OID/clone.FMT` (create) **TODO**
> _action:_ clones OID (sans comments)
> _returns:_ new OID
  * `/api/object/OID/clone.FMT` (read) **TODO**
> _returns:_ list of oids that are clones of OID

## relation API ##

  * `/api/relation.FMT` (create)
> _action:_ creates a relation from valid relation keys supplied in postdata
> _returns:_ rid
  * `/api/relation.FMT` (read)
> _returns:_ a list of rids, sorted most-recently-interesting-first
  * `/api/relation/RID.FMT` (delete)
> _action:_ deletes RID
> _returns:_ status
  * `/api/relation/RID.FMT` (read)
> _returns:_ all metadata associated with RID
  * `/api/relation/RID/key.FMT` (create)
> _action:_ updates multiple keys for RID from valid relation keys supplied in postdata
> _returns:_ number of successful updates
  * `/api/relation/RID/key/KEY.FMT` (delete)
> _action:_ deletes KEY from RID
> _returns:_ status
  * `/api/relation/RID/key/KEY.FMT` (read)
> _action:_ reads KEY from RID
> _returns:_ value
  * `/api/relation/RID/key/KEY.FMT` (update)
> _action:_ updates KEY in RID
> _returns:_ status

## tag API ##

  * `/api/tag.FMT` (create)
> _action:_ creates a tag from valid tag keys supplied in postdata
> _returns:_ tid
  * `/api/tag.FMT` (read)
> _returns:_ a list of tids, sorted most-recently-interesting-first
  * `/api/tag/TID.FMT` (delete)
> _action:_ deletes TID
> _returns:_ status
  * `/api/tag/TID.FMT` (read)
> _returns:_ all metadata associated with TID
  * `/api/tag/TID/key.FMT` (create)
> _action:_ updates multiple keys for TID from valid tag keys supplied in postdata
> _returns:_ number of successful updates
  * `/api/tag/TID/key/KEY.FMT` (delete)
> _action:_ deletes KEY from TID
> _returns:_ status
  * `/api/tag/TID/key/KEY.FMT` (read)
> _action:_ reads KEY from TID
> _returns:_ value
  * `/api/tag/TID/key/KEY.FMT` (update)
> _action:_ updates KEY in TID
> _returns:_ status

## search and selection API ##

  * `/api/select/object.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/select/relation.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/select/tag.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/share/raw/RID/RVSN/OID.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/share/redirect/RID.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/share/redirect/RID/OID.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/share/url/RID.FMT` (read) **TODO**
> _action:_ tbd
  * `/api/share/url/RID/OID.FMT` (read) **TODO**
> _action:_ tbd


# valid object-related keys #

  * `data` - the data described by the object metadata, eg: a JPEG image

> NOTE1: Because the `data` key has its own MIME-type, it is not
> available via a READ of `/api/object/OID/key/data.FMT`, however
> `data` may be CREATEd, UPDATEd or DELETEd.

  * `objectCreated` **RO** - decimal unix time
  * `objectDescription` - HTML
  * `objectHideAfter` - decimal unix time
  * `objectDeleteAfter` - decimal unix time  # **TODO** for GC of tweets, etc
  * `objectHideBefore` - decimal unix time
  * `objectId` **RO** **GT0** - decimal integer
  * `objectLastModified` **RO** - decimal unix time
  * `objectName` - plaintext
  * `objectStatus` - one of: `draft`, `final`, or `public`, plaintext
  * `objectTags` - tag-text
  * `objectType` - valid object mime type

# valid comment-related keys #

> Question: should contentData carry a content-type, or its usage be implicit
via the object it hangs-off?

  * `commentBody` - HTML
  * `commentData` - octets, non-HTML payload, limited in size (eg: identi.ca)
  * `commentCreated` **RO** - decimal unix time
  * `commentId` **RO** **GT0** - decimal integer
  * `commentLastModified` **RO** - decimal unix time
  * `commentRelationId` **GT0** - decimal integer RID
  * `commentSubject` - plaintext

# valid relation-related keys #

  * `relationContactEmail` - rfc822 email address, plaintext
  * `relationContactURL` - URL, plaintext
  * `relationCreated` **RO** - decimal unix time
  * `relationDescription` - HTML
  * `relationEmbargoAfter` - decimal unix time
  * `relationEmbargoBefore` - decimal unix time
  * `relationIPAddress` - IP address from which this relation accesses you; as CIDR (eg: `192.168.1.0/24`) **or** ip-address-prefix (eg: `192.168.1.`)
  * `relationId` **RO** **GT0** - decimal integer
  * `relationImageURL` - URL
  * `relationInterests` - relation-tag-text
  * `relationLastModified` **RO** - decimal unix time
  * `relationName` - plaintext
  * `relationURL` - URL
  * `relationVersion` **GT0** - decimal integer

# valid tag-related keys #

  * `tagCreated` **RO** - decimal unix time
  * `tagId` **RO** **GT0** - decimal integer
  * `tagImplies` - tag-name
  * `tagLastModified` **RO** - decimal unix time
  * `tagName` - tag-name