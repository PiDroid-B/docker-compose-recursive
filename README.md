# docker-compose-recursive

State : beta/developpment

**use it at your own risk**

A little script as like as a bulk manager to use with several docker-compose files.

## Features

- Run, Stop a tree of docker-compose.yml
- Stop'n'Run to force a full reload
- Each docker-compose.yml can be managed/unmanaged just with an empty file "OK"
- External conf file can be used to order the Run and Stop (Stop is inverted)
- Single command to prune all unused images/volumes/networks
- installer/updater for docker-compose (read the help before use)

## Help

`./dcr.sh -h`
```bash

manage a tree of docker-compose :
        default only dir with 'OK' file can be managed (or use the 'force' option)
        conf file dcr.sh.conf is used is exist to manage the tree (can be define too by -c)

dcr.sh
├── stack1
│   ├── docker-compose.yml
│   ├── .env
│   └── OK
└── stack2
    └── docker-compose.yml

Usage : dcr.sh [ACTION] [OPTION]

ACTION
        -h               Help : show this help
        -u               Up : builds, (re)creates, starts, and attaches to containers for each docker-compose
        -d               Down : stops containers and removes containers, networks, volumes, and images created by up
        -r               Restart : Down and Up on each docker-compose
        -p               Prune : remove unsed images, volumes and networks
        -i               Install/Update : check if new versions of docker-compose and dcr exist (autoupdate for docker-compose if force)
OPTION
        -f               Force : no check of 'OK' file (udr), auto install/upgrade (i)
        -c <file>        Conf file : get list of folder from file instead of generate it
        -v               Verbose : show more information

        /!\ use force only if you are sure what you do
        use this script at your own risk

some usefull commands :

generate conf file from running docker-compose :
  docker compose ls | cut -f1 -d" " | sed "1d" > myfile.conf


```

## Todo (maybe)

- installer/updater
- manage default conf file in `/etc/` and/or `/usr/local/etc`
- add version number management
