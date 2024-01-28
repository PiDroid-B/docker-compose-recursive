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


## Install (Debian)

**Prerequisites/information :**
- user root needed
- symbolic link in /usr/local/bin/ can be named as what you want

### git clone
```bash
cd /opt

git clone https://github.com/PiDroid-B/docker-compose-recursive

ln -s /opt/docker-compose-recursive/docker-compose-recursive.sh /usr/local/bin/dcr
chmod 700 /opt/docker-compose-recursive/docker-compose-recursive.sh
```

### wget
```bash
mkdir /opt/docker-compose-recursive
cd /opt/docker-compose-recursive

wget https://raw.githubusercontent.com/PiDroid-B/docker-compose-recursive/main/docker-compose-recursive.sh

ln -s /opt/docker-compose-recursive/docker-compose-recursive.sh /usr/local/bin/dcr
chmod 700 /opt/docker-compose-recursive/docker-compose-recursive.sh
```

### wget (development version)
```bash
mkdir /opt/docker-compose-recursive
cd /opt/docker-compose-recursive

wget https://raw.githubusercontent.com/PiDroid-B/docker-compose-recursive/dev/docker-compose-recursive.sh

ln -s /opt/docker-compose-recursive/docker-compose-recursive.sh /usr/local/bin/dcr
chmod 700 /opt/docker-compose-recursive/docker-compose-recursive.sh
```

## Autocompletion (Debian)
```bash
cd /tmp/
wget https://raw.githubusercontent.com/PiDroid-B/docker-compose-recursive/main/bash-autocompletion

sed -i "s/@@MYAPP@@/dcr/g" bash-autocompletion
mv bash-autocompletion /etc/bash_completion.d/docker-compose-recursive
```

## Autocompletion (Debian - development version)
```bash
cd /tmp/
wget https://raw.githubusercontent.com/PiDroid-B/docker-compose-recursive/dev/bash-autocompletion

sed -i "s/@@MYAPP@@/dcr/g" bash-autocompletion
mv bash-autocompletion /etc/bash_completion.d/docker-compose-recursive
```

## Help

`dcr -h`
```bash
docker-compose-recursive.sh - version v0.3.2

Manage a tree of docker-compose :
        By default, only dir with 'OK' file can be managed (otherwise, use the 'force' option)
        dcr.sh.conf is used, if existing, to manage the tree (can be defined with -c)

dcr
├── stack1
│   ├── docker-compose.yml
│   ├── .env
│   └── OK
└── stack2
    └── docker-compose.yml

Usage : dcr [FOLDER] <ACTION> [OPTION]

FOLDER
         apply only to this folder (apply on all folder if missing)

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

https://github.com/PiDroid-B/docker-compose-recursive MIT ©2022 PiDroid-B 
```
### Usage

##### Show the help
`dcr -h`

##### show if new versions of docker-compose and docker-compose-recursive are available
`dcr my_folder -i`

##### install/update docker-compose and show if new docker-compose-recursive is available
`dcr my_folder -i -f`

##### List visible folder (go to #Configuration file for more information)
`dcr -c`

##### docker compose up -d on all folder
`dcr -u`

##### docker compose down for only one folder
`dcr my_folder -d`


## Configuration file

Directories are managed with the first configuration found below :
- file given by `-c`
- file /usr/local/etc/docker-compose-recursive/directories.conf
- file /etc/docker-compose-recursive/directories.conf
- file /opt/docker-compose-recursive/directories.conf
- on demand on the current directory


## ToDo (maybe)

- installer/updater
- dcr -i bash_completion | sudo tee /etc/bash_completion.d/docker-compose-recursive
