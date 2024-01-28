#!/bin/bash
# https://github.com/PiDroid-B/docker-compose-recursive
# MIT ©2022 PiDroid-B 
############################################################
# Const                                                    #
############################################################
VERSION="v0.3.2"
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
GRAY='\033[1;30m'
BLUE='\033[1;34m'
NC='\033[0m'

# Gets the command name without path
cmd="$(basename "$0")"

ACTION=""
FORCE=0
FILE=""
DIRECTORIES=""
DIRECTORIES_INV=""
VERBOSE=0
PRUNE=0
UPDATE=0
LIST=0
DOCKER=""

############################################################
# Help                                                     #
############################################################
Help(){
echo -e "\
docker-compose-recursive.sh - version ${VERSION}

manage a tree of docker-compose :
#default only dir with 'OK' file can be managed (or use the 'force' option)
#conf file ${cmd}.conf is used is exist to manage the tree (can be define too by -c)

${cmd}
├── stack1
│   ├── docker-compose.yml
│   ├── .env
│   └── OK
└── stack2
    └── docker-compose.yml

${GREEN}Usage : ${cmd} [FOLDER] <ACTION> [OPTION]${NC}

FOLDER
# apply only to this folder (apply on all folder if missing)

ACTION
#-h## Help : show this help
#-u## Up : builds, (re)creates, starts, and attaches to containers for each docker-compose
#-d## Down : stops containers and removes containers, networks, volumes, and images created by up
#-r## Restart : Down and Up on each docker-compose
#-p## Prune : remove unsed images, volumes and networks
#-i## Install/Update : check if new versions of docker-compose and dcr exist (autoupdate for docker-compose if force)
#-c [<file>]# Conf file : get list of folder from file instead of generate it, return list when file is missing
OPTION
#-f## Force : no check of 'OK' file (udr), auto install/upgrade (i)
#-v## Verbose : show more information

#${RED}/!\ use force only if you are sure what you do${NC}
#use this script at your own risk

some usefull commands :

generate conf file from running docker-compose :
  docker compose ls | cut -f1 -d\" \" | sed \"1d\" > myfile.conf

https://github.com/PiDroid-B/docker-compose-recursive MIT ©2022 PiDroid-B 

" | tr "#" "\t"
#" | column -t -s ";"
}


############################################################
# Functions                                                #
############################################################

Up(){
	echo -e "${GREEN}####### ${1} > up #######${NC}"
	docker compose up -d
}

Down(){
	echo -e "${ORANGE}####### ${1} > down #######${NC}"
	docker compose down
}

Prune(){
	echo -e "${GREEN}####### Prune unused images/volumes/networks #######${NC}"
	verbose "# Prune"
	verbose "  - Prune unused images"
	docker image prune -fa
	verbose "  - Prune unused volumes"
	docker volume prune -f
	verbose "  - Prune unused networks\n"
	docker network prune -f
}

List(){
        watch -n 1 -d 'docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.State}}" -a | ( read -r header ; printf "%s\n" "$header" ; sort "$@" )'
}

