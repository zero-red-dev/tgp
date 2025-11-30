#!/usr/bin/env bash
source ./header.sh

##############  input validation ##############
if [[ ! $# -lt 1 ]]; then
	project_name=$1
else
	project_name=$($DIALOG --inputbox "Project Name:" 8 40 3>&1 1>&2 2>&3 3>&-)
fi

project_type__options=(
	"vite-web" "" on
	"vite-node" "" off
)

project_type__keys=()
for ((i = 0; i < ${#project_type__options[@]}; i += 3)); do
	project_type__keys+=("${project_type__options[i]}")
done

if [[ ! $# -lt 2 ]]; then
	project_type=$2
else
	project_type=$($DIALOG --clear \
		--radiolist "Select project type:" \
		10 40 3 \
		"${project_type__options[@]}" \
		3>&1 1>&2 2>&3 3>&-)
fi

valid_type=false
for key in "${project_type__keys[@]}"; do
	if [[ "$project_type" == "$key" ]]; then
		valid_type=true
		break
	fi
done

if [[ $valid_type == false ]]; then
	project_type__error_msg="Invalid project type '$project_type'. Choose from:"
	for key in "${project_type__keys[@]}"; do
		project_type__error_msg="$project_type__error_msg\n  - $key"
	done
	error "$project_type__error_msg"
fi
##############   ##############

project_dir="$PWD/$project_name"
create_project $project_dir $project_type

config_packagejs $project_dir $project_type
config_tsconfigjson $project_dir $project_type
config_prettier $project_dir
config_git $project_dir
config_yarn $project_dir $project_type
plugin_swc $project_dir
config_viteconfigts $project_dir $project_type

if [[ "$project_type" == "vite-web" ]]; then
	create_indexhtml $project_dir $project_name
	create_maints $project_dir
elif [[ "$project_type" == "vite-node" ]]; then
	create_node__maints $project_dir
fi
