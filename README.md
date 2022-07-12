# textadept-hydra

A plugin for the textadept editor, modeled on the emacs [hydra](https://github.com/abo-abo/hydra) plugin.
It allows you to define key maps for related commands, with the ability to easily repeat commands by using a single keystroke. 
When a hydra is active, the available keys and actions are displayed in the status bar,
so you don't need to memorise them.

For example, the following configuration would allow you to type `ctrl+w` to trigger a word navigation hydra,
in which you can use the left and right arrow keys to navigate by words.
Any other key will exit the hydra.

```
local hydra = require('hydra')

local word_hydra = hydra.create({
  { key='left', help='prev', action=buffer.word_left, persistent=true },
  { key='right', help='next', action=buffer.word_right, persistent=true },
})

hydra.keys = hydra.create({
  { key='ctrl+w', help="word", action=word_hydra },
})
```

# Installation

In your textadept configuration directory, type

    git clone git@github.com:mhwombat/textadept-hydra.git modules/hydra

Configure your desired hydra key bindings in `init.lua`.
Here's a simple example that illustrates the flexibility of textadept-hydra:

```
local hydra = require('hydra')

local word_hydra = hydra.create({
  { key='left', help='prev', action=buffer.word_left, persistent=true },
  { key='right', help='next', action=buffer.word_right, persistent=true },
  { key='shift+right', help='extend selection', action=buffer.word_right_extend, persistent=true },
  { key='shift+left', help='shrink selection', action=buffer.word_left_extend, persistent=true },
})

local line_hydra = hydra.create({
  { key='j', help="join", action=textadept.editing.join_lines },
  { key='|', 
    help="pipe to bash", 
    action=function()
             ui.command_entry.run(textadept.editing.filter_through, 'bash')
           end },
})

hydra.keys = hydra.create({
  { key='ctrl+w', help="word", action=word_hydra },
  { key='ctrl+l', help="line", action=line_hydra }
})
```

# Configuration syntax

A basic hydra key binding has the form:

**{ key=**_key_**, help=**_msg_**, action=**_action_**[, persistent=true] }**

where

- _key_ is the key that will trigger the action.
- _msg_ is the hint that will be displayed in the popup.
  This field is only used in nested hydras.
  If the action is persistent, `*` will be displayed after it.
  If the action is another hydra, `...` will be displayed after it.
- _action_ is either a Textadept function call, or another hydra key binding.
- `persistent` is optional. If set to `true`, the hydra will remain active after the action is performed.
  Any key that is not bound in this hydra will terminate the hydra.
  
# Sample configurations
  
- [mhwombat's config](https://github.com/mhwombat/dotWombat/blob/master/.config/textadept/init.lua)

Do you have a configuration that you would like to share? Please [open an issue](https://github.com/mhwombat/textadept-hydra/issues).

# Using with textredux

The hydra key bindings are separate from the normal textadept key bindings, 
so the Textredux `hijack` function doesn't have the intended effect.
However, you can use the Textredux API. 
For example, instead of using `io.open_file()` as a hydra action, use `textredux.fs.open_file`.

# Modifying key bindings on the fly

You can call the following function to change key bindings on-the-fly.

**hydra.bind(hydra, { key=**_key_**, help=**_msg_**, action=**_action_**[, persistent=true] })**

where `hydra` is something you created using `hydra.create`.
If you want to change a top-level key binding, pass `hydra.keys` as the first parameter to `hydra.bind`.

# Support

Have a question about how to use textadept-hydra? Please [start a discussion](https://github.com/mhwombat/textadept-hydra/discussions).

Find a bug in textadept-hydra? Please [open an issue](https://github.com/mhwombat/textadept-hydra/issues).
