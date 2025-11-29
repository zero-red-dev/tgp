#!/usr/bin/env bash
source ./header.sh

if [[ ! $# -lt 1 ]]; then
	project_name=$1
else
	project_name=$($DIALOG --inputbox "Project Name:" 8 40 3>&1 1>&2 2>&3 3>&-)
fi

project_dir="$PWD/$project_name"
create_project $project_dir

pushd $project_dir

config_packagejs
config_tsconfigjson
config_prettier
config_git
config_yarn

create_indexhtml $project_dir $project_name
create_maints

plugin_swc
config_viteconfigts

popd
