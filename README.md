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


## Help

`dcr -h`
```bash
docker-compose-recursive.sh - version v0.2.0

manage a tree of docker-compose :
	default only dir with 'OK' file can be managed (or use the 'force' option)
	conf file docker-compose-recursive.sh.conf is used is exist to manage the tree (can be define too by -c)

docker-compose-recursive.sh
├── stack1
│   ├── docker-compose.yml
│   ├── .env
│   └── OK
└── stack2
    └── docker-compose.yml

Usage : docker-compose-recursive.sh [ACTION] [OPTION]

ACTION
	-h		 Help : show this help
	-u		 Up : builds, (re)creates, starts, and attaches to containers for each docker-compose
	-d		 Down : stops containers and removes containers, networks, volumes, and images created by up
	-r		 Restart : Down and Up on each docker-compose
	-p		 Prune : remove unsed images, volumes and networks
	-i		 Install/Update : check if new versions of docker-compose and dcr exist (autoupdate for docker-compose if force)
OPTION
	-f		 Force : no check of 'OK' file (udr), auto install/upgrade (i)
	-c <file>	 Conf file : get list of folder from file instead of generate it
	-v		 Verbose : show more information

	/!\ use force only if you are sure what you do
	use this script at your own risk

some usefull commands :

generate conf file from running docker-compose :
  docker compose ls | cut -f1 -d" " | sed "1d" > myfile.conf


```

## configuration file

Directories are managed with the first configuration found below :
- file given by `-c`
- file /usr/local/etc/docker-compose-recursive/directories.conf
- file /etc/docker-compose-recursive/directories.conf
- file /opt/docker-compose-recursive/directories.conf
- on demand on the current directory

## Todo (maybe)

- installer/updater
