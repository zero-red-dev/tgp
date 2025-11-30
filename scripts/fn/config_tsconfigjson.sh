#!/usr/bin/env bash
source ../header.sh

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
