# RetroArch on Flathub

[Flathub](https://flathub.org/) is the central place for building and hosting [Flatpak](http://flatpak.org/) builds.
Go to https://flathub.org/builds/ to see Flathub in action.

[RetroArch](http://retroarch.com) is a frontend for emulators, game engines and media players.

## Installation

To install RetroArch through Flathub, use the following:
```
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.libretro.RetroArch
```

## Run

To run RetroArch through Flatpak, execute:
```
flatpak run org.libretro.RetroArch
```

## Update

To update RetroArch through Flathub, use the follow command:
```
flatpak update --user org.libretro.RetroArch
```

### Options

Through the [Flatpak command line arguments](http://flatpak.org/flatpak/flatpak-docs.html), it is possible to change how RetroArch is used.

#### Mounted Directories

Allow Flatpak access to different mounted drives through using the `--filesystem` option:
```
flatpak run --filesystem=host --filesystem=/media/NAS/roms org.libretro.RetroArch
```

## Development

To test the application locally, use [flatpak-builder](http://docs.flatpak.org/en/latest/flatpak-builder.html) with:
```
git clone https://github.com/flathub/org.libretro.RetroArch.git
cd org.libretro.RetroArch
git submodule update --init
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.kde.Sdk//5.9
flatpak install --user flathub org.kde.Platform//5.9
flatpak-builder --repo=libretro --force-clean retroarch org.libretro.RetroArch.json
flatpak remote-add --user libretro libretro --no-gpg-verify
flatpak install --user libretro org.libretro.RetroArch
flatpak run org.libretro.RetroArch --verbose
```

### Clean

```
flatpak uninstall --user org.libretro.RetroArch
rm -rf ~/.var/app/org.libretro.RetroArch
flatpak remote-delete libretro
```
