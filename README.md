# WSP

Windows Services Profiles

## How to use

**For the time being, please edit the script to make the profiles yours.**

*Future versions may come with separate configuration files.*

1. Check the `Useful debugging commands` section to help you list the services currently available on your machine.
2. Edit `$hogs` to list the services you want to manage.
3. Edit `$profiles` to your liking.
4. Update the accompanying variables to specify required services.
5. Test switching profiles manually (See Help).
6. Create convenient Start Menu shortcuts (See Help).
7. Use the Start Menu shortcuts to switch profiles depending on what you do and hopefully enjoy an optimized experience.

## Help

### SYNOPSIS

A PowerShell script to selectively stop/suspend and start/resume services based on profiles.

### DESCRIPTION

The `WSP.ps1` script switches services profiles and optionally creates Start Menu shortcuts to easily target these
profiles.

The goal is to only run required services for each activity to limit unwanted resources usage by mundane services or
prevent conflicts.

### PARAMETER Profile

A profile identifier. The special profile 'CS' creates/updates global Start Menu shortcuts to this script for each
profile. Left empty it prints out the help.

### INPUTS

None. You cannot pipe objects to `WSP.ps1`.

### OUTPUTS

None. `WSP.ps1` does not generate output and merely prints services actions.

### EXAMPLES

```powershell
.\WSP.ps1 GAME
```

Switches to the gaming profile.

```powershell
.\WSP.ps1 CS
```

Creates global Start Menu shortcuts for each available profile.

### NOTES

Copyright 2021 Raphaël Doursenaud <rdoursenaud@free.fr>

License: Microsoft Public License (Ms-PL)

Uses `Get-SpecialFolderPath.ps1` from https://github.com/beatcracker/Powershell-Misc
