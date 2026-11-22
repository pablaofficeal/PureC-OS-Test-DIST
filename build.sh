#!/bin/sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
parent=${1:-${PARENT:-$here/..}}
parent=$(cd "$parent" && pwd)
jobs=${JOBS:-$(nproc 2>/dev/null || echo 4)}
work=$here/staging
out=$here/out
name=${ISO_NAME:-purec-test-dist}
iso=$out/$name.iso

for py in /usr/bin/python3 /usr/bin/python; do
	if [ -x "$py" ] && "$py" -c 'import cryptography' 2>/dev/null; then
		mkdir -p "$here/staging/bin"
		ln -sf "$py" "$here/staging/bin/python3"
		PATH="$here/staging/bin:$PATH"
		export PATH
		break
	fi
done

for t in python3 xorriso limine make; do
	command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }
done

mkdir -p "$work" "$out"
rm -rf "$work/repo" "$work/stage" "$work/stage.conf"
mkdir -p "$work/repo"

cd "$parent"
make -j"$jobs" kernel programs
make -j"$jobs" chocolate-doom
make -C programs/purec-os-pkg host
make -C programs/PureC-OS-Core-Programs packages
make -C video-backend package
make -C PureC-OS-LibGui package
cp bin/video-backend/video-backend-*.pkg.tar.gz* bin/libgui/libgui-*.pkg.tar.gz* bin/core-repo/

for p in $(grep -v '^#' "$here/profile/packages.txt" | awk 'NF{print $1}'); do
	if ! line=$(grep "^$p " Trusted/repository.conf); then
		ls bin/core-repo/"$p"-[0-9]*.pkg.tar.gz >/dev/null 2>&1 && continue
		echo "package $p not in Trusted/repository.conf or bin/core-repo" >&2
		exit 1
	fi
	rel=$(echo "$line" | awk '{print $2}')
	cp "Trusted/$rel" "Trusted/$rel.sig" "$work/repo/"
done
for f in bin/core-repo/*.pkg.tar.gz; do
	base=$(basename "$f")
	pkg=${base%%-[0-9]*}
	if grep -qx "$pkg" "$here/profile/packages.txt"; then
		rm -f "$work/repo/$pkg"-[0-9]*.pkg.tar.gz*
		cp "$f" "$f.sig" "$work/repo/"
	fi
done

sh "$here/scripts/stage.sh" "$parent" "$work/repo" "$work/stage" "$parent/programs/purec-os-pkg/build/host/pkg"

for p in $(grep -v '^#' "$here/profile/packages.txt" | awk 'NF{print $1}'); do
	ls "$work/stage/var/lib/pkg/local" | grep -q "^$p-[0-9]" || { echo "package $p missing in staging" >&2; exit 1; }
done

sh "$here/scripts/mkiso.sh" "$parent" "$work/stage" "$work" "$iso"

ls -la "$iso"
