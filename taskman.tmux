#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

source "$SCRIPTS_DIR/variables.sh"
source "$SCRIPTS_DIR/helpers.sh"

set_default_key_binding_options() {
    local task_key="$(task_key)"
    local task_focus_key="$(task_focus_key)"
    local task_command="$(task_command)"
    local task_position="$(task_position)"
    local task_height="$(task_height)"

    set_tmux_option "${VAR_KEY_PREFIX}-${task_key}" "$task_command,${task_position},${task_height}"
	set_tmux_option "${VAR_KEY_PREFIX}-${task_focus_key}" "$task_command,${task_position},${task_height},focus"
}

set_key_bindings() {
    local stored_key_vars="$(stored_key_vars)"
	local search_var
	local key
	local pattern
	for option in $stored_key_vars; do
		key="$(get_key_from_option_name "$option")"
		value="$(get_value_from_option_name "$option")"

        echo $key $value

		tmux bind-key "$key" run-shell "$SCRIPTS_DIR/toggle.sh '$value' '#{pane_id}'"
	done
}

main() {
    set_default_key_binding_options
    set_key_bindings
}

main
