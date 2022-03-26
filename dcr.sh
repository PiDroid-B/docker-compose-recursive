#!/bin/bash

############################################################
# Const                                                    #
############################################################
ACTION=${1:-"up"}

EXPECTED_ACTION=" up down "

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
GRAY='\033[1;30m'
BLUE='\033[1;34m'
NC='\033[0m'

# Option defaults
OPT="value"

# getopts string
# This string needs to be updated with the single character options (e.g. -f)
opts="fvo:"

# Gets the command name without path
cmd="$(basename $0)"

ACTION="Up"
FORCE=0
FILE=""
DIRECTORIES=""
DIRECTORIES_INV=""
VERBOSE=0

############################################################
# Help                                                     #
############################################################
Help(){
echo -e "\

manage a tree of docker-compose :
#default only dir with "OK" file can be managed (or use the 'force' option)
#conf file ${cmd}.conf is used is exist to manage the tree (can be define too by -c)

${cmd}
├── stack1
│   ├── docker-compose.yml
│   ├── .env
│   └── OK
└── stack2
    └── docker-compose.yml

${GREEN}Usage : ${cmd} [ACTION] [OPTION]${NC}

ACTION
#-h# Help : show this help
#-u# Up : run docker compose on each file (default)
#-d# Down : stop docker compose on each file
#-r# Restart : stop and run docker compose on each file
OPTION
#-f# Force : do it without checking of "OK" file
#-c <file># Conf file : get list of folder from file instead of generate it
#-v# Verbose : show more information

some usefull commands :

generate conf file from running docker-compose :
  docker compose ls | cut -f1 -d" " | sed "1d" > myfile.conf

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

# Run_for_item <action (Up|Down)> <force(1|0)> <directory>
Run_for_item(){
	local action=${1}
	local force=${2}
	local directory=${3}
	verbose "\n    - Action $action (force=$force) on $directory"

	if [[ -r "${directory}/docker-compose.yml" ]]; then

		verbose "      + change directory to ${directory}"
		command pushd "${directory}" > /dev/null

		if [[ "${force}" -eq 1 || -e "OK"  ]]; then
			verbose "      + Force==1 or file OK found"
			verbose "      + Do action $action"
			${action} "${directory}"
		else
			verbose "      + Force($force)==0 or file OK not found"
			verbose "      + Skip action $action"
			echo -e "${GRAY}####### ${directory} > ${1} [SKIP] (OK && force == false) #######${NC}"
		fi

		command popd > /dev/null
		verbose "      + return to previous directory $(pwd)"
	else
		verbose "      + file ${directory}/docker-compose.yml not found"
		echo -e "${RED}####### ${directory} > ERROR ${directory} not found #######${NC}"
	fi
}

# Run_for_all <action (Up|Down|Restart)> <force(1|0)>
Run_for_all(){
	local action=${1}
	local force=${2}
	local directories=${3}

	verbose "# Action $action (force=$force) on each directory of $(Array_to_Str "${DIRECTORIES}")"

	if [[ "Down Restart" == *"$action"* ]]; then
		verbose "\n  - Action $action[Down] (force=$force) on each directory of $(Array_to_Str "${DIRECTORIES_INV}")"
		for dir in $DIRECTORIES_INV; do
			Run_for_item "Down" "${force}" "${dir}"
		done
	fi

	if [[ "Up Restart" == *"$action"* ]]; then
		verbose "\n  - Action $action[Up] (force=$force) on each directory of $(Array_to_Str "${DIRECTORIES}")"
		for dir in $DIRECTORIES; do
			Run_for_item "Up" "${force}" "${dir}"
		done
	fi
}

# Array_to_Str <array>
Array_to_Str(){
	local result=""
	for i in $1; do
		result="$result $i"
	done
	echo $result
}

############################################################
# Main                                                     #
############################################################

while getopts "hudrfc:v" option; do
	case $option in
		h) Help; exit 0;;
		u) ACTION="Up";;
		d) ACTION="Down";;
		r) ACTION="Restart";;
		f) FORCE=1;;
		c) FILE="${OPTARG}";;
		v) VERBOSE=1;;
		:) echo -e "${RED}missing argument for $OPTARG \n\n"; Help; exit 1;;
		?) echo -e "${RED}Invalid option \n\n" ; Help; exit 1;;
	esac
done

verbose(){
	[[ "${VERBOSE}" -eq 1 ]] && printf "${BLUE}${1}${NC}\n"
}

echo -e "${GREEN}####### START #######${NC}\n"

verbose "\
# Command and options
  - ACTION=${ACTION}
  - FORCE=${FORCE}
  - FILE=${FILE:-"<Empty>"}
  - VERBOSE=${VERBOSE}
"

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

Run_for_all "${ACTION}" "${FORCE}"

echo -e "${GREEN}####### END #######${NC}\n"


