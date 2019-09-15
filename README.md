# tmux-taskman

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/I3I1VA18)

Based extensively on Bruno Sutic's tmux-sidebar ( https://github.com/tmux-plugins/tmux-sidebar ),
tmux-taskman also does one thing: it opens a task manager (htop if available, otherwise top, by
default) pane. A fast and convenient what's-going-on check whatever you're doing in tmux.

![screenshot](https://raw.githubusercontent.com/arkane-systems/tmux-taskman/master/screenshot.gif)

## Features:

  * toggles on and off with one key binding, which may or may not focus the pane
  * remembers its size
  * preserves layout

## Requirements:

  * tmux 1.9 or higher, top; htop recommended but not required

## Key bindings:

  * prefix + ` - toggle task manager but do not focus it
  * prefix + ~ - toggle task manager and focus it

## Installation:

Use [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) and add this plugin
to your `.tmux.conf`:

```
set -g @plugin 'tmux-plugins/tmux-sidebar'
```

Hit prefix + I to fetch the plugin and source it. You should now be able to use the plugin.

## Customization:

To change the keybindings:

```
set -g @taskman-task '\`'
set -g @taskman-task-focus '~'
```

To change the command run as the task manager:

```
set -g @taskman-task-command 'atop'
```

To make it appear at the bottom instead of the top:

```
set -g @taskman-task-position 'bottom'
```
