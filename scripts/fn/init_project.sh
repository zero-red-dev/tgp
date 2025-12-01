#!/usr/bin/env bash
source ../header.sh

init_project() {
	local prj_dir=${1:-"."}
	local prj_name=${2:-"my-app"}
	local prj_type=${3:-"vite-web"}

	if [[ -d $prj_dir ]]; then
		error "Project already exist in \"$prj_dir\"!!"
	else
		mkdir -p "$prj_dir" ||
			error "Failed to create project directory \"$prj_dir\""
	fi

	pushd $prj_dir

	info $prj_dir
	yarn init --yes
	popd
}
