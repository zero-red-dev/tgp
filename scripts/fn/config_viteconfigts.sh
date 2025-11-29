#!/usr/bin/env bash
source ../header.sh

config_viteconfigts() {
	local prj_dir=${1:-"."}

	# TODO: Right now this is hardcode for swc fix it later
	node -e "$(
		cat <<EOF
const fs = require('fs')

const str = \`
import swc from "./plugin/swc"
import { defineConfig } from "vite"

export default defineConfig({
  plugins: [swc()],
})
\`

fs.writeFile('$prj_dir/vite.config.ts', str, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $prj_dir/vite.config.ts:', writeErr)
        return
    }
})
EOF
	)"
}
