#!/usr/bin/env bash
source ../header.sh

config_scripts() {
	local prj_dir=${1:-"."}
	local prj_type=${2:-"vite-web"}
	local scripts_dir="$dir/scripts"

	if [[ ! -d $scripts_dir ]]; then
		mkdir -p "$scripts_dir" ||
			error "Failed to create directory \"$scripts_dir\""
	fi

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str1 = \`
import { execSync } from "child_process"
import { cpSync, rmSync } from "fs"

const cmd = (command, path = process.cwd()) =>
  execSync(command, {
    stdio: [0, 1, 2],
    cwd: path,
  })

//cmd("yarn server:build")

cpSync(process.cwd() +"dist", process.cwd() + "dist-server/statics", {
  recursive: true,
})

rmSync(process.cwd() + "/dist", {
  force: true,
  recursive: true,
})
\`

fs.writeFile('$scripts_dir/build.js', str1, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $scripts_dir/build.js:', writeErr)
        return
    }
})
EOF
	)"
}
