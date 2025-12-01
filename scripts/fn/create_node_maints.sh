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
