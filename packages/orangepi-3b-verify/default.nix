{ writeShellApplication
, coreutils
, diffutils
, findutils
, gnugrep
, zstd
, imagePackage
, kernelPackage
, ubootPackage
, dtbPath
, idbloaderSector
, uBootSector
,
}:

writeShellApplication {
  name = "verify-orangepi-3b";
  runtimeInputs = [
    coreutils
    diffutils
    findutils
    gnugrep
    zstd
  ];
  text = ''
    set -euo pipefail

    image_root="${imagePackage}"
    kernel_root="${kernelPackage}"
    uboot_root="${ubootPackage}"

    dtb_file="$(find "$kernel_root" -path "*/${dtbPath}" -print -quit)"
    if [ -z "$dtb_file" ]; then
      echo "missing DTB ${dtbPath} in $kernel_root" >&2
      exit 1
    fi

    idbloader="$uboot_root/idbloader.img"
    uboot_itb="$uboot_root/u-boot.itb"

    test -f "$idbloader"
    test -f "$uboot_itb"

    if [ -f "$image_root" ]; then
      image_file="$image_root"
    else
      image_file="$(find "$image_root" -type f \( -name '*.img' -o -name '*.img.zst' \) | sort | head -n 1)"
    fi

    if [ -z "''${image_file:-}" ]; then
      echo "unable to find built Orange Pi 3B image under $image_root" >&2
      exit 1
    fi

    if printf '%s\n' "$image_file" | grep -q '\.zst$'; then
      tmpdir="''${TMPDIR:-$(mktemp -d)}"
      decompressed="$tmpdir/orangepi-3b.img"
      zstd --decompress --stdout "$image_file" > "$decompressed"
      image_file="$decompressed"
    fi

    check_offset() {
      local expected="$1"
      local sector="$2"
      local label="$3"
      local size
      local offset

      size="$(stat -c %s "$expected")"
      offset="$(( sector * 512 ))"

      if ! dd if="$image_file" iflag=skip_bytes,count_bytes skip="$offset" count="$size" status=none | cmp -s - "$expected"; then
        echo "$label bytes do not match the image at sector $sector" >&2
        exit 1
      fi
    }

    check_offset "$idbloader" ${toString idbloaderSector} "idbloader.img"
    check_offset "$uboot_itb" ${toString uBootSector} "u-boot.itb"

    cat <<EOF
    Orange Pi 3B verification passed
    - DTB: $dtb_file
    - U-Boot defconfig artifact root: $uboot_root
    - Image: $image_file
    - idbloader.img sector: ${toString idbloaderSector}
    - u-boot.itb sector: ${toString uBootSector}
    EOF
  '';
}
