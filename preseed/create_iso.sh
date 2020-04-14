#!bin/bash

# T&M Hansson IT AB © - 2020, https://www.hanssonit.se/

DEVDIR=/home/daniel/Desktop/preseed_20200413
PRESEED_ISO_DIR="$DEVDIR"/preseeded
ISO=http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso
#PRESEED_ORIG="$DEVDIR"/preseed.cfg
PRESSEED_FOLDER=/tmp
PRESEED_ORIG="$PRESSEED_FOLDER"/preseed.cfg

# Download the presseed file
echo "Downloading preseed file..."
wget https://raw.githubusercontent.com/techandme/things/master/preseed/diaverum.cfg -O "$PRESSEED_FOLDER"/preseed.cfg

# Always get the latest mini.iso
echo "Getting latest mini.iso..."
mkdir -p $DEVDIR && cd $DEVDIR
curl -sLO $ISO -o mini.iso || exit

# Install 7Zip if missing
if ! dpkg -l | grep p7zip >/dev/null
then
    apt update && apt install p7zip-full -y
fi

# Extract the content of ISO
if [ -d "$DEVDIR"/mini ]
then
    rm -R "$DEVDIR"/mini
fi

7z x -omini "$DEVDIR"/mini.iso

# Extract intrd.gz
rm -rf "$PRESEED_ISO_DIR"
mkdir -p "$PRESEED_ISO_DIR"
(cd preseeded && gzip -d < "$DEVDIR"/mini/initrd.gz | cpio -id)

if [ ! -f "$PRESEED_ORIG" ]
then
    echo "The preseed file is missing, please put your preseed.cfg in $PRESEED_ORIG"
    exit 1
fi

# Copy the preseed file
cp "$PRESEED_ORIG" "$PRESEED_ISO_DIR"

# Package the initrd.gz with the new preseed.cfg
(cd preseeded && find . | cpio -o -H newC | gzip) > "$DEVDIR"/mini/initrd.gz

# Make new ISO
(cd "$DEVDIR"/mini && genisoimage -quiet -o "$DEVDIR"/mini-preseed.iso \
    -b isolinux.bin -c boot.cat -boot-info-table \
    -no-emul-boot -iso-level 2 -udf -rock \
    -J -l -D -N -joliet-long -relaxed-filenames \
    -allow-limited-size .)

echo "New changes made, and new ISO created!"

chown -R daniel:daniel "$DEVDIR"
