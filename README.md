# README #

This is a script that performs Rsync backups from Windows to Unix servers. It sports the following advanced features:

* It creates volume shadow copies for consistent backups and backups of open files.
* It sends email notifications when a backup fails and on every 10th backup so you know it is still working. These email notifications contain the error messages and the transfer stats.
* It includes an XML file that can be imported into Windows' Scheduled Tasks.

### System Requirements ###

* Windows Vista and higher (tested on Windows 7 Professional, Windows 10 Pro, and Windows 11 Pro)

### Installation ###

1. Clone this repository to *C:\Program Files\rsyncbackup*.
1. Open a `cmd` prompt with Administrator privileges.
1. Run `powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"`
1. Run `powershell.exe -File "C:\Program Files\rsyncbackup\rsyncbackup.ps1"`
1. It will show you a link from where you need to download [cwRsync](https://www.itefix.net/content/cwrsync-free-edition). Get the x86 or x64 version, depending on what operating system architecture you are running. Extract the ZIP file and place the contents of the *bin* directory contained in it into *C:\Program Files\rsyncbackup\cwRsync*.
1. Run `powershell.exe -File "C:\Program Files\rsyncbackup\rsyncbackup.ps1"` again to generate the SSH key and do an initial backup.
1. Open the Windows Task Scheduler (`taskschd.msc`) with administrator privileges and import the XML file. The backup will then run at noon on weekdays and 6pm on weekends.

### Log files
Backed-up files are logged to *C:\Program Files\rsyncbackup\rsyncbackup.log*.
Errors are logged to *C:\Program Files\rsyncbackup\rsyncbackup_err.log*.

### ASLR exception needed on Windows 10

rsync (and other Cygwin binaries that call `fork()`) may have trouble with Windows 10's latest ASLR enhancements.
If you see error messages like these in rsyncbackup_err.log

	fatal error - "
	fatal error in forked process - fork: can't reserve memory for parent stack

then you need to add an ASLR exception:

1. Go to the Start menu and search for and open *Windows Defender Security Center*.
1. Select *App & browser control*.
1. Select *Settings for Exploit Protection*.
1. Go to the *Program settings* tab.
1. Add a new program by full path for both *rsync.exe* and *ssh.exe* in *C:\Programme\rsyncbackup\cwRsync*.
1. Check both *ASLR* options and set them to *Off* for both executables.
