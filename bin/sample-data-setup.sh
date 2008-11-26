#!/bin/sh
exec 2>&1 
#set -x

CMD=remote-mine.sh
DIR=database/doc/sample-data

# set up some tags
while read tag parents
do
    test "$tag" = "" && continue
    $CMD create-tag $tag $parents|| exit 1
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
while read name version comment contact interests
do
    $CMD create-relation \
	"$name" \
	"$version" \
	"$comment" \
	"$contact" \
	"$interests" || exit 1
done <<EOF
alec 1 Alec-Muffett alec.muffett@gmail.com wine cats motorbikes mine
adriana 1 Adriana-Lukas adriana.lukas@gmail.com italy motorbikes cats vrm mine
carrie 1 Carrie-Bishop fake.address@fake.domain sneakers trainers mine vrm
ben 1 Ben-Laurie fake.address@fake.domain wine food motorbikes
EOF

# set up some objects
while read filename type
do
    $CMD create \
	$DIR/$filename \
	"upload from $filename" \
	`bin/lookup-mime.pl $filename` \
	draft \
	"this is a comment about $filename" || exit 1
done <<EOF
adriana.jpg
alecm.png
austen.txt
bridge.jpg
buster.jpg
cloud.jpg
dam.jpg
fashion1.jpg
feeds-based-vrm.pdf
italy.jpg
milan.jpg
mine-diagram.jpg
mine-paper-v2.pdf
monument.jpg
moon.jpg
mountains.jpg
pimpernel.jpg
rome.jpg
rose.jpg
stonehenge.jpg
suzi.jpg
woodland.jpg
EOF
