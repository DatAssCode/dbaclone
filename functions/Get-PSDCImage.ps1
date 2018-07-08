﻿function Get-PSDCImage {
    <#
    .SYNOPSIS
        Get-PSDCImage get on or more clones

    .DESCRIPTION
        Get-PSDCImage will retrieve the clones and apply filters if needed.
        By default all the clones are returned

    .PARAMETER SqlCredential
        Allows you to login to servers using SQL Logins as opposed to Windows Auth/Integrated/Trusted. To use:

        $scred = Get-Credential, then pass $scred object to the -SqlCredential parameter.

        Windows Authentication will be used if SqlCredential is not specified. SQL Server does not accept Windows credentials being passed as credentials.
        To connect as a different Windows user, run PowerShell as that user.

    .PARAMETER PSDCSqlCredential
        Allows you to login to servers using SQL Logins as opposed to Windows Auth/Integrated/Trusted.
        This works similar as SqlCredential but is only meant for authentication to the PSDatabaseClone database server and database.

    .PARAMETER ImageID
        Filter based on the image id

    .PARAMETER ImageName
        Filter based on the image name

    .PARAMETER ImageLocation
        Filter based on the image location

    .PARAMETER Database
        Filter based on the database

    .NOTES
        Author: Sander Stad (@sqlstad, sqlstad.nl)

        Website: https://psdatabaseclone.io
        Copyright: (C) Sander Stad, sander@sqlstad.nl
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://psdatabaseclone.io/

    .EXAMPLE
        Get-PSDCImage -ImageName DB1_20180704220944, DB2_20180704221144

        Retrieve the images for DB1_20180704220944, DB2_20180704221144

    .EXAMPLE
        Get-PSDCImage -ImageLocation "\\fileserver1\psdatabaseclone\images\DB1_20180704220944.vhdx"

        Get all the images that are the same as the image location

    .EXAMPLE
        Get-PSDCImage -Database DB1, DB2

        Get all the images that were made for databases DB1 and DB2
    #>

    [CmdLetBinding()]

    param(
        [System.Management.Automation.PSCredential]$SqlCredential,
        [System.Management.Automation.PSCredential]
        $PSDCSqlCredential,
        [int[]]$ImageID,
        [string[]]$ImageName,
        [string[]]$ImageLocation,
        [string[]]$Database
    )

    begin {
        # Test the module database setup
        try {
            Test-PSDCConfiguration -SqlCredential $PSDCSqlCredential -EnableException
        }
        catch {
            Stop-PSFFunction -Message "Something is wrong in the module configuration" -ErrorRecord $_ -Continue
        }

        $pdcSqlInstance = Get-PSFConfigValue -FullName psdatabaseclone.database.server
        $pdcDatabase = Get-PSFConfigValue -FullName psdatabaseclone.database.name

        $query = "
            SELECT ImageID,
                ImageName,
                ImageLocation,
                SizeMB,
                DatabaseName,
                DatabaseTimestamp,
                CreatedOn
            FROM dbo.Image;
        "

        try {
            $results = @()
            $results += Invoke-DbaSqlQuery -SqlInstance $pdcSqlInstance -SqlCredential $PSDCSqlCredential -Database $pdcDatabase -Query $query -As PSObject
        }
        catch {
            Stop-PSFFunction -Message "Could retrieve images from database $pdcDatabase" -ErrorRecord $_ -Target $query
        }

        # Filter image id
        if ($ImageID) {
            $results = $results | Where-Object {$_.ImageID -in $ImageID}
        }

        # Filter image name
        if ($ImageName) {
            $results = $results | Where-Object {$_.ImageName -in $ImageName}
        }

        # Filter image location
        if ($ImageLocation) {
            $results = $results | Where-Object {$_.ImageLocation -in $ImageLocation}
        }

        # Filter database
        if ($Database) {
            $results = $results | Where-Object {$_.DatabaseName -in $Database}
        }
    }

    process {
        # Test if there are any errors
        if (Test-PSFFunctionInterrupt) { return }

        # Convert the results to the PSDCClone data type
        foreach ($result in $results) {

            [pscustomobject]@{
                ImageID           = $result.ImageID
                ImageName         = $result.ImageName
                ImageLocation     = $result.ImageLocation
                SizeMB            = $result.SizeMB
                DatabaseName      = $result.DatabaseName
                DatabaseTimestamp = $result.DatabaseTimestamp
                CreatedOn         = $result.CreatedOn
            }

        }

    }

    end {
        # Test if there are any errors
        if (Test-PSFFunctionInterrupt) { return }

        Write-PSFMessage -Message "Finished retrieving image(s)" -Level Verbose
    }
}