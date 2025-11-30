#!/usr/bin/env bash
source ../header.sh

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
