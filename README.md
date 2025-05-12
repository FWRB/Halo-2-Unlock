# Halo 2 Unlock
This repository contains patches for the Halo 2 Alpha and Beta builds to unlock menus and restore system link functionality. 

The patches for the Halo 2 Alpha/Beta builds contain the following changes:
- Updates executable display name to "Halo 2 Alpha" and "Halo 2 Beta".
- Restores main menu functionality so sub-menus can be accessed.
- Bypasses Xbox Live requirements.
- Allows 4 players to sign in simultaneously.
- Unlocks all game types and match settings.
- Restores system link functionality.
- Disables data mining.
- Optionally enables debug output.

## Installation
You can find precompiled versions of the patches in the releases section. You'll need [XDelta](https://www.romhacking.net/utilities/598/) to apply the patch files to the clean alpha/beta executable files. They should have the following SHA1 hashes:
- Halo 2 Alpha default.xbe: 43A1B01EB741DDEC7968FBD2240A938526655206
- Halo 2 Beta TU 1 default.xbe: 80F3BF79E60D7F08A9BEFC8866BF626324142D5D
- Halo 2 Beta TU 2 default.xbe: F2A79EC5602B210D8AE33FF2600B5AABA9093DB4
- Halo 2 Beta TU 3 default.xbe: AF4C19C73DFF53677744F3359A2A7B16A236187C
- Halo 2 Beta TU 4 default.xbe: D496B362910D00C1D9271CD4489B512203DDFC24

To apply the patch run XDelta UI and select patch file and default.xbe file for the version of the game you want to patch. Halo 2 Alpha should use the H2AlphaUnlock.xdelta patch and default.xbe file from the game files. Halo 2 Beta should use the H2BetaUnlock.xdelta patch and default.xbe from the title update 3 content package. Once the patch is applied copy the output xbe file to your Xbox console alongside the other game files.

## Xbox 360 Compatibility
The patches are designed to be compatible with the Xbox 360 back-compat emulator but may still experience some issues from time to time. It's recommended to use the v2.0.5829.0 (or newer) version of the back-compat emulator for best results, earlier versions may cause crashes when trying to load a map. To check the version of the back-compat emulator you can run the following XexTool command on the xbox.xex file found in the Compatibility partition of your console's HDD: 

`XexTool.exe xbox.xex` 

The execution ID version should read at least v2.0.5829.0 or newer:
```XexTool.exe xbox.xex
XexTool v6.6  -  xorloser 2006-2013 (Build Mon Sep 23 14:56:21 2013)
Reading and parsing input xex file...

...

Execution Id
  Media Id:           00000000
  Title Id:           FFFE07D2
  Savegame Id:        00000000
  Version:            v2.0.5829.0
  Base Version:       v2.0.5829.0
  Platform:           0
  Executable Type:    0
  Disc Number:        0
  Number of Discs:    0
```

## Compiling
To compile the patches from scratch you'll need [XePatcher](http://icode4.coffee/files/XePatcher_3.0.zip) and [XboxImageExploder v1.2](https://github.com/grimdoomer/XboxImageXploder) or newer. You should only need to compile the patches from scratch if you want to make changes or enable the debug output feature. 

The first step is to create a new code segment in the clean xbe file. This can be done with XboxImageXploder using the following command:

`XboxImageXploder.exe <xbe file> .hacks 8192`

You'll need to check the output and make sure the base address and offset for the .hacks segment match the values in the corresponding patch file. For example, the output from XboxImageXploder for the Halo 2 Alpha should match the following:

```
Section Name:           .hacks
Virtual Address:        0x00abd000
Virtual Size:           0x00002000
File Offset:            0x0048e000
File Size:              0x00002000

Successfully added new section to image!
```

The values for Virtual Address and File Offset must match the HacksSegmentAddress and HacksSegmentOffset values in the H2AlphaUnlock patch file:

```
; .hacks segment info:
%define ExecutableBaseAddress           00010000h           ; Base address of the executable
%define HacksSegmentAddress             00abd000h           ; Virtual address of the .hacks segment
%define HacksSegmentOffset              0048e000h           ; File offset of the .hacks segment
%define HacksSegmentSize                00002000h           ; Size of the .hacks segment
```

If they don't the values in the patch file will need to be updated.

Next the patch file can be compiled using XePatcher and applied to the expanded xbe file using the following command:

`XePatcher.exe" -p <h2_unlock.asm> -proc x86 -bin <expanded xbe file> -o <output xbe file>`

Where `<h2_unlock.asm>` is the full file path to the H2AlphaUnlock.asm or H2BetaUnlock.asm file, `<expanded xbe file>` is the xbe file produce in the previous step, and `<output xbe file>` is where the patched xbe file will be saved to. The output xbe file path must be different from the expanded xbe file path. If any errors occurred during compilation they will be printed out and must be fixed. If no errors are printed then the patch was compiled and applied successfully.
