#!/bin/bash

############################################################
# Const                                                    #
############################################################
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

############################################################
# Help                                                     #
############################################################
Help(){
echo -e "\

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

${GREEN}Usage : ${cmd} [ACTION] [OPTION]${NC}

ACTION
#-h## Help : show this help
#-u## Up : builds, (re)creates, starts, and attaches to containers for each docker-compose
#-d## Down : stops containers and removes containers, networks, volumes, and images created by up
#-r## Restart : Down and Up on each docker-compose
#-p## Prune : remove unsed images, volumes and networks
#-i## Install/Update : check if new versions of docker-compose and dcr exist (autoupdate for docker-compose if force)
OPTION
#-f## Force : no check of 'OK' file (udr), auto install/upgrade (i)
#-c <file># Conf file : get list of folder from file instead of generate it
#-v## Verbose : show more information

#${RED}/!\ use force only if you are sure what you do${NC}
#use this script at your own risk

some usefull commands :

generate conf file from running docker-compose :
  docker compose ls | cut -f1 -d\" \" | sed \"1d\" > myfile.conf

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

        dc_last_version="$( curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | sed -r "s/^.*(v[0-9].[0-9].[0-9]).*/\1/" )"
	verbose "  - last version : ${dc_last_version}"

	if [[ "${dc_curr_version}" == "${dc_last_version}" ]]; then
		echo "docker-compose already up to date"
	else
		echo "docker-compose update avaiable : ${dc_curr_version} > ${dc_last_version}"

		verbose "  - get information from github"
		github_content="$( curl -s https://api.github.com/repos/docker/compose/releases/latest )"
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

while getopts "hudrifc:vp" option; do
	case $option in
		h) Help; exit 0;;
		u) ACTION="Up";;
		d) ACTION="Down";;
		r) ACTION="Restart";;
		i) UPDATE=1;;
		f) FORCE=1;;
		c) FILE="${OPTARG}";;
		p) PRUNE=1;;
		v) VERBOSE=1;;
		:) echo -e "${RED}missing argument for $OPTARG ${NC}\n\n"; Help; exit 1;;
		?) echo -e "${RED}Invalid option ${NC}\n\n" ; Help; exit 1;;
	esac
done

verbose(){
	[[ "${VERBOSE}" -eq 1 ]] && printf "${BLUE}${1}${NC}\n"
}

echo -e "${GREEN}####### START #######${NC}\n"

verbose "\
# Command and options
  - ACTION=${ACTION}
  - PRUNE=${PRUNE}
  - UPDATE=${UPDATE}
  - FORCE=${FORCE}
  - FILE=${FILE:-"<Empty>"}
  - VERBOSE=${VERBOSE}
"

if [[ -z "${ACTION}" && "${PRUNE}" -eq 0 && "${UPDATE}" -eq 0 ]]; then
	echo -e "${RED}missing option ${NC}\n\n"
	Help
	exit 1
fi

verbose "# Directories to manage"
if [[ -n "${FILE}" && -r  "${FILE}" ]]; then
	verbose "  - file ${FILE} found"
	DIRECTORIES="$(cat "${FILE}")"
else
	verbose "  - check file ${0}.conf exists"
	if [[ -r "${0}.conf" ]]; then
		verbose "  - default file ${0}.conf found"
		DIRECTORIES="$(cat "${0}.conf")"
	else
		verbose "  - no file, list auto-generated"
		DIRECTORIES="$(echo */ | tr ' ' '\n')"
	fi
fi
DIRECTORIES_INV="$(echo "${DIRECTORIES}" | tac)"
verbose "  - DIRECTORIES=$(Array_to_Str "${DIRECTORIES}")"
verbose "  - DIRECTORIES_INV=$(Array_to_Str "${DIRECTORIES_INV}")\n"

[[ "${PRUNE}" -eq 1 ]] && Prune
[[ "${UPDATE}" -eq 1 ]] && DC_Update

[[ -n "${ACTION}" ]] && Run_for_all "${ACTION}"

echo -e "${GREEN}####### END #######${NC}\n"


