#!/usr/bin/env bash
source ./header.sh

##############  fn ##############
create_project() {
	local prj_dir=${1:-"."}
	local prj_name=${2:-"my_app"}
	local prj_type=${3:-"vite-web"}

	info_bold "Start creating $prj_name project ..."

	init_project $prj_dir $prj_name $prj_type
	config_packagejs $prj_dir $prj_name $prj_type
	config_tsconfigjson $prj_dir $prj_type
	config_prettier $prj_dir
	config_git $prj_dir
	config_yarn $prj_dir $prj_type
	plugin_swc $prj_dir $prj_type
	config_viteconfigts $prj_dir $prj_type

	if [[ "$prj_type" == "vite-web" ]]; then
		create_indexhtml $prj_dir $prj_name
		create_maints $prj_dir
	elif [[ "$prj_type" == "vite-node" ]]; then
		create_node__maints $prj_dir
	fi

	if [[ "$prj_type" == "vite-mono" ]]; then
		config_scripts $prj_dir $prj_type
		create_project "$prj_dir/packages/ui" "@$prj_name/ui" "vite-web"
		create_project "$prj_dir/packages/server" "@$prj_name/server" "vite-node"
	fi

	success "$prj_name project done :)"
}
##############  ##############

##############  Input Validation ##############
if [[ ! $# -lt 1 ]]; then
	project_name=$1
else
	project_name=$($DIALOG --inputbox "Project Name:" 8 40 3>&1 1>&2 2>&3 3>&-)
fi

project_type__options=(
	"vite-web" "" on
	"vite-node" "" off
	"vite-mono" "" off
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
##############  ##############

project_dir="$PWD/$project_name"
create_project $project_dir $project_name $project_type
