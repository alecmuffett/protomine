#!/bin/sh
exec 2>&1
#set -x

DIR=database/doc/sample-data
CMD=remote-mine.pl

# set up some tags
while read tagName tagParents
do

    test "$tagName" = "" && continue
    $CMD create-tag \
	"tagName=$tagName" \
	"tagParents=$tagParents" || exit 1

done <<EOF
food
drink
people
things
animals
plants
transport
wine drink
white-wine wine
red-wine wine
tannins
cats animals
shoes
stiletto shoes
sneakers shoes
trainers shoes
pumps shoes
france
italy
spain
rioja  red-wine tannins
chardonnay white-wine
documents
flowers plants
mine
motorbikes
vrm
weather
EOF

# set up some relations
while read relationName relationVersion relationDescription relationContact relationInterests
do

    test "$relationName" = "" && continue
    $CMD create-relation \
	"relationName=$relationName" \
	"relationVersion=$relationVersion" \
	"relationDescription=$relationDescription" \
	"relationContact=$relationContact" \
	"relationInterests=$relationInterests" || exit 1

done <<EOF
alec 1 Alec-Muffett alec.muffett@gmail.com wine cats motorbikes mine
adriana 1 Adriana-Lukas adriana.lukas@gmail.com italy motorbikes cats vrm mine
carrie 1 Carrie-Bishop fake.address@fake.domain sneakers trainers mine vrm
ben 1 Ben-Laurie fake.address@fake.domain wine food motorbikes
EOF

# set up some objects
$CMD upload $DIR/*

# done
exit 0
