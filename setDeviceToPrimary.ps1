foreach ($Device in $Devices) { 
    Write-Host "Device name:" $device."deviceName" -ForegroundColor Cyan
    $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -deviceId $Device.id

    # Check if there is a Primary user set on the device already
    if ($IntuneDevicePrimaryUser -eq $null) {
        Write-Host "No Intune Primary User Id set for Intune Managed Device" $Device."deviceName" -f Red 
    } else {
        $PrimaryAADUser = Get-AADUser -userPrincipalName $IntuneDevicePrimaryUser
        Write-Host "Intune Device Primary User:" $PrimaryAADUser.displayName
    }

    # Get the objectID of the last logged-in user for the device
    $LastLoggedInUser = ($Device.usersLoggedOn[-1]).userId

    # Using the objectID, get the user from the Microsoft Graph for logging purposes
    $User = Get-AADUser -userPrincipalName $LastLoggedInUser

    # Check if the current primary user of the device is the same as the last logged-in user
    if ($User.id -is [System.Guid]) {
        if ($IntuneDevicePrimaryUser -notmatch $User.id) {
            # If the user does not match, then set the last logged-in user as the new Primary User
            $SetIntuneDevicePrimaryUser = Set-IntuneDevicePrimaryUser -IntuneDeviceId $Device.id -userId $User.id
            if ($SetIntuneDevicePrimaryUser -eq "") {
                Write-Host "User '$($User.displayName)' set as Primary User for device '$($Device.deviceName)'" -ForegroundColor Green
            }
        } else {
            # If the user is the same, then write to host that the primary user is already correct.
            Write-Host "The user '$($User.displayName)' is already the Primary User on the device." -ForegroundColor Yellow
        }
    } else {
        # If the user ID is not in the form of a GUID, skip setting the primary user
        Write-Host "Skipping setting primary user. User ID '$($User.id)' is not in the correct format." -ForegroundColor Yellow
    }

    Write-Host
}
