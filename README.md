# docker-machine-unison

Docker machine mounts files with vboxsf. It is very slow and the main issue:
  - file watching is broken, that many build tools relay on.

The solution: umount everything and use unison to sync instead.

TODO: Finish this


