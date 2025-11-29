#!/usr/bin/env bash
source ../header.sh

config_prettier() {
	local prj_dir=${1:-"."}

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str1 = \`
{
  "tabWidth": 2,
  "useTabs": false,
  "semi": false,
  "singleQuote": false
}
\`

const str2 = \`
# Ignore all README files: 
**/*.md
\`

fs.writeFile('$prj_dir/.prettierrc', str1, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $prj_dir/.prettierrc:', writeErr)
        return
    }
})

fs.writeFile('$prj_dir/.prettierignore', str2, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $prj_dir/.prettierignore:', writeErr)
        return
    }
})
EOF
	)"
}
