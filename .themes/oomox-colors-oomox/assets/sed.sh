#!/bin/sh
sed -i \
         -e 's/#0a0a0f/rgb(0%,0%,0%)/g' \
         -e 's/#d7cccc/rgb(100%,100%,100%)/g' \
    -e 's/#0a0a0f/rgb(50%,0%,0%)/g' \
     -e 's/#3A4A57/rgb(0%,50%,0%)/g' \
     -e 's/#0a0a0f/rgb(50%,0%,50%)/g' \
     -e 's/#d7cccc/rgb(0%,0%,50%)/g' \
	"$@"
