#!/usr/bin/env bash
source ../header.sh

config_yarn() {
	local prj_dir=${1:-"."}

	pushd $prj_dir
	yarn config set nodeLinker node-modules
	yarn
	yarn add typescript vite sass --dev
	popd
}

create_indexhtml() {
	local prj_dir=${1:-"."}
	local title=${2:-"Main"}

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str = \`
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$title</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="./src/main.ts"></script>
  </body>
</html>
\`

fs.writeFile('$prj_dir/index.html', str, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $prj_dir/index.html:', writeErr)
        return
    }
})
EOF
	)"
}
