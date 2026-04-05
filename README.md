# NixOS AArch64

Personal NixOS Image for AArch64 machines.

Forked this from [5aaee9](https://github.com/5aaee9/nixos-aarch64), edited it so it will be more focused on Orange Pi 3B.

## Device supported

| Device                                                                                                          | Uboot | Kernel | Boot             | Chipset        |
|-----------------------------------------------------------------------------------------------------------------|-------|--------|------------------|----------------|
| ~~[BigTreeTech Pi](https://biqu.equipment/products/bigtreetech-btt-pi-v1-2)~~                                   | ❌    | ✅    | ✅               | Allwinner H616 |
| ~~[Fly Gemini V3](https://item.taobao.com/item.htm?id=661670024975)~~                                           | ✅    | ✅    | ✅               | Allwinner H5   |
| [Orange Pi 3B](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-3B.html)     | ✅    | ✅    | ✅               | RK3566         |
| ~~[Panther X2](https://panther.global)~~                                                                        | ✅    | ✅    | ✅               | RK3566         |

### Prerequisites

- an `x86_64-linux` machine
- Nix with `nix-command` and `flakes` enabled

## Quickstart (for OPi 3B)

- Build the image:
```bash
nix build .#orangepi-3b-image --extra-experimental-features 'nix-command flakes'
```

That alias resolves to the existing `sdimage-orangepi-3b` output and produces the SD image in `./result`.
