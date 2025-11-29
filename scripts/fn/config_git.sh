#!/usr/bin/env bash
source ../header.sh

config_git() {
	local prj_dir=${1:-"."}
	rm -rf "$prj_dir/.git" ||
		error "Can't remove unnecessary \"$prj_dir/.git\""

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str = \`
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
\`

fs.stat('$prj_dir/.gitignore', (err, stats) => {
    if (err) {
      fs.writeFile('$prj_dir/.gitignore', str, (writeErr) => {
          if (writeErr) {
              console.error('Error writing $prj_dir/.gitignore:', writeErr)
              return
          }
      })
    } else {
      fs.readFile('$prj_dir/.gitignore', 'utf8', (err, data) => {
          if (err) {
              console.error('Error reading $prj_dir/.gitignore:', err)
              return
          }
      
          fs.writeFile('$prj_dir/.gitignore', data + "\n" + str, (writeErr) => {
              if (writeErr) {
                  console.error('Error writing $prj_dir/.gitignore:', writeErr)
                  return
              }
          })
      })
    }
});
EOF
	)"
}
