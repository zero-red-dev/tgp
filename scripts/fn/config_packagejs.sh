#!/usr/bin/env bash
source ../header.sh

config_packagejs() {
	local prj_dir=${1:-"."}

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
}
