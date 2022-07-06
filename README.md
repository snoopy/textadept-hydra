# textadept-hydra

A plugin for the textadept editor, modeled on the emacs [hydra](https://github.com/abo-abo/hydra) plugin.
It allows you to define key maps for related commands, with the ability to easily repeat commands by using a single keystroke. 
This allows you to avoid the mouse.
When a hydra is active, the available keys and actions are displayed in the status bar,
so you don't need to memorise them.

For example, the following hydra would allow you to type `ctrl+w` to trigger a word navigation hydra,
in which you can use the left and right arrow keys to navigate by words.
Any other key will exit the hydra.

```
local word_hydra = {
  help="word",
  action = { 
    ['right'] = { help="next", action=buffer.word_right, persistent=true },
    ['left'] = { help="prev", action=buffer.word_left, persistent=true },
  }
}
hydra.keys['ctrl+w'] = word_hydra
```

# Installation

In your textadept configuration directory, type

    git clone git@github.com:mhwombat/textadept-hydra.git modules/hydra

Configure your desired hydra key bindings in `init.lua`.
Here's an example:

```
local hydra = require('hydra')

local word_hydra = {
  { key='left', help="prev", action=buffer.word_left, persistent=true },
  { key='right', help="next", action=buffer.word_right, persistent=true },
  { key='shift+left', help="shrink selection", action=buffer.word_left_extend, persistent=true },
  { key='shift+right', help="extend selection", action=buffer.word_right_extend, persistent=true },
}

local line_hydra = {
  { key='j', help="join", action=textadept.editing.join_lines },
  { key='|', 
    help="pipe to bash", 
    action=function()
             ui.command_entry.run(textadept.editing.filter_through, 'bash')
           end },
}

hydra.keys = {
  { key='ctrl+w', help="word", action=word_hydra },
  { key='ctrl+l', help="line", action=line_hydra }
}
```

# Configuration syntax

A basic hydra key binding has the form:

`{ key=`_key_`, help=`_msg_`, action=`_action_`[, persistent=true] }`

where

- _key_ is the key that will trigger the action.
- _msg_ is the text that will be displayed in help messages in the status bar.
  This text is optional in a top-level hydra key binding.
- _action_ is either a Textadept function call, or another hydra key binding.
- `persistent` is optional. If set to `true`, the hydra will remain active after the action is performed.