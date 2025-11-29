#!/usr/bin/env bash
source ../header.sh

create_project() {
	local prj_dir=${1:-"."}

	if [[ -d $prj_dir ]]; then
		error "Project already exist in \"$prj_dir\"!!"
	else
		mkdir -p "$prj_dir" ||
			error "Failed to create project directory \"$prj_dir\""
	fi

	pushd $prj_dir
	yarn init --yes
	popd
}
