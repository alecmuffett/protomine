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

$MINECTL new-tags \
     animals documents drink food mine motorbikes people plants shoes \
     things transport vrm weather french italian spanish


###
# set up tags for implicit tagging;
# NB: you must pre-declare a tag before you use it as an implied tag

$MINECTL new-tags \
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

$MINECTL new-tags \
     wine/drink \
     white-wine/wine \
     red-wine/wine \
     chardonnay/white-wine \
     tannins \
     rioja/red-wine/tannins


###
# upload some objects without individual tagging

$MINECTL upload $DIR/* # my, isn't this easy?


###
# verbosely set up some relations; there is actually a "new-relation"
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
alec     1  Alec_Muffett   wine      cats      motorbikes  mine  food
adriana  1  Adriana_Lukas  wine      cookery   motorbikes  vrm   mine
carrie   1  Carrie_Bishop  sneakers  trainers  mine        vrm
ben      1  Ben_Laurie     wine      food      motorbikes
EOF


###
# quick hack to demo new-relation

$MINECTL new-relation perry 1 "Perry de Havilland" red-wine food require:hippos except:white-wine

###
# special cases for tag testing
while read file tags
do
    $MINECTL create-object data=@$DIR/$file objectType=`$MINECTL mime-type $file` \
	objectName="name($file)" objectDescription="description($file $tags)" \
	objectStatus=public objectTags="$tags"
done <<EOF
dam.jpg              for:perry
fashion1.jpg         food       for:perry
adriana.jpg          food       hippos     chardonnay
rome.jpg             food       hippos     for:perry   not:perry
feeds-based-vrm.pdf  food       hippos     not:perry
monument.jpg         food       hippos
rose.jpg             food
mountains.jpg        hippos
stonehenge.jpg       not:perry
suzi.jpg             red-wine   hippos
moon.jpg             wine       hippos
mine-diagram.jpg
italy.jpg
mine-paper-v2.pdf    for:alec
bridge.jpg
alecm.png   
woodland.jpg
austen.txt
milan.jpg
cloud.jpg
pimpernel.jpg
buster.jpg
EOF

###
# done

exit 0
