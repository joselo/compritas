#!/bin/bash
set -e

SWAPFILE="/swapfile"
SIZE="2G"

echo "Configuring swap..."

if [ ! -f $SWAPFILE ]; then
  echo "Creating swapfile of size $SIZE..."
  sudo fallocate -l $SIZE $SWAPFILE
  sudo chmod 600 $SWAPFILE
  sudo mkswap $SWAPFILE
else
  echo "Swapfile already exists at $SWAPFILE"
fi

echo "Activating swap..."
sudo swapon $SWAPFILE || echo "Swap already active"

if ! grep -q "$SWAPFILE" /etc/fstab; then
  echo "Adding swapfile to /etc/fstab..."
  echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
else
  echo "Swapfile already present in /etc/fstab"
fi

echo "Swap configured:"
free -h

