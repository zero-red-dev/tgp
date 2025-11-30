#!/usr/bin/env bash
source ../header.sh

config_viteconfigts() {
	local prj_dir=${1:-"."}
	local prj_type=${2:-"vite-web"}

	if [[ "$prj_type" == "vite-web" ]]; then
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
	elif [[ "$prj_type" == "vite-node" ]]; then
		node -e "$(
			cat <<EOF
const fs = require('fs')

const str = \`
import swc from "./plugin/swc"
import { defineConfig } from "vite"
import { nodeExternals } from "rollup-plugin-node-externals"
import path from "path"
import { cpSync, readFileSync, writeFileSync } from "fs"

export default defineConfig({
  build: {
    lib: {
      name: "create-make",
      entry: [path.resolve(__dirname, "./src/main.ts")],
      fileName: (format, name) => {
        if (format === "es") return \\\`\\\${name}.js\\\`
        else return \\\`\\\${name}.\\\${format}\\\`
      },
      formats: ["es"],
    },
  },
  plugins: [
    nodeExternals(),
    swc(),
    {
      name: "assets-config",
      closeBundle: async () => {
        cpSync(\\\`\\\${__dirname}/statics\\\`, \\\`\\\${__dirname}/dist/statics\\\`, {
          recursive: true,
        })

        const { devDependencies, packageManager, ...packageJson } = JSON.parse(
          readFileSync(\\\`\\\${__dirname}/package.json\\\`, "utf8"),
        )

        packageJson.scripts = { start: "node main.js" }
        writeFileSync(
          \\\`\\\${__dirname}/dist/package.json\\\`,
          JSON.stringify(packageJson, null, 2),
        )
      },
    },
  ],
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
	fi
}
