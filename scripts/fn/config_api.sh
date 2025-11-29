#!/usr/bin/env bash
source ../header.sh

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
