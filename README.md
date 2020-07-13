# BootList
## Graphical BootNext picker

I operate a multi-boot setup for various reasons. However, rebooting into a different operating system is not exactly an enthralling activity.

On Mac hardware, you can hold down the Option key at startup to launch a boot picker. But, in fact, this is the _only_ supported way to boot most standard UEFI firmware—macOS has a "startup disk" picker, but it can only detect installations of macOS and Windows, leaving our beloved Linux behind. BootList fills this gap by allowing you to select any entry in your EFI boot menu (stored in NVRAM) to boot from on the next reboot (by setting the `BootNext` variable in NVRAM).

## Requirements

BootList was hacked together as a quick'n'easy solution, so it relies on the wonderful [`bootoption`](https://github.com/bootoption/bootoption) command-line tool to do the heavy lifting. It should be installed in `/usr/local/bin`, e.g., 

    brew install bootoption

## Usage

Once the app is up and running, usage is simple as long as you know the rough layout of your boot menu. I recommend using `bootoption` proper to get more detailed information about this where appropriate.

## How it works

Boot menu entries are parsed from the output of `bootoption list`.

When you select to boot from an entry, a small snippet of AppleScript is used to elevate permissions (you will see a password dialog), as `root` access is required to write to NVRAM. The temporary shell process spawned by AppleScript runs `bootoption set -x <bootnum>` to set `BootNext` in NVRAM, which is read by the Mac bootloader as the default operating system on next boot. The system then reboots normally.

I built the GUI with SwiftUI, both as a learning opporunity and so that I get it done quickly. This means that, unfortunately, the app requires macOS 10.15 or later.
