$commandname = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\..\constants.ps1"
#. "$PSScriptRoot\..\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-ChildItem Function:\New-PSDCClone).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'PSDCSqlCredential', 'Credential', 'ParentVhd', 'Destination', 'CloneName', 'Database', 'LatestImage', 'Disabled', 'Force', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $knownParameters.Count
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {

    BeforeAll {
        Write-PSFMessage -Level Important -Message $script:clonefolder

        if (-not (Test-Path -Path $script:clonefolder)) {
            New-Item -Path $script:clonefolder -ItemType Directory
        }

        Set-PSDCConfiguration -InformationStore File -Path $script:clonefolder -Force


    }

    AfterAll {

    }

}