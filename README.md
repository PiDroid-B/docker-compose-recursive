# docker-compose-recursive

State : beta/developpment

A little script as like as a bulk manager to use with several docker-compose files.

## Features

- Run, Stop a tree of docker-compose.yml
- Stop'n'Run to force a full reload
- Each docker-compose.yml can be managed/unmanaged just with an empty file "OK"
- External conf file can be used to order the Run and Stop (Stop is inverted)
- Single command to prune all unused images/volumes/networks

## Help

`./dcr.sh -h`
```bash

manage a tree of docker-compose :
        default only dir with OK file can be managed (or use the 'force' option)
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
        -u               Up : run docker compose on each file (default)
        -d               Down : stop docker compose on each file
        -r               Restart : stop and run docker compose on each file
        -p               Prune : remove unsed images, volumes and networks
OPTION
        -f               Force : do it without checking of OK file
        -c <file>        Conf file : get list of folder from file instead of generate it
        -v               Verbose : show more information

some usefull commands :

generate conf file from running docker-compose :
  docker compose ls | cut -f1 -d  | sed 1d > myfile.conf

```

## Todo (maybe)

- installer/updater
- installer/updater for docker-compose
- manage default conf file in `/etc/` and/or `/usr/local/etc`
- add version number management
