#!/bin/bash


SCRIPT_PATH="/var/lib/CertAlert/skrypty/powiadamiacz.sh"
CERT_DIR="/var/lib/CertAlert/Monitorowane"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Skrypt $SCRIPT_PATH nie istnieje."
  exit 1
fi


if [ ! -d "$CERT_DIR" ]; then
  echo "Folder $CERT_DIR nie istnieje."
  exit 1
fi

for cert_file in "$CERT_DIR"/*; do
  if [ -f "$cert_file" ]; then
    "$SCRIPT_PATH" "$cert_file"
  fi
done