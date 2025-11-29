#!/usr/bin/env bash
set -euo pipefail

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

out_file=${1:-"tpg.sh"}

header_path=${2:-"./scripts/header.sh"}
main_path=${3:-"./scripts/main.sh"}
scripts_path=${4-"./scripts/fn"}

if [[ ! -r "$header_path" ]]; then
	error "File $header_path is not readable"
fi

if [[ ! -r "$main_path" ]]; then
	error "File $main_path is not readable"
fi

if [ ! -d "$scripts_path" ]; then
	error "$scripts_path folder not found!"
fi

header_str=$(cat ./scripts/header.sh)
main_str=$(cat ./scripts/main.sh)
scripts_str=""

for file in $scripts_path/*; do
	if [ -f "$file" ]; then
		info "Processing: $(basename "$file")"
		file_content=$(cat "$file" | sed -E '1{/^#!.*(bash|sh)/d}; /^[[:space:]]*source[[:space:]]+/d')
		scripts_str="$scripts_str"$'\n'"$file_content"
	fi
done

header_str=$(echo "$header_str" | sed '1{/^#!\/bin\/bash/d; /^#!\/usr\/bin\/env bash/d}; /^source /d')
main_str=$(echo "$main_str" | sed '1{/^#!\/bin\/bash/d; /^#!\/usr\/bin\/env bash/d}; /^source /d')

cat >"$out_file" <<EOF
#!/usr/bin/env bash
$header_str
$scripts_str
$main_str
EOF

chmod +x $out_file
