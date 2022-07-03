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

--local function get_keys(t)
--  local ks={}
--  for k,_ in pairs(t) do
--    table.insert(ks, k)
--  end
--  return k
--end

local function expecting(key)
  for k,_ in pairs(current_key_map) do
    print("comparing",k,key)
    if k == key then 
      print("found a match!")
      return true
    end
  end
  return false
end

local function describe_key_map (m)
  help_msg = m.help .. ":"
  for k, v in pairs(m.action) do
    help_msg = help_msg .. "\n" .. k .. ") " .. v.help
  end
  return help_msg
end

local function start_hydra (key_map)
  print("Entering a hydra")
  current_key_map = key_map.action
  hydra_active = true
  ui.statusbar_text = describe_key_map(key_map)
end

local function reset_hydra ()
  print("Exiting hydra")
  current_key_map = M.keys
  hydra_active = false
  ui.statusbar_text = "exit hydra"
end

local function run_action(key_seq)
  action = current_key_map[key_seq]
  print("action", action)
  
  if type(action) == "table" then
    start_hydra(action)
    return
  end
    
  print("do the thing")
  print(f"DEBUG action=", key_map.action)
  print("DEBUG terminate=", key_map.terminate)
  return
end

local function handle_key_seq (key_seq)
  print("handling", key_seq)
  print(">>> DEBUG")
  util.print_table(current_key_map)
  print("<<< DEBUG")
  expected = expecting(key_seq)
  
  if expected then
    run_action(key_seq)
    return true
  end
  
  if hydra_active then
    reset_hydra()
    return true
  end
end

events.connect(events.INITIALIZED, function()
  print("initialising hydra")
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
