-- Copyright 2025 SmartThings, Inc.
-- Licensed under the Apache License, Version 2.0

-- Test instrumentation for logging the driver's view of the hub zigbee id (environment_info.hub_zigbee_eui)
-- on startup state, on environment info updates, and periodically from a cosock task.
local cosock = require "cosock"
local log = require "log"
local base64 = require "base64"
local Driver = require "st.driver"

local INTERVAL_S = 5

local hub_zigbee_id_monitor = {}

-- Re-encode the decoded eui as base64 so it matches the raw hub_zigbee_id format the hub sends
local function eui_to_str(eui)
  if eui == nil then
    return "nil"
  end
  return base64.encode(eui)
end

--- Wraps the default environment info handler so the hub zigbee id can be logged before and after the update
function hub_zigbee_id_monitor.environment_info_handler(driver, environment_channel)
  local msg_type, msg_val = environment_channel:receive()
  local old_eui = (driver.environment_info or {}).hub_zigbee_eui

  -- Hand the already received message to the default handler so its behavior is unchanged
  Driver.environment_info_handler(driver, {
    receive = function() return msg_type, msg_val end
  })

  if msg_type == "zigbee" then
    local new_eui = driver.environment_info.hub_zigbee_eui
    log.info_with({hub_logs = true}, string.format(
      "[hub_zigbee_id monitor] environment update (zigbee) raw=%s old=%s new=%s changed=%s",
      tostring(type(msg_val) == "table" and msg_val.hub_zigbee_id or nil),
      eui_to_str(old_eui),
      eui_to_str(new_eui),
      tostring(old_eui ~= new_eui)
    ))
  else
    log.debug_with({hub_logs = true}, string.format("[hub_zigbee_id monitor] environment update (%s)", tostring(msg_type)))
  end
end

--- Called by the default driver lifecycle handler after the startup state has been processed
function hub_zigbee_id_monitor.handle_startup_state_received(driver)
  log.info_with({hub_logs = true}, string.format(
    "[hub_zigbee_id monitor] startup state hub_zigbee_id=%s",
    eui_to_str(driver.environment_info.hub_zigbee_eui)
  ))
end

--- Spawn a cosock task that logs the current hub zigbee id every INTERVAL_S seconds
function hub_zigbee_id_monitor.spawn_periodic_logger(driver)
  cosock.spawn(function()
    local last_eui = driver.environment_info.hub_zigbee_eui
    while true do
      cosock.socket.sleep(INTERVAL_S)
      local current_eui = driver.environment_info.hub_zigbee_eui
      log.info_with({hub_logs = true}, string.format(
        "[hub_zigbee_id monitor] periodic hub_zigbee_id=%s (%s)",
        eui_to_str(current_eui),
        current_eui ~= last_eui and "CHANGED since last tick" or "unchanged"
      ))
      last_eui = current_eui
    end
  end, "hub_zigbee_id monitor")
end

return hub_zigbee_id_monitor