DC_Update(){
	local dc_curr_version
	local dc_last_version
	local github_content
	local filename
	local files

	echo -e "${GREEN}####### Install/Update docker-compose  #######${NC}"
	verbose "# docker-compose"
	dc_curr_version="not installed"

	if [[ -r /usr/libexec/docker/cli-plugins/docker-compose ]]; then
		dc_curr_version="$( docker compose version | sed -r "s/^.*(v[0-9]\.[0-9]\.[0-9]).*/\1/" )"
	fi
	verbose "  - current version : ${dc_curr_version}"

	github_content="$( curl -s https://api.github.com/repos/docker/compose/releases/latest )"
	dc_last_version="$( echo "${github_content}" | grep "tag_name" | sed -r "s/^.*(v[0-9].[0-9].[0-9]).*/\1/" )"
        #dc_last_version="$( curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | sed -r "s/^.*(v[0-9].[0-9].[0-9]).*/\1/" )"
	verbose "  - last version : ${dc_last_version}"

	if [[ "${dc_curr_version}" == "${dc_last_version}" ]]; then
		echo "docker-compose already up to date"
	else
		echo "docker-compose update avaiable : ${dc_curr_version} > ${dc_last_version}"

		verbose "  - get information from github"
		#github_content="$( curl -s https://api.github.com/repos/docker/compose/releases/latest )"
		filename="docker-compose-$(uname -s)-$(uname -m)"
		files="$( echo "${github_content}" | grep -Ei "browser_download_url.*$filename" | cut -d"\"" -f4 )"

		if [[ "${FORCE}" -eq 1 ]]; then
			echo "force==1 > auto-update"

			verbose "  - change directory to /tmp/"
			command pushd "/tmp/" > /dev/null || exit 1

			for f in $files; do
				verbose "  - download ${f}"
				curl -L -o "/tmp/$(basename "${f}")" "${f}"
				[[ "${f}" == *".sha256"* ]] && f_sha="$(basename "${f}")" || f_dc="$(basename "${f}")"
			done

			verbose "  - checksum of ${f_dc} with ${f_sha}"

			if ! sha256sum -c "${f_sha}"  > /dev/null ; then
				echo -e "${RED}${f_dc} with ${f_sha} : checksum failed ${NC}"
				exit 1
			fi

			verbose "  - copy ${filename}"
			cp "${f_dc}" /usr/libexec/docker/cli-plugins/docker-compose || exit 1

			command popd > /dev/null || exit 1
			verbose "  - return to previous directory $(pwd)"

			chmod +x /usr/libexec/docker/cli-plugins/docker-compose || exit 1
			verbose "  - chmod for docker-compose"
			echo -e "${GREEN}####### docker-compose up to date ! #######${NC}"
		else
			echo
			echo "##################################################################################################"
			echo -e "${ORANGE}docker-compose new version available : ${NC}${dc_curr_version} > ${GREEN}${dc_last_version}${NC}"
			echo -e "\t${GREEN}How to install/upgrade${NC}"
			echo
			for f in $files; do
				echo "wget \"${f}\" -O \"/tmp/$(basename \""${f}"\")\""
				[[ "${f}" == *".sha256"* ]] && f_sha="${f}" || f_dc="${f}"
			done
			echo
			echo "sha256sum -c \"${f_sha}\""
			echo
			echo "mv \"${f_dc}\" /usr/libexec/docker/cli-plugins/docker-compose"
			echo
			echo "chmod +x /usr/libexec/docker/cli-plugins/docker-compose"
			echo ""
			echo -e "${GREEN}####### Exit to manage it #######${NC}"
			echo
			exit 0
		fi
	fi
}

# Run_for_item <action (Up|Down)> <directory>
Run_for_item(){
	local action=${1}
	local directory=${2}
	verbose "\n    - Action ${action} (force=$FORCE) on $directory"

	if [[ -r "${directory}/docker-compose.yml" ]]; then

		verbose "      + change directory to ${directory}"
		command pushd "${directory}" > /dev/null || exit 1

		if [[ "${FORCE}" -eq 1 || -e "OK"  ]]; then
			verbose "      + Force==1 or file OK found"
			verbose "      + Do action ${action}"
			${action} "${directory}"
		else
			verbose "      + Force($FORCE)==0 or file OK not found"
			verbose "      + Skip action ${action}"
			echo -e "${GRAY}####### ${directory} > ${1} [SKIP] (OK && force == false) #######${NC}"
		fi

		command popd > /dev/null || exit 1
		verbose "      + return to previous directory $(pwd)"
	else
		verbose "      + file ${directory}/docker-compose.yml not found"
		echo -e "${RED}####### ${directory} > ERROR ${directory} not found #######${NC}"
	fi
}

# Run_for_all <action (Up|Down|Restart)>
Run_for_all(){
	local action=${1}

	verbose "# Action ${action} (force=$FORCE) on each directory of $(Array_to_Str "${DIRECTORIES}")"

	if [[ "Down Restart" == *"${action}"* ]]; then
		verbose "\n  - Action ${action}[Down] (force=$FORCE) on each directory of $(Array_to_Str "${DIRECTORIES_INV}")"
		for dir in $DIRECTORIES_INV; do
			Run_for_item "Down" "${dir}"
		done
	fi

	if [[ "Up Restart" == *"${action}"* ]]; then
		verbose "\n  - Action ${action}[Up] (force=$FORCE) on each directory of $(Array_to_Str "${DIRECTORIES}")"
		for dir in $DIRECTORIES; do
			Run_for_item "Up" "${dir}"
		done
	fi
}

# Run_for_one <action (Up|Down|Restart)> <docker>
Run_for_one(){
	local action=${1}
	local docker=${2}

	verbose "# Action ${action} (force=$FORCE) on ${docker}"

	if [[ "Down Restart" == *"${action}"* ]]; then
		verbose "\n  - Action ${action}[Down] (force=$FORCE) on ${docker}"
		Run_for_item "Down" "${docker}"
	fi

	if [[ "Up Restart" == *"${action}"* ]]; then
		verbose "\n  - Action ${action}[Up] (force=$FORCE) on ${docker}"
		Run_for_item "Up" "${docker}"
	fi
}

# Array_to_Str <array>
Array_to_Str(){
	local result=""
	for i in $1; do
		result="$result $i"
	done
	echo "$result"
}

############################################################
# Main                                                     #
############################################################

