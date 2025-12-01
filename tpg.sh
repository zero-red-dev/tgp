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
	local scripts_dir="$prj_dir/scripts"

	if [[ ! -d $scripts_dir ]]; then
		mkdir -p "$scripts_dir" ||
			error "Failed to create directory \"$scripts_dir\""
	fi

	if [[ "$prj_type" == "vite-mono" ]]; then
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

cmd("yarn server:build")
cmd("yarn ui:build")

rmSync(\\\`\\\${process.cwd()}/dist\\\`, {
  force: true,
  recursive: true,
})

cpSync(\\\`\\\${process.cwd()}/packages/server/dist\\\`, \\\`\\\${process.cwd()}/dist\\\`, {
  recursive: true,
})

cpSync(\\\`\\\${process.cwd()}/packages/ui/dist\\\`, \\\`\\\${process.cwd()}/dist/statics\\\`, {
  recursive: true,
})
\`



const str2 = \`
import { execSync } from "child_process"
import { cpSync, existsSync } from "fs"

const cmd = (command, path = process.cwd()) =>
  execSync(command, {
    stdio: [0, 1, 2],
    cwd: path,
  })

if (!existsSync(\\\`\\\${process.cwd()}/dist\\\`)) cmd("yarn build")

cpSync(\\\`\\\${process.cwd()}/dist/statics\\\`, \\\`\\\${process.cwd()}/statics\\\`, {
  recursive: true,
})

cmd("node dist/main.js")
\`


fs.writeFile('$scripts_dir/build.js', str1, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $scripts_dir/build.js:', writeErr)
        return
    }
})

fs.writeFile('$scripts_dir/start.js', str2, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $scripts_dir/start.js:', writeErr)
        return
    }
})
EOF
		)"
	fi
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
	elif [[ "$prj_type" == "vite-mono" ]]; then
		pushd $prj_dir
		yarn config set nodeLinker node-modules
		yarn
		yarn add typescript concurrently --dev
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

const str1 = \`
import { serve } from "@hono/node-server"
import { Hono } from "hono"
import { serveStatic } from "@hono/node-server/serve-static"
import { WebSocketServer } from "ws"
import pathNode from "path"

const port = 3000
const app = new Hono()

app.use(
  "/*",
  serveStatic({
    root: ".",
    rewriteRequestPath: (path) => {
      return path.match(/^\\\\/api\\\\//) ? "" : pathNode.join("statics", path)
    }
  }),
)

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
    setTimeout(() => {
      ws.send(\\\`Welcome \\\${name}, Thanks for visiting my website\\\`)
    }, 2000);
  })
  ws.on("close", () => {})
})
\`


const str2 = \`
body {
  background-color: #232323;
  color: #ffffff;
}
\`

const str3 = \`
const wss = new WebSocket("")
const msg = document.querySelector("#msg")

wss.addEventListener("open", () => {
  wss.send("I'm Client")
})

wss.addEventListener("message", (e) => {
  console.log(e.data)
  msg.innerHTML = e.data
})
\`

const str4 = \`
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Home</title>
    <link href="./main.css" rel="stylesheet" />
  </head>
  <body>
    <div id="msg"></div>
    <h1>Simple Ui without anything fancy :)</h1>
    <script src="./main.js"></script>
  </body>
</html>
\`

fs.writeFile('$src_dir/main.ts', str1, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $src_dir/main.ts:', writeErr)
        return
    }
})

fs.writeFile('$statics_dir/main.css', str2, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $statics_dir/main.css:', writeErr)
        return
    }
})

fs.writeFile('$statics_dir/main.js', str3, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $statics_dir/main.js:', writeErr)
        return
    }
})

fs.writeFile('$statics_dir/index.html', str4, (writeErr) => {
    if (writeErr) {
        console.error('Error writing $statics_dir/index.html:', writeErr)
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

init_project() {
	local prj_dir=${1:-"."}
	local prj_name=${2:-"my-app"}
	local prj_type=${3:-"vite-web"}

	if [[ -d $prj_dir ]]; then
		error "Project already exist in \"$prj_dir\"!!"
	else
		mkdir -p "$prj_dir" ||
			error "Failed to create project directory \"$prj_dir\""
	fi

	pushd $prj_dir

	info $prj_dir
	yarn init --yes
	popd
}

plugin_swc() {
	local prj_dir=${1:-"."}
	local prj_type=${2:-"vite-web"}
	local dir="$prj_dir/plugin"
	local plugin_dir="$dir/swc"

	if [ "$prj_type" == "vite-web" ] || [ "$prj_type" == "vite-node" ]; then
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
	fi
}

##############  fn ##############
create_project() {
	local prj_dir=${1:-"."}
	local prj_name=${2:-"my_app"}
	local prj_type=${3:-"vite-web"}

	info_bold "Start creating $prj_name project ..."

	init_project $prj_dir $prj_name $prj_type
	config_packagejs $prj_dir $prj_name $prj_type
	config_tsconfigjson $prj_dir $prj_type
	config_prettier $prj_dir
	config_git $prj_dir
	config_yarn $prj_dir $prj_type
	plugin_swc $prj_dir $prj_type
	config_viteconfigts $prj_dir $prj_type

	if [[ "$prj_type" == "vite-web" ]]; then
		create_indexhtml $prj_dir $prj_name
		create_maints $prj_dir
	elif [[ "$prj_type" == "vite-node" ]]; then
		create_node__maints $prj_dir
	fi

	if [[ "$prj_type" == "vite-mono" ]]; then
		config_scripts $prj_dir $prj_type
		create_project "$prj_dir/packages/ui" "@$prj_name/ui" "vite-web"
		create_project "$prj_dir/packages/server" "@$prj_name/server" "vite-node"
	fi

	success "$prj_name project done :)"
}
##############  ##############

##############  Input Validation ##############
if [[ ! $# -lt 1 ]]; then
	project_name=$1
else
	project_name=$($DIALOG --inputbox "Project Name:" 8 40 3>&1 1>&2 2>&3 3>&-)
fi

project_type__options=(
	"vite-web" "" on
	"vite-node" "" off
	"vite-mono" "" off
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
##############  ##############

project_dir="$PWD/$project_name"
create_project $project_dir $project_name $project_type
