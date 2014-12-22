$target = "user@192.168.200.29:/mnt/Backup/user/computer"
$mailto = "someone@example.local"
$mailfrom = "Administrator@localhost"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
[Environment]::SetEnvironmentVariable("CYGWIN", "nodosfilewarning", "Process")
$rsync = Join-Path -Path $scriptDir -ChildPath cwRsync\rsync.exe
$ssh = Join-Path -Path $scriptDir -ChildPath cwRsync\ssh.exe
$keygen = Join-Path -Path $scriptDir -ChildPath cwRsync\ssh-keygen.exe
$sshdir = Join-Path -Path $scriptDir -ChildPath .ssh
$sshkey = Join-Path -Path $scriptDir -ChildPath .ssh\id_rsa
$sshknown = Join-Path -Path $scriptDir -ChildPath .ssh\known_hosts
$sshknown = ".\.ssh\known_hosts"
$log = Join-Path -Path $scriptDir -ChildPath rsyncbackup.log
$err = Join-Path -Path $scriptDir -ChildPath rsyncbackup_err.log

# check if rsync is installed
If (!(Test-Path $rsync)) {
    "Please download cwRsync from https://www.itefix.net/content/cwrsync-free-edition"
    "and make sure {0} exists." -f $rsync
    Exit
}

# check if SSH key has been generated
If (!(Test-Path $sshkey)) {
    "Generating SSH key"
    if (!(Test-Path $sshdir)) {
        New-Item $sshdir -type directory
    }
    & $keygen "-t" "rsa" "-f" $sshkey "-N" '""'
}

$shadow = get-wmiobject win32_shadowcopy
"There are {0} shadow copies on this system" -f $shadow.count

# create shadow copy
$class=[WMICLASS]"root\cimv2:win32_shadowcopy"
$sc = $class.create("C:\", "ClientAccessible")
If ($sc.ReturnValue -ne 0) {
    "Shadow copy failed"
    $sc
}
Else
{
    "Shadow copy {0} created" -f $sc.ShadowID
    $shadow = get-wmiobject win32_shadowcopy
    "There are now {0} shadow copies on this system" -f $shadow.count
    
    If ((Get-Random -Maximum 30) -eq 0) {
        "Running checksummed backup"
        $checksum = "--checksum"
    }
    Else {
        $checksum = "--no-checksum"
    }
    
    # run rsync
    Get-WmiObject Win32_Shadowcopy | ForEach-Object {
        If ($_.ID -eq $sc.ShadowID) { 
            "Device object: {0}" -f $_.DeviceObject
            #$source = $_.DeviceObject -replace "\\", "/"
            $source = "/proc/sys/Device/" + $_.DeviceObject.Split("\\")[-1] + "/"
            Start-Process -filepath $rsync -NoNewWindow -Wait `
                -RedirectStandardOutput "rsyncbackup.log" -RedirectStandardError "rsyncbackup_err.log" `
                -argumentList @(
                "-v", "--stats",                "--recursive", "--links", "--times", $checksum,
                "--delete", "--delete-excluded", "--inplace",
                "-e", "'`"$ssh`" -o passwordauthentication=no -o stricthostkeychecking=no -i `"$sshkey`" -o UserKnownHostsFile=`"$sshknown`" -F /dev/null'",                "--exclude='`$RECYCLE.BIN'",
                "--exclude='System Volume Information'",
                "--exclude=hiberfil.sys",
                "--exclude=pagefile.sys",
                "--exclude=RECYCLER",
                "--exclude='Temp/*'",
                "--exclude=Thumbs.db",
                "--exclude='Temporary Internet Files/*'",
                "--exclude='Lokale Einstellungen/Anwendungsdaten/Mozilla'",
                "--exclude='iTunes Music/Downloads'",
                "--exclude='iTunes Music/Podcasts'",
                "--exclude='iPod Photo Cache'",
                "--exclude='TomTom/HOME/Backup'",
                "--exclude='AppData/Local/*'",
                "--exclude=DVDRip",
                "--exclude=Config.Msi",
                "--exclude=`$Recycle.Bin",
                "--exclude='* Previews.lrdata'",
                "--exclude='MSOCache/*'",
                "$source/",
                "$target/C")
        }
    }
}

# delete shadow copy
Get-WmiObject Win32_Shadowcopy | ForEach-Object {
    If ($_.ID -eq $sc.ShadowID) { 
        "Shadow copy {0} deleted" -f $sc.ShadowID
        $_.Delete() 
    } 
}

$shadow = get-wmiobject win32_shadowcopy
"There are now {0} shadow copies on this system" -f $shadow.count

# Send email notification
if((Get-Item $err).length -gt 0 -Or (Get-Random -Maximum 10) -eq 0)
{
    $message1 = Get-Content $log | Select-Object -last 30
    $message2 = Get-Content $err
    
    "Sending message: $message1`n`n`n$message2"
    Send-Mailmessage `        -To $mailto `
        -Subject "rsyncbackup $target" `        -From $mailfrom `        -Body "$message1`n`n`n$message2" `        -SmtpServer "mail"
}