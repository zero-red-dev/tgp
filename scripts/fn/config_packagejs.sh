#!/usr/bin/env bash
source ../header.sh

config_packagejs() {
	local prj_dir=${1:-"."}
	local prj_name=${2:-"my-app"}
	local prj_type=${3:-"vite-web"}

	if [[ "$prj_type" == "vite-web" ]]; then
		node -e "$(
			cat <<EOF
const fs = require('fs')

fs.readFile('$prj_dir/package.json', 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading $prj_dir/package.json:', err)
        return
    }

    try {
        const packageJson = JSON.parse(data)

        packageJson.name = "$prj_name"
        packageJson.version = "0.0.0"
        packageJson.type = "module"

        packageJson.scripts = {}
        packageJson.scripts.dev = "vite"
        packageJson.scripts.build = "tsc && vite build"
        packageJson.scripts.preview = "vite preview"


        fs.writeFile('$prj_dir/package.json', JSON.stringify(packageJson, null, 2), (writeErr) => {
            if (writeErr) {
                console.error('Error writing $prj_dir/package.json:', writeErr)
                return
            }
        })
    } catch (parseError) {
      console.error('Error parsing JSON($prj_dir/package.json):', parseError)
    }
})
EOF
		)"
	elif [[ "$prj_type" == "vite-node" ]]; then
		node -e "$(
			cat <<EOF
const fs = require('fs')

fs.readFile('$prj_dir/package.json', 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading $prj_dir/package.json:', err)
        return
    }

    try {
        const packageJson = JSON.parse(data)

        packageJson.name = "$prj_name"
        packageJson.version = "0.0.0"
        packageJson.type = "module"

        packageJson.scripts = {}
        packageJson.scripts.dev = "tsc && concurrently -k \"tsc --watch\" \"nodemon --delay 2 --watch dist ./dist/main.js\""
        packageJson.scripts.build = "tsc && vite build"


        fs.writeFile('$prj_dir/package.json', JSON.stringify(packageJson, null, 2), (writeErr) => {
            if (writeErr) {
                console.error('Error writing $prj_dir/package.json:', writeErr)
                return
            }
        })
    } catch (parseError) {
      console.error('Error parsing JSON($prj_dir/package.json):', parseError)
    }
})
EOF
		)"
	elif [[ "$prj_type" == "vite-mono" ]]; then
		node -e "$(
			cat <<EOF
const fs = require('fs')

fs.readFile('$prj_dir/package.json', 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading $prj_dir/package.json:', err)
        return
    }

    try {
        const packageJson = JSON.parse(data)

        packageJson.name = "$prj_name"
        packageJson.version = "0.0.0"
        packageJson.type = "module"
        packageJson.workspaces = [
          "packages/*"
        ]

        packageJson.scripts = {}

        packageJson.scripts.build = "node scripts/build.js"
        packageJson.scripts.start = "node scripts/start.js"

        packageJson.scripts.dev = "concurrently --kill-others \"npm:server:dev\" \"npm:ui:dev\""
        
        packageJson.scripts["ui:dev"] = "yarn workspace @$prj_name/ui dev"
        packageJson.scripts["ui:build"] = "yarn workspace @$prj_name/ui build"
        
        packageJson.scripts["server:dev"] = "yarn workspace @$prj_name/server dev"
        packageJson.scripts["server:build"] = "yarn workspace @$prj_name/server build"


        fs.writeFile('$prj_dir/package.json', JSON.stringify(packageJson, null, 2), (writeErr) => {
            if (writeErr) {
                console.error('Error writing $prj_dir/package.json:', writeErr)
                return
            }
        })
    } catch (parseError) {
      console.error('Error parsing JSON($prj_dir/package.json):', parseError)
    }
})
EOF
		)"
	fi
}
