-- Copyright 2022 Amy de Buitléir. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- TODO: Put description here
module('lsp')]]

local M = {}

M.keys = {}

local CTRL, ALT, CMD, SHIFT = 'ctrl+', 'alt+', 'cmd+', 'shift+'
if CURSES then ALT = 'meta+' end

local current_key_map = M.keys
local current_hint = ""
local hydra_active = false
local parsed_keys = {}

--
-- Utility functions
--

local function map(func, array)
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

local function pretty_key(c)
  if c == ' ' then return 'space' end
  if c == '\t' then return 'tab' end
  return c
end

local function raw(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. raw(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function dump(leader, t)
  for k,v in pairs(t) do
    s = leader .. pretty_key(k) .. ': '
    if type(v.action) == 'table' then
      ui.print(s .. v.hint)
      dump(leader .. '  ', v.action)
    else
      ui.print(s .. tostring(v.action))
    end
  end
end

function M.print_keys()
  dump('', parsed_keys)
end

--
-- Functions to convert the user's keymap configuration to a form that
-- is more convenient for this module.
--

local function describe_hydra (x)
  local entries = {}
  if x.help then
    table.insert(entries, x.help .. ': ')
  end
  for k,v in pairs(x.action) do
    --ui.print('v=', raw(v))
    s = pretty_key(v.key) .. ') ' .. v.help
    if v.persistent then s = s .. '*' end
    if type(v.action) == 'table' then s = s .. '...' end
    table.insert(entries, s)
  end
  return table.concat(entries, '\n')
end

local function parse (x)
  local result = {}
  for k,v in pairs(x) do
    local v2 = { persistent=v.persistent }
    if type(v.action) == 'table' then
      v2.hint = describe_hydra(v)
      v2.action = parse(v.action)
    else
      v2.action = v.action
    end
    if result[v.key] then
      ui.print('[hydra] WARNING: duplicate binding for key: ' .. pretty_key(v.key) .. ' "' .. v.help .. '"')
    else
      result[v.key] = v2
    end
  end
  return result
end

--
-- Functions for reacting to keypress events
--

local function start_hydra (key_map)
  current_key_map = key_map.action
  hydra_active = true
  current_hint = key_map.hint
  view:call_tip_show(buffer.current_pos, current_hint)
end

local function maintain_hydra ()
  view:call_tip_show(buffer.current_pos, current_hint)
end

local function reset_hydra ()
  current_key_map = parsed_keys
  hydra_active = false
  view:call_tip_cancel()
end

local function run(action)
  -- temporarily disable hydra
  local current_key_map_before = current_key_map
  local hydra_active_before = hydra_active
  current_key_map = nil
  hydra_active = false
  view:call_tip_cancel()
  
  -- run the action
  action()
  
  -- re-enable hydra
  current_key_map = current_key_map_before
  hydra_active = hydra_active_before
end

local function run_hydra(key_map)
  action = key_map.action
  
  if type(action) == 'table' then
    start_hydra(key_map)
    return
  else
    -- invoke the action mapped to this key
    run(action)
    -- should the hydra stay active?
    if key_map.persistent then
      maintain_hydra()
    else
      reset_hydra()
    end
    return
  end
end

local function handle_key_seq (key_seq)
  --print('handling', key_seq)
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

--
-- Main code for module
--

events.connect(events.INITIALIZED, function()
  parsed_keys = parse(M.keys)
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
    
  return handle_key_seq(key_seq)
end, 1)

return M
