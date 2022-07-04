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

local file_hydra = {
  help="file",
  action = { 
    ['n'] = { help="new", action=buffer.new },
    ['o'] = { help="open", action=io.open_file },
    ['r'] = { help="open recent", action=io.open_recent_file },
    ['s'] = { help="save", action=buffer.save },
    ['S'] = { help="save as", action=buffer.save_as },
    ['c'] = { help="close", action=buffer.close },
    ['R'] = { help="reload", action=buffer.reload },
  }
}

local word_hydra = {
  help="word",
  action = { 
    ['right'] = { help="next", action=buffer.word_right, persistent=true },
    ['left'] = { help="prev", action=buffer.word_left, persistent=true },
    ['shift+right'] = { help="extend selection", action=buffer.word_right_extend, persistent=true },
    ['shift+left'] = { help="shrink selection", action=buffer.word_left_extend, persistent=true },
    ['d'] = { help="delete", 
              action= function()
                        textadept.editing.select_word()
                        buffer:delete_back()
                      end, 
              persistent=true },
  }
}

local line_hydra = {
  help="line",
  action = { 
    ['+'] = { help="join", action=textadept.editing.join_lines },
    ['|'] = { help="pipe to bash", 
              action=function()
                       ui.command_entry.run(textadept.editing.filter_through, 'bash')
                     end },
  }
}

hydra.keys['ctrl+f'] = file_hydra
hydra.keys['ctrl+w'] = word_hydra
hydra.keys['ctrl+l'] = line_hydra
```

# Configuration syntax

A basic hydra key binding has the form:

    _key_ = { help=_msg_, action=_action_[, persistent=true] }

where

- _key_ is the key that will trigger the action
- _msg_ is the text that will be displayed in any help messages in the status bar
- _action_ is either a Textadept function call, or another hydra key binding
- `persistent` is optional. If set to `true`, the hydra will remain active