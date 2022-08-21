# docker-compose-recursive

State : Beta/Development

**Use it at your own risk**

A script to bulk manage several docker-compose files.

## Features

- Run or Stop a tree of docker-compose.yml
- Stop and Run to force a full reload
- Each docker-compose.yml can be managed/unmanaged just with an "OK" empty file next to it
- External conf file can be used to order the Run and Stop (Stop is inverted)
- Single command to prune all unused images/volumes/networks
- installer/updater for docker-compose (read the help before use)

## Help

`./dcr.sh -h`
```bash

Manage a tree of docker-compose :
        By default, only dir with 'OK' file can be managed (otherwise, use the 'force' option)
        dcr.sh.conf is used, if existing, to manage the tree (can be defined with -c)

dcr.sh
├── stack1
│   ├── docker-compose.yml
│   ├── .env
│   └── OK
└── stack2
    └── docker-compose.yml

Usage : dcr.sh [ACTION] [OPTION]

ACTION
        -h               Help : Show help
        -u               Up : Build, (re)create, start and attach containers for each docker-compose
        -d               Down : Stop and remove containers, networks, volumes and images created
        -r               Restart : Run a Down and Up on each docker-compose
        -p               Prune : Remove unused images, volumes and networks
        -i               Install/Update : Check if a new version of docker-compose and dcr exist (autoupdate for docker-compose if force)
OPTION
        -f               Force : Ignore 'OK' files (udr), auto install/upgrade (-i)
        -c <file>        Conf file : Get the list of folders from file instead of generate it
        -v               Verbose : Show more information

        /!\ Use -f (force) only if you know what you are doing, using this script is at your own risk

Some useful commands:

Generate conf file from running docker-compose:
  docker compose ls | cut -f1 -d" " | sed "1d" > myfile.conf


```

## ToDo (maybe)

- installer/updater
- manage default conf file in `/etc/` and/or `/usr/local/etc`
- add version number management
