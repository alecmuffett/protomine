#!/bin/sh
exec 2>&1
#set -x

DIR=database/doc/sample-data
CMD=remote-mine.pl

# set up some basic tags
$CMD fast-tags \
     animals documents drink food france italy mine motorbikes people \
     plants shoes spain tannins things transport vrm weather

# set up tags with parents (must pre-define) for implicit tagging
$CMD fast-tags \
     cats/animals \
     flowers/plants \
     pumps/shoes \
     sneakers/shoes \
     stiletto/shoes \
     trainers/shoes

# the wine hierarchy, just to drive the point home
$CMD fast-tags \
     wine/drink \
     white-wine/wine \
     red-wine/wine \
     chardonnay/white-wine \
     rioja/red-wine/tannins

# upload some objects without individual tagging
$CMD fast-upload $DIR/*

# verbosely set up some relations
while read relationName relationVersion relationDescription relationInterests
do

    test "$relationName" = "" && continue

    $CMD create-relation \
	"relationName=$relationName" \
	"relationVersion=$relationVersion" \
	"relationDescription=$relationDescription" \
	"relationContact=$relationContact" \
	"relationInterests=$relationInterests" || exit 1

done <<EOF
alec     1  Alec-Muffett   wine      cats        motorbikes  mine
adriana  1  Adriana-Lukas  italy     motorbikes  cats        vrm   mine
carrie   1  Carrie-Bishop  sneakers  trainers    mine        vrm
ben      1  Ben-Laurie     wine      food        motorbikes
EOF

# done
exit 0
