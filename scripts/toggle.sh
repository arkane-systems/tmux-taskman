#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/variables.sh"

# script global vars
ARGS="$1"               # example args format: "htop,top,20,focus"
PANE_ID="$2"
COMMAND="$(echo "$ARGS"  | cut -d',' -f1)"   # "htop"
POSITION="$(echo "$ARGS" | cut -d',' -f2)"   # "top"
SIZE="$(echo "$ARGS"     | cut -d',' -f3)"   # "20"
FOCUS="$(echo "$ARGS"    | cut -d',' -f4)"   # "focus"

PANE_HEIGHT="$(get_pane_info "$PANE_ID" "#{pane_height}")"

supported_tmux_version_ok() {
	$CURRENT_DIR/check_tmux_version.sh "$SUPPORTED_TMUX_VERSION"
}

current_pane_is_taskman() {
	local var="$(get_tmux_option "${REGISTERED_TASKMAN_PREFIX}-${PANE_ID}" "")"
	[ -n "$var" ]
}

execute_command_from_main_pane() {
	# get pane_id for this taskman
	local main_pane_id="$(get_tmux_option "${REGISTERED_TASKMAN_PREFIX}-${PANE_ID}" "")"
	# execute the same command as if from the "main" pane
	$CURRENT_DIR/toggle.sh "$ARGS" "$main_pane_id"
}

taskman_registration() {
	get_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" ""
}

taskman_pane_id() {
	taskman_registration |
		cut -d',' -f1
}

taskman_pane_args() {
	echo "$(taskman_registration)" |
		cut -d',' -f2-
}

taskman_exists() {
	local pane_id="$(taskman_pane_id)"
	tmux list-panes -F "#{pane_id}" 2>/dev/null |
		\grep -q "^${pane_id}$"
}

has_taskman() {
	if [ -n "$(taskman_registration)" ] && taskman_exists; then
		return 0
	else
		return 1
	fi
}

current_pane_height_not_changed() {
	if [ $PANE_HEIGHT -eq $1 ]; then
		return 0
	else
		return 1
	fi
}

kill_taskman() {
	# get data before killing the task manager
	local taskman_pane_id="$(taskman_pane_id)"
	local taskman_args="$(taskman_pane_args)"
	local taskman_position="$(echo "$taskman_args" | cut -d',' -f2)" # bottom or defaults to top
	local taskman_height="$(get_pane_info "$taskman_pane_id" "#{pane_height}")"

	echo "$taskman_height" > $(taskman_file).bak
    mv $(taskman_file).bak $(taskman_file)

	# kill the task manager
	tmux kill-pane -t "$taskman_pane_id"

	# check current pane "expanded" properly
	local new_current_pane_height="$(get_pane_info "$PANE_ID" "#{pane_height}")"
	if current_pane_height_not_changed "$new_current_pane_height"; then
		# need to expand current pane manually
		local direction_flag
		if [[ "$taskman_position" =~ "bottom" ]]; then
			direction_flag="-D"
		else
			direction_flag="-U"
		fi
		# compensate 1 column
		tmux resize-pane "$direction_flag" "$((taskman_height + 1))"
	fi
	PANE_HEIGHT="$new_current_pane_height"
}

current_pane_too_narrow() {
	[ $PANE_HEIGHT -lt $MINIMUM_HEIGHT_FOR_TASKMAN ]
}

exit_if_pane_too_short() {
	if current_pane_too_short; then
		display_message "Pane too short for the task manager"
		exit
	fi
}

taskman_bottom() {
	[[ $POSITION =~ "bottom" ]]
}

height_from_taskman_file() {
	echo $(head -n 1 $(taskman_file))
}

desired_taskman_size() {
	local half_pane="$((PANE_HEIGHT / 2))"
	if [[ -f taskman_file ]]; then
		# use stored taskman height
		echo "$(height_from_taskman_file)"
	elif size_defined && [ $SIZE -lt $half_pane ]; then
		echo "$SIZE"
	else
		echo "$half_pane"
	fi
}

# tmux version 2.0 and below requires different argument for `join-pane`
use_inverted_size() {
	[ tmux_version_int -le 20 ]
}

split_taskman_top() {
	local taskman_size=$(desired_taskman_size)
	if use_inverted_size; then
		taskman_size=$((PANE_HEIGHT - $taskman_size - 1))
	fi
	local taskman_id="$(tmux new-window -c "~" -P -F "#{pane_id}" "$COMMAND")"
	tmux join-pane -vb -l "$taskman_size" -t "$PANE_ID" -s "$taskman_id"
	echo "$taskman_id"
}

split_taskman_bottom() {
	local taskman_size=$(desired_taskman_size)
	tmux split-window -v -l "$taskman_size" -c "~" -P -F "#{pane_id}" "$COMMAND"
}

register_taskman() {
	local taskman_id="$1"
	set_tmux_option "${REGISTERED_TASKMAN_PREFIX}-${taskman_id}" "$PANE_ID"
	set_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" "${taskman_id},${ARGS}"
}

no_focus() {
	if [[ $FOCUS =~ (^focus) ]]; then
		return 1
	else
		return 0
	fi
}

create_taskman() {
	local position="$1" # top / bottom
	local taskman_id="$(split_taskman_${position})"
	register_taskman "$taskman_id"
	if no_focus; then
		tmux last-pane
	fi
}

toggle_taskman() {
	if has_taskman; then
		kill_taskman
	else
		exit_if_pane_too_short
		if task_bottom; then
			create_taskman "bottom"
		else
			create_taskman "top"
		fi
	fi
}

main() {
	if supported_tmux_version_ok; then
		if current_pane_is_taskman; then
			execute_command_from_main_pane
		else
			toggle_taskman
		fi
	fi
}

main