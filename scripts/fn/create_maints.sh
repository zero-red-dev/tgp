#!/usr/bin/env bash
source ../header.sh

create_maints() {
	local dir=${1:-"."}
	local src_dir="$dir/src"

	if [[ ! -d $src_dir ]]; then
		mkdir -p "$src_dir" ||
			error "Failed to create src directory \"$src_dir\""
	fi

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str = \`
alert("Hello Zero")
\`

fs.writeFile('$src_dir/main.ts', str, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $src_dir/main.ts:', writeErr)
        return
    }
})
EOF
	)"
}
