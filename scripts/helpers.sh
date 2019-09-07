get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

set_tmux_option() {
	local option=$1
	local value=$2
	tmux set-option -gq "$option" "$value"
}

stored_key_vars() {
	tmux show-options -g |
		\grep -i "^${VAR_KEY_PREFIX}-" |
		cut -d ' ' -f1 |               # cut just the variable names
		xargs                          # splat var names in one line
}

# get the key from the variable name
get_key_from_option_name() {
	local option="$1"
	echo "$option" |
		sed "s/^${VAR_KEY_PREFIX}-//"
}

get_value_from_option_name() {
	local option="$1"
	echo "$(get_tmux_option "$option" "")"
}

get_pane_info() {
	local pane_id="$1"
	local format_strings="#{pane_id},$2"
	tmux list-panes -t "$pane_id" -F "$format_strings" |
		\grep "$pane_id" |
		cut -d',' -f2-
}

taskman_dir() {
	echo "$TASKMAN_DIR"
}

taskman_file() {
	echo "$(taskman_dir)/pane_height.txt"
}

# function is used to get "clean" integer version number. Examples:
# `tmux 1.9` => `19`
# `1.9a`     => `19`
_get_digits_from_string() {
	local string="$1"
	local only_digits="$(echo "$string" | tr -dC '[:digit:]')"
	echo "$only_digits"
}

tmux_version_int() {
	local tmux_version_string=$(tmux -V)
	echo "$(_get_digits_from_string "$tmux_version_string")"
}
