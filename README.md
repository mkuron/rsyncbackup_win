# README #

This is a script that performs Rsync backups from Windows to Unix servers. It sports the following advanced features:

* It creates volume shadow copies for consistent backups and backups of open files.
* It sends email notifications when a backup fails and on every 10th backup so you know it is still working. These email notifications contain the error messages and the transfer stats.
* It includes an XML file that can be imported into Windows' Scheduled Tasks.

### System Requirements ###

* Windows Vista and higher (tested on Windows 7 Professional and Windows 10 Pro)

### Installation ###

1. Clone this repository to *C:\Program Files (x86)\rsyncbackup*.
1. Open a `cmd` prompt with Administrator privileges.
1. Run `powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"`
1. Run `powershell.exe -File "C:\Program Files (x86)\rsyncbackup\rsyncbackup.ps1"`.
1. It will show you a link from where you need to download [cwRsync](https://www.itefix.net/content/cwrsync-free-edition). Extract the ZIP file and place its contents into *C:\Program Files (x86)\rsyncbackup\cwRsync*.
1. Run `powershell.exe -File "C:\Program Files (x86)\rsyncbackup\rsyncbackup.ps1"` again to generate the SSH key and do an initial backup.
1. Open the Windows Task Scheduler (`taskschd.msc`) with administrator privileges and import the XML file. The backup will then run at noon on weekdays and 6pm on weekends.
