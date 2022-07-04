-- Copyright 2022 Amy de Buitléir. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- TODO: Put description here
module('lsp')]]

local M = {}

local util = require('util')

M.keys = {}

local CTRL, ALT, CMD, SHIFT = 'ctrl+', 'alt+', 'cmd+', 'shift+'
if CURSES then ALT = 'meta+' end

local current_key_map = M.keys
local hydra_active = false

local function map(func, array)
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

local function describe_key_map (m)
  if m.help then
    help_msgs = { m.help .. ":" }
  else
    help_msgs = {}
  end
  for k, v in pairs(m.action) do
    table.append(help_msgs, k .. ") " .. v.help)
  end
  return tab.concat(help_msgs, "\n")
end

local function start_hydra (key_map)
  current_key_map = key_map.action
  hydra_active = true
  ui.statusbar_text = describe_key_map(key_map)
end

local function reset_hydra ()
  current_key_map = M.keys
  hydra_active = false
  ui.statusbar_text = ""
end

local function run_hydra(key_map)
  action = key_map.action
  
  if type(action) == "table" then
    start_hydra(key_map)
    return
  else
    -- invoke the action mapped to this key
    action()
    -- should the hydra stay active?
    if not key_map.persistent then
      reset_hydra()
    end
    return
  end
end

local function handle_key_seq (key_seq)
  --print("handling", key_seq)
  local active_key_map = current_key_map[key_seq]

  if active_key_map == nil then
    -- An unexpected key cancels any active hydra
    if hydra_active then
      reset_hydra()
    end
    -- Let Textadept or another module handle the key
    return
  else    
    run_hydra(active_key_map)
    -- We've handled the key, no need for Textadept or another module to act
    return true
  end
end

events.connect(events.INITIALIZED, function()
  reset_hydra()
end)

events.connect(events.KEYPRESS, function(code, shift, control, alt, cmd, caps)
  --print(code, keys.KEYSYMS[code], shift, control, alt, cmd, caps)
  
  if caps and (shift or control or alt or cmd) and code < 256 then
    code = string[shift and 'upper' or 'lower'](string.char(code)):byte()
  end
  
  local key = code >= 32 and code < 256 and string.char(code) or keys.KEYSYMS[code]
  if not key then return end
  
  -- Since printable characters are uppercased, disable shift.
  if shift and code >= 32 and code < 256 then shift = false end

  -- For composed keys on macOS, ignore alt.  
  if OSX and alt and code < 256 then alt = false end
  
  local key_seq = (control and CTRL or '') .. (alt and ALT or '') .. (cmd and OSX and CMD or '') ..
    (shift and SHIFT or '') .. key
    
  return(handle_key_seq(key_seq))
end, 1)

return M
