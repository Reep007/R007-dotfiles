#!/bin/bash
source ~/.cache/wal/colors.sh
for icon in folder.svg folder-downloads.svg folder-documents.svg folder-pictures.svg folder-desktop.svg folder-music.svg folder-publicshare.svg folder-videos.svg folder-templates.svg; do
    sed -i "s/fill:[^;]*;/fill:$color3;/g" ~/.icons/pywal-custom/scalable/places/$icon
done
gtk-update-icon-cache ~/.icons/pywal-custom
