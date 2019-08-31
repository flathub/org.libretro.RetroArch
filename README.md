# RetroArch on Flathub

[Flathub](https://flathub.org/) is the central place for building and hosting [Flatpak](http://flatpak.org/) builds. Go to https://flathub.org/builds/ to see Flathub in action.

[RetroArch](http://retroarch.com) is a frontend for emulators, game engines and media players.

## Installation

To install RetroArch through Flathub, use the following:
```
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub org.libretro.RetroArch
```

## Usage

1. Run RetroArch through Flatpak:
    ```
    flatpak run org.libretro.RetroArch
    ```

2. [Install some libretro cores](https://docs.libretro.com/guides/download-cores/) using the Online Updater. There is no need to update core info files, assets, joypad profiles, cheats, database, cg, glsl, or slang shaders, as those are shipped with the Flatpak.

3. [Import content](https://docs.libretro.com/guides/import-content/) by scanning the folder where your games are kept.

4. [Launch content](https://docs.libretro.com/guides/launch-content/) through RetroArch either through the menu, or through the command line:
    ```
    flatpak run org.libretro.RetroArch -L ~/.var/app/org.libretro.RetroArch/config/retroarch/cores/chailove_libretro.so FloppyBird.chailove
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
flatpak-builder builddir --install-deps-from=flathub --user --install --force-clean org.libretro.RetroArch.json
flatpak run org.libretro.RetroArch --verbose
```

### Clean

```
flatpak uninstall --user org.libretro.RetroArch
rm -rf ~/.var/app/org.libretro.RetroArch .flatpak-builder
```
