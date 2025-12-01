#!/usr/bin/env bash
source ../header.sh

config_scripts() {
	local prj_dir=${1:-"."}
	local prj_type=${2:-"vite-web"}
	local scripts_dir="$prj_dir/scripts"

	if [[ ! -d $scripts_dir ]]; then
		mkdir -p "$scripts_dir" ||
			error "Failed to create directory \"$scripts_dir\""
	fi

	if [[ "$prj_type" == "vite-mono" ]]; then
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

cmd("yarn server:build")
cmd("yarn ui:build")

rmSync(\\\`\\\${process.cwd()}/dist\\\`, {
  force: true,
  recursive: true,
})

cpSync(\\\`\\\${process.cwd()}/packages/server/dist\\\`, \\\`\\\${process.cwd()}/dist\\\`, {
  recursive: true,
})

cpSync(\\\`\\\${process.cwd()}/packages/ui/dist\\\`, \\\`\\\${process.cwd()}/dist/statics\\\`, {
  recursive: true,
})
\`



const str2 = \`
import { execSync } from "child_process"
import { cpSync, existsSync } from "fs"

const cmd = (command, path = process.cwd()) =>
  execSync(command, {
    stdio: [0, 1, 2],
    cwd: path,
  })

if (!existsSync(\\\`\\\${process.cwd()}/dist\\\`)) cmd("yarn build")

cpSync(\\\`\\\${process.cwd()}/dist/statics\\\`, \\\`\\\${process.cwd()}/statics\\\`, {
  recursive: true,
})

cmd("node dist/main.js")
\`


fs.writeFile('$scripts_dir/build.js', str1, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $scripts_dir/build.js:', writeErr)
        return
    }
})

fs.writeFile('$scripts_dir/start.js', str2, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $scripts_dir/start.js:', writeErr)
        return
    }
})
EOF
		)"
	fi
}
