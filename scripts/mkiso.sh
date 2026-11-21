#!/bin/sh
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
parent=$1
stage=$2
work=$3
iso=$4
efi=BOOTX64.EFI

limine_share=""
for c in /usr/share/limine /tmp/limine-pkg/usr/share/limine; do
	[ -f "$c/limine-bios-cd.bin" ] && { limine_share=$c; break; }
done
limine_bin=""
for c in /usr/bin/limine /tmp/limine-pkg/usr/bin/limine; do
	[ -x "$c" ] && { limine_bin=$c; break; }
done
[ -n "$limine_share" ] && [ -n "$limine_bin" ] || { echo "limine not found" >&2; exit 1; }

root=$work/iso_root
staged=$work/staged
rm -rf "$root" "$staged"
mkdir -p "$root/boot/limine" "$root/EFI/BOOT" "$root/bin/program" "$root/lib/modules" "$root/lib/firmware" "$staged"

python3 "$here/scripts/gen_assets.py" --root "$parent" --iso "$root" --staged "$staged" \
	--modules "$parent/bin/modules" --stage "$stage" --overlay "$here/profile/overlay" --compact

cp "$parent/bin/kernel/kernel-limine.elf" "$root/boot/kernel.elf"
cp "$parent/bin/kernel/kernel-fallback.elf" "$root/boot/kernel-fallback.elf"
[ -f "$parent/bin/kernel/kernel.map" ] && cp "$parent/bin/kernel/kernel.map" "$root/boot/kernel.map"
[ -d "$parent/bin/modules" ] && cp -r "$parent/bin/modules/"* "$root/lib/modules/" 2>/dev/null || true
cp "$limine_share/$efi" "$root/EFI/BOOT/$efi"
sh "$here/scripts/make_esp_image.sh" "$root" "$root/boot/esp.img"
cp "$staged/limine.conf" "$root/boot/limine/limine.conf"
cp "$staged/limine.conf" "$root/limine.conf"
cp "$limine_share/limine-bios.sys" "$limine_share/limine-bios-cd.bin" "$limine_share/limine-uefi-cd.bin" "$root/boot/limine/"
[ -f "$limine_share/BOOTIA32.EFI" ] && cp "$limine_share/BOOTIA32.EFI" "$root/EFI/BOOT/" || true

mkdir -p "$(dirname "$iso")"
xorriso -as mkisofs \
	-b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	--efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image \
	--protective-msdos-label "$root" -o "$iso"
"$limine_bin" bios-install "$iso"
echo "ISO created: $iso"
