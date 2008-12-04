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

exec 2>&1
#set -x

###
# can't be arsed to poke filenames in everywhere

DIR=database/doc/sample-data
MINECTL=./minectl


###
# set up some basic tags

$MINECTL fast-tags \
     animals documents drink food mine motorbikes people plants shoes \
     things transport vrm weather french italian spanish


###
# set up tags with parents for implicit tagging; 
# NB: you must pre-declare a tag before you use it as a parent

$MINECTL fast-tags \
     cats/animals \
     hippos/animals \
     cookery/food \
     flowers/plants \
     pumps/shoes \
     sneakers/shoes \
     stiletto/shoes \
     trainers/shoes


###
# the wine hierarchy, just to drive the point home

$MINECTL fast-tags \
     wine/drink \
     white-wine/wine \
     red-wine/wine \
     chardonnay/white-wine \
     tannins \
     rioja/red-wine/tannins


###
# upload some objects without individual tagging

$MINECTL fast-upload $DIR/* # my, isn't this easy?


###
# verbosely set up some relations; there is actually a "fast-relation"
# that does exactly this, however the example is worthwhile to show
# what you may want to do if you want to drive it at the lowest level.

while read relationName relationVersion relationDescription relationInterests
do
    test "$relationName" = "" && continue

    # this shell script can't preserve space easily, hence this hack
    relationDescription=`echo $relationDescription | sed -e 's/_/ /'`

    $MINECTL create-relation \
	"relationName=$relationName" \
	"relationVersion=$relationVersion" \
	"relationDescription=$relationDescription" \
	"relationInterests=$relationInterests" || exit 1

done <<EOF
alec     1  Alec_Muffett   wine      cats      motorbikes  mine
adriana  1  Adriana_Lukas  wine      cookery   motorbikes  vrm   mine
carrie   1  Carrie_Bishop  sneakers  trainers  mine        vrm
ben      1  Ben_Laurie     wine      food      motorbikes
EOF


###
# quick hack to demo fast-relation

$MINECTL fast-relation perry 1 "Perry de Havilland" red-wine food require:hippos except:white-wine


###
# done

exit 0
