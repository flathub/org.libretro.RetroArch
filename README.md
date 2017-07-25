# RetroArch on Flathub

[Flathub](https://flathub.org/) is the central place for building and hosting [Flatpak](http://flatpak.org/) builds.
Go to https://flathub.org/builds/ to see Flathub in action.

[RetroArch](http://retroarch.com) is a frontend for emulators, game engines and media players.

## Installation

To install RetroArch through Flathub, use the following:
```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install flathub org.libretro.RetroArch
```

## Usage

To run RetroArch through Flatpak, execute:
```
flatpak run org.libretro.RetroArch
```

### Options

Through the [Flatpak command line arguments](http://flatpak.org/flatpak/flatpak-docs.html), it is possible to change how RetroArch is used.

#### Mounted Directories

Allow Flatpak access to different mounted drives through using the `--filesystem` option:
```
flatpak run --filesystem=host --filesystem=/media/NAS/roms org.libretro.RetroArch
```