# if first char of first arg is not '-' then it's the directory of a docker compose
if [[ -n "${1}" && "${1:0:1}" != "-" ]]; then
    DOCKER="${1}"
	shift
fi

last_arg=""
for option in "$@"; do
	case $option in
		-c) FILE="<GetList>";;	
		-*)
			for (( i=1; i<${#option}; i++ )); do
				case ${option:$i:1} in
					h) Help; exit 0;;
					u) ACTION="Up";;
					d) ACTION="Down";;
					r) ACTION="Restart";;
                                        l) LIST=1 ;;
					i) UPDATE=1;;
					f) FORCE=1;;
					p) PRUNE=1;;
					v) VERBOSE=1;;
				esac
			done
			;;
		*)
		case $last_arg in
		  	-c) FILE="$option";;
			:) echo -e "${RED}missing argument for $OPTARG ${NC}\n\n"; Help; exit 1;;
			?) echo -e "${RED}Invalid option ${NC}\n\n" ; Help; exit 1;;
		esac
		;;
	esac
	last_arg=$option
done

# while getopts "hudrifcvp" option; do
# 	case $option in
# 		h) Help; exit 0;;
# 		u) ACTION="Up";;
# 		d) ACTION="Down";;
# 		r) ACTION="Restart";;
# 		i) UPDATE=1;;
# 		f) FORCE=1;;
# 		c) FILE="${OPTARG}";;
# 		p) PRUNE=1;;
# 		v) VERBOSE=1;;
# 		:) echo -e "${RED}missing argument for $OPTARG ${NC}\n\n"; Help; exit 1;;
# 		?) echo -e "${RED}Invalid option ${NC}\n\n" ; Help; exit 1;;
# 	esac
# done

verbose(){
	[[ "${VERBOSE}" -eq 1 ]] && printf "${BLUE}${1}${NC}\n"
}

verbose "\
# Command and options
  - ACTION=${ACTION}
  - LIST=${LIST}
  - PRUNE=${PRUNE}
  - UPDATE=${UPDATE}
  - FORCE=${FORCE}
  - DOCKER=${DOCKER}
  - FILE=${FILE:-"<GetList>"}
  - VERBOSE=${VERBOSE}
"

if [[ -z "${ACTION}" && "${PRUNE}" -eq 0 && "${UPDATE}" -eq 0 && "${FILE}" != "<GetList>" && "${LIST}" -eq 0 ]]; then
	echo -e "${RED}missing option ${NC}\n\n"
	Help
	exit 1
fi

verbose "# Directories to manage"
if [[ -n "${FILE}" && -r  "${FILE}" ]]; then
	verbose "  - file ${FILE} found"
	DIRECTORIES="$(cat "${FILE}")"
else
	verbose "  - check file directories.conf exists"
	if [[ -r /usr/local/etc/docker-compose-recursive/directories.conf ]]; then
		verbose "  - /usr/local/etc/docker-compose-recursive/directories.conf found"
		DIRECTORIES="$(cat "/usr/local/etc/docker-compose-recursive/directories.conf" )"
	elif [[ -r /etc/docker-compose-recursive/directories.conf ]]; then
		verbose "  - /etc/docker-compose-recursive/directories.conf found"
		DIRECTORIES="$(cat "/etc/docker-compose-recursive/directories.conf" )"
	elif [[ -r /opt/docker-compose-recursive/directories.conf ]]; then
		verbose "  - /opt/docker-compose-recursive/directories.conf found"
		DIRECTORIES="$(cat "/opt/docker-compose-recursive/directories.conf" )"
	else
		verbose "  - no file, list auto-generated from current directory"
		DIRECTORIES="$(echo */ | tr ' ' '\n' | sed 's-/$--' )"
		# if contains no folder
		[[ "${DIRECTORIES}" == "*" ]] && DIRECTORIES=""
	fi
fi
DIRECTORIES_INV="$(echo "${DIRECTORIES}" | tac)"
verbose "  - DIRECTORIES=$(Array_to_Str "${DIRECTORIES}")"
verbose "  - DIRECTORIES_INV=$(Array_to_Str "${DIRECTORIES_INV}")\n"
if [[ "${FILE}" == "<GetList>" ]]; then
	echo "$DIRECTORIES"
	exit 0
fi

echo -e "${GREEN}####### START #######${NC}\n"

[[ "${PRUNE}" -eq 1 ]] && Prune
[[ "${UPDATE}" -eq 1 ]] && DC_Update

if [[ -n "${DOCKER}" ]]; then
	[[ -n "${ACTION}" ]] && Run_for_one "${ACTION}" "${DOCKER}"
else
	[[ -n "${ACTION}" ]] && Run_for_all "${ACTION}"
fi

echo -e "${GREEN}####### END #######${NC}\n"
[[ "${LIST}" -eq 1 ]] && List


