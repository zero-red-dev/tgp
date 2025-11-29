#!/usr/bin/env bash
set -euo pipefail

platform=$(uname -ms)

# Reset
Color_Off=''

# Regular Colors
Red=''
Green=''
Dim='' # White

# Bold
Bold_White=''
Bold_Green=''

if [[ -t 1 ]]; then
	# Reset
	Color_Off='\033[0m' # Text Reset

	# Regular Colors
	Red='\033[0;31m'   # Red
	Green='\033[0;32m' # Green
	Dim='\033[0;2m'    # White

	# Bold
	Bold_Green='\033[1;32m' # Bold Green
	Bold_White='\033[1m'    # Bold White
fi

error() {
	echo -e "${Red}error${Color_Off}:" "$@" >&2
	exit 1
}

info() {
	echo -e "${Dim}$* ${Color_Off}"
}

info_bold() {
	echo -e "${Bold_White}$* ${Color_Off}"
}

success() {
	echo -e "${Green}$* ${Color_Off}"
}

if command -v whiptail &>/dev/null; then
	DIALOG=whiptail
elif command -v dialog &>/dev/null; then
	DIALOG=dialog
else
	error "This script requires 'whiptail' or 'dialog'. Please install one of them."
fi

command -v git >/dev/null ||
	error 'git is required'


config_api() {
	local dir=${1:-"."}
	local api_dir="$dir/api"

	yarn add hono @hono/node-server

	if [[ ! -d $api_dir ]]; then
		mkdir -p "$api_dir" ||
			error "Failed to create directory \"$api_dir\""
	fi

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str1 = \`
import { Context } from "hono"

export function GET(c: Context) {
  return c.text("Hell Zero")
}
\`

const str2 = \`
import { GET as hello } from "./api/hello"
import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import { serveStatic } from "@hono/node-server/serve-static"
import { join as pathJoin } from "path"

const environment = process.env.NODE_ENV
const isDevelopment = environment === "development"

console.log("\n" + environment + "\n")

const port = isDevelopment ? 3000 : 80
const app = new Hono()

app.use(
  "/*",
  serveStatic({
    root: ".",
    rewriteRequestPath(path) {
      if (path.match(/^\/api\//)) return ""
      else return pathJoin("statics", path)
    },
  }),
)

app.get('/api/hello', hello)

serve(
  {
    fetch: app.fetch,
    port,
  },
  (info) => {
    console.log("Listening on http://localhost" + info.port)
  },
)
\`

fs.writeFile('$api_dir/hello.ts', str1, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $api_dir/hello.ts:', writeErr)
        return
    }
})

fs.writeFile('$dir/server.ts', str2, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $api_dir/server.ts:', writeErr)
        return
    }
})
EOF
	)"
}

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

config_scripts() {
	local prj_dir=${1:-"."}
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

config_tsconfigjson() {
	local prj_dir=${1:-"."}

	node -e "$(
		cat <<EOF
const fs = require('fs')
try {
    const tsConfig = {
      "compilerOptions": {
      "target": "ES2022",
      "useDefineForClassFields": true,
      "module": "ESNext",
      "lib": ["ES2022", "DOM", "DOM.Iterable"],
      "types": ["vite/client"],
      "skipLibCheck": true,

      /* Bundler mode */
      "moduleResolution": "bundler",
      "allowImportingTsExtensions": true,
      "verbatimModuleSyntax": true,
      "moduleDetection": "force",
      "noEmit": true,

      /* Linting */
      "strict": true,
      "noUnusedLocals": true,
      "noUnusedParameters": true,
      "erasableSyntaxOnly": true,
      "noFallthroughCasesInSwitch": true,
      "noUncheckedSideEffectImports": true
      },
      "include": ["src"]
    }

    fs.writeFile('$prj_dir/tsconfig.json', JSON.stringify(tsConfig, null, 2), (writeErr) => {
        if (writeErr) {
            console.error('Error writing $prj_dir/tsconfig.json:', writeErr)
            return
        }
    })
} catch (parseError) {
  console.error('Error parsing JSON($prj_dir/tsconfig.json):', parseError)
}
EOF
	)"
}

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

create_project() {
	local prj_dir=${1:-"."}

	if [[ -d $prj_dir ]]; then
		error "Project already exist in \"$prj_dir\"!!"
	else
		mkdir -p "$prj_dir" ||
			error "Failed to create project directory \"$prj_dir\""
	fi

	pushd $prj_dir
	yarn init --yes
	popd
}

plugin_swc() {
	local dir=${1:-"plugin"}
	local plugin_dir="$dir/swc"

	if [[ ! -d $plugin_dir ]]; then
		mkdir -p "$plugin_dir" ||
			error "Failed to create directory \"$plugin_dir\""
	fi

	yarn add @swc/core @rollup/pluginutils --dev

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str = \`
import { FilterPattern, createFilter } from "@rollup/pluginutils"
import { transform as SWCTransform, Options as SWCOption } from "@swc/core"

interface Options extends Omit<SWCOption, "filename" | "sourceFileName"> {
  include?: FilterPattern
}

const swc = (
  options: Options = {
    include: /\.ts?$/,
    exclude: "node_modules",
    swcrc: false,
    configFile: false,
    minify: true,
    jsc: {
      parser: {
        syntax: "typescript",
        decorators: true,
      },
      transform: {
        decoratorMetadata: true,
        decoratorVersion: "2022-03",
      },
    },
  },
) => {
  const { include, ...swcOptions } = options
  const filter = createFilter(options.include, options.exclude)
  return {
    name: "vite-plugin-swc",
    enforce: "pre" as any,
    config() {
      return {
        esbuild: false,
      } as any
    },
    transform(code: string, id: string) {
      if (filter(id)) {
        return SWCTransform(code, {
          filename: id,
          sourceFileName: id.split("?", 1)[0],
          ...swcOptions,
        })
      }
    },
  }
}

export { swc }
export default swc
\`

fs.writeFile('$plugin_dir/index.ts', str, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $plugin_dir/index.ts:', writeErr)
        return
    }
})
EOF
	)"
}

if [[ ! $# -lt 1 ]]; then
	project_name=$1
else
	project_name=$($DIALOG --inputbox "Project Name:" 8 40 3>&1 1>&2 2>&3 3>&-)
fi

project_dir="$PWD/$project_name"
create_project $project_dir

pushd $project_dir

config_packagejs
config_tsconfigjson
config_prettier
config_git
config_yarn

create_indexhtml $project_dir $project_name
create_maints

plugin_swc
config_viteconfigts

popd
