# WSP

Windows Services Profiles

## SYNOPSIS

A PowerShell script to selectively stop/suspend and resume services based on profiles.

## DESCRIPTION

The WSP.ps1 script switches services profiles and optionnally creates Start Menu shortcuts to easily target these
profiles. The goal is to only run required services for each activity to limit unwanted resources usage by mundane
services or prevent conflicts.

## PARAMETER Profile

A profile identifier. The special profile 'CS' creates/updates global Start Menu shortcuts to this script for each
profile. Left empty it prints out the help.

## INPUTS

None. You cannot pipe objects to WSP.ps1.

## OUTPUTS

None. WSP.ps1 does not generate output and merely prints stopped/suspended/resumed services.

## EXAMPLES

```powershell
.\WSP.ps1 GAME
```

Switches to the gaming profile.

```powershell
.\WSP.ps1 CS
```

Creates global shortcuts for each available profile.

## NOTES

Copyright 2021 Raphaël Doursenaud <rdoursenaud@gmail.com>

License: Microsoft Public License (Ms-PL)

Uses Get-SpecialFolderPath.ps1 from https://github.com/beatcracker/Powershell-Misc
