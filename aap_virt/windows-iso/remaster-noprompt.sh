#!/usr/bin/env bash
# Rebuild a Windows ISO so UEFI boots straight into Setup (no "Press any key to
# boot from CD or DVD" prompt), then upload it to an OpenShift Virtualization PVC.
#
# Stock Microsoft media uses efi/microsoft/boot/efisys.bin, which prompts and
# times out to "no bootable device" on a blank disk. efisys_noprompt.bin ships on
# the same media and boots Setup unattended.
#
# Usage: remaster-noprompt.sh <source.iso> <namespace> [pvc-name] [storage-class]
# Needs: sudo (loop mount), rsync, xorriso, virtctl, oc login to the virt cluster.
set -euo pipefail
SRC=${1:?source iso}; NS=${2:?namespace}; PVC=${3:-win2022-eval-iso}; SC=${4:-truenas-iscsi-block}
WORK=$(mktemp -d); OUT="${SRC%.iso}-noprompt.iso"
sudo mkdir -p "$WORK/mnt" && sudo mount -o loop,ro "$SRC" "$WORK/mnt"
mkdir "$WORK/src" && rsync -a "$WORK/mnt/" "$WORK/src/"
sudo umount "$WORK/mnt"
xorriso -as mkisofs -iso-level 3 -J -joliet-long -R -V "WIN_NOPROMPT" \
  -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 \
  -eltorito-alt-boot -e efi/microsoft/boot/efisys_noprompt.bin -no-emul-boot \
  -o "$OUT" "$WORK/src"
rm -rf "$WORK/src"
SIZE_GI=$(( ( $(stat -c %s "$OUT") + 1073741823 ) / 1073741824 + 1 ))
UPLOAD=$(oc get route cdi-uploadproxy -n openshift-cnv -o jsonpath='{.spec.host}')
oc delete dv "$PVC" -n "$NS" --ignore-not-found; oc delete pvc "$PVC" -n "$NS" --ignore-not-found
virtctl image-upload dv "$PVC" -n "$NS" --size "${SIZE_GI}Gi" --image-path "$OUT" \
  --storage-class "$SC" --volume-mode block --access-mode ReadWriteMany --insecure \
  --uploadproxy-url "https://$UPLOAD"
echo "ISO PVC $NS/$PVC ready: $OUT"
