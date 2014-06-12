tresync
=======

Backup for files into two locations, one for full and one for iterative backups.

## SYNOPSIS

tresync from-directory to-directory [ destination-directory ]

## DESCRIPTION

tresync supports full and interative backups.

What distinguishes thie program is that it can do a complete backup to one
location (such as an external hard drive), and then do iterative backups to
other locations. To do a full recovery, one needs only to copy the full backup
and then apply each iteration on top of it.

Files that are backed up are copied and kept as regular files, as opposed to
being put into a compressed or archived file. This functionality means that
files in the backup are more accessible than in some backup programs, which
store backups in compressed or archived files.

This is a bare-bones program, and options are very limited.

### AUTHOR

Jeff Pace (jeugenepace at gmail dot com)

http://www.github.com/jpace/tresync
