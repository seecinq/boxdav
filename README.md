boxdav mounts your Box account via WebDAV
on a Linux machine.

Mount usage:   sudo boxdav [-b user@example.com]

Unmount usage: sudo boxdav -u [-b user@example.com]

The mount point will be: /mnt/boxdav/user@example.com
(Where user@example.com is your Box account.)

If the -b flag is not given, you will be prompted
to supply your Box login (email address).

NOTE: boxdav depends on davfs2 (http://savannah.nongnu.org/projects/davfs2).
You must install davfs2 before running boxdav.
