# Windows Services Profiles
#
# Copyright 2021 Raphael Doursenaud <rdoursenaud@gmail.com>
#
# Selectively suspend and resume services based on profiles/modes
#

###
# Arguments
###

param(
    [Parameter(Mandatory = $true)] $Mode = ""
)


Set-StrictMode -Version 'latest'
#Requires -RunAsAdministrator

###
# Useful debugging commands
###

#Get-Service | Where { $_.Status -eq "Stopped" } | Format-Table Name | Out-Host -Paging
#Get-Service | Where { $_.Status -eq "Running" } | Format-Table Name | Out-Host -Paging
#Get-Service | Where { $_.Name -like "StartWith*" } | Format-Table Name

###
# Constants
###

# Resource intensive services
$hogs = @(
,'DSAService'
,'DSAUpdateService'
,'Intel(R) PROSet Monitoring Service'
,'Jackett'
,'JTAGServer'
,'LeapService'
,'MullvadVPN'
,'OVRLibraryService'  # FIXME: this is a tough cookie. Might need to kill him.
,'OVRService'
,'PaceLicenseDServices'
,'Presonus Hardware Access Service'
,'rtpMIDIService'
,'Shibari.Dom.Server'
,'Synergy'
,'vorpX Service'
)

$stan_required = @(
,'NIHardwareService'
,'NIHostIntegrationAgent'
,'PaceLicenseDServices'
,'Presonus Hardware Access Service'
,'rtpMIDIService'
,'TbtHostControllerService'
)

$game_required = @(
,'Shibari.Dom.Server'
)

$dev_required = @(
,'JTAGServer'
#,'kite'
)

$vr_required = @(
,'OVRLibraryService'
,'OVRService'
)

$ar_required = $vr_required + @(
,'LeapService'
)

$vrgame_required = $vr_required + @(
,'vorpX Service'
)

$leisure_required = @(
,'Jackett'
,'MullvadVPN'
,'Synergy'
)

$modes = @(
,'AR'
,'DEV'
,'GAME'
,'LEISURE'
,'STAN'
,'VR'
,'VRGAME'
)

$modes_required = @{ }

$modes_required.Add('AR', $ar_required)
$modes_required.Add('DEV', $dev_required)
$modes_required.Add('GAME', $game_required)
$modes_required.Add('LEISURE', $leisure_required)
$modes_required.Add('STAN', $stan_required)
$modes_required.Add('VR', $vr_required)
$modes_required.Add('VRGAME', $vrgame_required)

###
# Functions
###

function Help
{
    Write-Host "Usage: wsp.ps -Mode [ModeName]}"
    Write-Host ""
    Write-Host "Available modes: $modes"
}

function Stop-Services
{
    param (
        $ServicesList
    )

    Write-Host "Stopping:"

    foreach ($Service in $ServicesList)
    {
        If (Get-Service $Service | Where { $_.Status -eq "Running" -or $_.Status -eq "Paused"})
        {

            Write-Host "- $Service"

            try
            {
                Stop-Service $Service -ErrorAction Stop
            }
            catch
            {
                Write-Host "`tService $Service cannont be stopped. Trying to suspend it."

                Suspend-Service $Service
            }
        }
    }
}

function Start-Services
{
    param (
        $ServicesList
    )

    Write-Host "Starting:"

    foreach ($Service in $ServicesList)
    {
        Write-Host "- $Service"

        If (Get-Service $Service | Where { $_.Status -eq "Stopped" })
        {
            Start-Service $Service
        }
        elseif (Get-Service $Service | Where { $_.Status -eq "Paused" })
        {
            Resume-Service $Service
        }

    }
}

####
# Main
####

If ($Mode -eq "")
{
    Help
}
ElseIf ($modes.Contains($Mode))
{
    Write-Host "WIP"
    $required = $modes_required[$Mode]
    $stop = Compare-Object -ReferenceObject $hogs -DifferenceObject $required -PassThru
    Stop-Services($stop)
    Start-Services($required)
}
Else
{
    Write-Error "Unknown mode: $Mode"
    Help
}