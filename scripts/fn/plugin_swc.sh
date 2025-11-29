#!/usr/bin/env bash
source ../header.sh

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
