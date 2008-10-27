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

##set -x

# where is the mine
ROOT=http://localhost/~alecm/mine
#CURLAUTH="--digest --user alecm:sesame"
#CURLVERBOSE="--verbose"
MIMEFILE=database/config/mime.types

# what are we doing
CMD=$1
shift

# prefix 

# Usage: Mine METHOD /URL/FOR/API CURLOPTIONS ...
Mine() {
    METHOD=$1
    shift

    case $METHOD in
	"create") QUERY="" ;;
	"read")   QUERY="" ;;
	"update") QUERY="?_method=UPDATE" ;;
	"delete") QUERY="?_method=DELETE" ;;
	*)      echo "$0: bad CRUD: '$METHOD' $1" 1>&2 ; exit 1 ;;
    esac

    API=$1
    shift

    curl --fail $CURLVERBOSE $CURLAUTH "$@" $ROOT$API$QUERY
    return $?
}

##################################################################
# main code starts here

case "$CMD" in

    test) 
	Mine read /test 
	;;

    version) 
	Mine read /api/version.xml 
	;;

    upload)
	for i in "$@" # recurse
	do
	    remote-mine.sh create "$i" "file: $i" `lookup-mime $i` draft "auto-upload of $i"
	done
	;;

    create)
	Mine create /api/object.xml \
	    -F "data=@$1" \
	    -F "objectName=$2" \
	    -F "objectType=$3" \
	    -F "objectStatus=$4" \
	    -F "objectDescription=$5"
	;;

    create-relation)
	Mine create /api/relation.xml \
	    -F "relationName=$1" \
	    -F "relationVersion=$2" \
	    -F "relationDescription=$3" \
	    -F "relationContact=$4" \
	    -F "relationInterests=$5"
	;;
    create-tag) 
	TAG=$1
	shift
	Mine create /api/tag.xml -F "tagName=$TAG" -F "tagParents=$*" # must use $*
	;;
    delete) 
	for i in "$@" 
	do 
	    Mine delete /api/object/$i.xml 
	done 
	;;
    delete-relation) 
	for i in "$@" 
	do 
	    Mine delete /api/relation/$i.xml 
	done 
	;;
    delete-tag) 
	for i in "$@" 
	do 
	    Mine delete /api/tag/$i.xml 
	done 
	;;
    list) 
	Mine read /api/object.xml 
	;;
    list-relations) 
	Mine read /api/relation.xml 
	;;
    list-tags) 
	Mine read /api/tag.xml 
	;;

    read) 
	ID=$1
	Mine read /api/object/$ID.xml
	;;

    read-aux) 
	ID=$1
	Mine read /api/object/$ID
	;;

    read-relation) 
	ID=$1
	Mine read /api/relation/$ID.xml
	;;

    read-tag) 
	ID=$1
	Mine read /api/tag/$ID.xml
	;;



    # clone) ;;
    # dump) ;;
    # dump-relations) ;;
    # dump-tags) ;;
    # get-http-feed) ;;
    # get-http-object) ;;
    # get-secure-url) ;;
    # pick-tagged) ;;
    # pick-visible-to) ;;
    # post) ;;
    # read-relation-by-name) ;;
    # read-tag-by-name) ;;
    # update) ;;
    # update-data) ;;
    # update-meta) ;;
    # update-relation) ;;
    # update-tag) ;;

    *)
	echo "$0: unknown command: $CMD $@" 1>&2
	exit 1
	;;
esac

exit $?
