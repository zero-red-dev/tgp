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
	local prj_type=${2:-"vite-web"}

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
	fi
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
	local prj_type=${2:-"vite-web"}
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
	local prj_type=${2:-"vite-web"}

	if [[ "$prj_type" == "vite-web" ]]; then
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

	elif [[ "$prj_type" == "vite-node" ]]; then
		node -e "$(
			cat <<EOF
const fs = require('fs')
try {
    const tsConfig = {
  "compilerOptions": {
    "outDir": "dist",
    "target": "ES2022",
    "useDefineForClassFields": true,
    "module": "NodeNext",
    "lib": ["ES2022"],
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "NodeNext",
    "resolveJsonModule": true,
    "isolatedModules": true,

    /* Linting */
    "strict": true,
    //"noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true
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

	fi

}

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

config_yarn() {
	local prj_dir=${1:-"."}
	local prj_type=${2:-"vite-web"}

	if [[ "$prj_type" == "vite-web" ]]; then
		pushd $prj_dir
		yarn config set nodeLinker node-modules
		yarn
		yarn add typescript vite sass --dev
		popd
	elif [[ "$prj_type" == "vite-node" ]]; then
		pushd $prj_dir
		yarn config set nodeLinker node-modules
		yarn
		yarn add typescript nodemon concurrently vite @types/node @types/ws rollup-plugin-node-externals --dev
		yarn add typescript hono @hono/node-server ws
		popd
	fi
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

create_node__maints() {
	local dir=${1:-"."}
	local src_dir="$dir/src"
	local statics_dir="$dir/statics"

	if [[ ! -d $src_dir ]]; then
		mkdir -p "$src_dir" ||
			error "Failed to create src directory \"$src_dir\""
	fi

	if [[ ! -d $statics_dir ]]; then
		mkdir -p "$statics_dir" ||
			error "Failed to create src directory \"$statics_dir\""
	fi

	node -e "$(
		cat <<EOF
const fs = require('fs')

const str = \`
import { serve } from "@hono/node-server"
import { Hono } from "hono"
import { serveStatic } from "@hono/node-server/serve-static"
import { WebSocketServer } from "ws"
import pathNode from "path"

const port = 3000
const app = new Hono()

/*
app.use(
  "/*",
  serveStatic({
    root: ".",
    rewriteRequestPath(path) {
      if (path.match(/^\/api\//)) return ""
      else return pathNode.join("statics", path)
    },
  }),
)
*/

const server = serve(
  {
    fetch: app.fetch,
    port,
  },
  (info) => {
    console.log(\\\`Listening on http://localhost:\\\${info.port}\\\`)
  },
)
const wss = new WebSocketServer({ server: server as any })

app.get("/api/hello", (c) => {
  return c.text("Hello World!")
})

wss.on("connection", (ws) => {
  ws.on("message", (data) => {
    const name = data.toString().split(" ").pop()
    ws.send(\\\`Welcome \\\${name}, Thanks for visiting my website\\\`)
  })
  ws.on("close", () => {})
})
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
	local prj_type=${2:-"vite-web"}

	# if [[ "$prj_type" == "vite-web" ]]; then
	if [[ -d $prj_dir ]]; then
		error "Project already exist in \"$prj_dir\"!!"
	else
		mkdir -p "$prj_dir" ||
			error "Failed to create project directory \"$prj_dir\""
	fi

	pushd $prj_dir
	yarn init --yes
	popd
	# fi
}

plugin_swc() {
	local prj_dir=${1:-"."}
	local dir="$prj_dir/plugin"
	local plugin_dir="$dir/swc"

	pushd $prj_dir
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
	popd
}

##############  input validation ##############
if [[ ! $# -lt 1 ]]; then
	project_name=$1
else
	project_name=$($DIALOG --inputbox "Project Name:" 8 40 3>&1 1>&2 2>&3 3>&-)
fi

project_type__options=(
	"vite-web" "" on
	"vite-node" "" off
)

project_type__keys=()
for ((i = 0; i < ${#project_type__options[@]}; i += 3)); do
	project_type__keys+=("${project_type__options[i]}")
done

if [[ ! $# -lt 2 ]]; then
	project_type=$2
else
	project_type=$($DIALOG --clear \
		--radiolist "Select project type:" \
		10 40 3 \
		"${project_type__options[@]}" \
		3>&1 1>&2 2>&3 3>&-)
fi

valid_type=false
for key in "${project_type__keys[@]}"; do
	if [[ "$project_type" == "$key" ]]; then
		valid_type=true
		break
	fi
done

if [[ $valid_type == false ]]; then
	project_type__error_msg="Invalid project type '$project_type'. Choose from:"
	for key in "${project_type__keys[@]}"; do
		project_type__error_msg="$project_type__error_msg\n  - $key"
	done
	error "$project_type__error_msg"
fi
##############   ##############

project_dir="$PWD/$project_name"
create_project $project_dir $project_type

config_packagejs $project_dir $project_type
config_tsconfigjson $project_dir $project_type
config_prettier $project_dir
config_git $project_dir
config_yarn $project_dir $project_type
plugin_swc $project_dir
config_viteconfigts $project_dir $project_type

if [[ "$project_type" == "vite-web" ]]; then
	create_indexhtml $project_dir $project_name
	create_maints $project_dir
elif [[ "$project_type" == "vite-node" ]]; then
	create_node__maints $project_dir
fi
