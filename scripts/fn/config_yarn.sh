#!/usr/bin/env bash
source ../header.sh

config_yarn() {
	local prj_dir=${1:-"."}
	local prj_type=${2:-"vite-web"}

	if [[ "$prj_type" == "vite-web" ]]; then
		pushd $prj_dir
		yarn config set nodeLinker node-modules
		yarn
		yarn add typescript vite sass --dev
		popd
	elif [[ "$prj_type" == "vite-node" ]]; then
		pushd $prj_dir
		yarn config set nodeLinker node-modules
		yarn
		yarn add typescript nodemon concurrently vite @types/node @types/ws rollup-plugin-node-externals --dev
		yarn add typescript hono @hono/node-server ws
		popd
	elif [[ "$prj_type" == "vite-mono" ]]; then
		pushd $prj_dir
		yarn config set nodeLinker node-modules
		yarn
		yarn add typescript concurrently --dev
		popd
	fi
}
