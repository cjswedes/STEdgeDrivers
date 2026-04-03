-- Copyright 2025 SmartThings, Inc.
-- Licensed under the Apache License, Version 2.0

-- The only reason we need this is because of supported_capabilities on the driver template
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local configurationMap = require "configurations"
local CONFIGURE_REPORTING_RESPONSE_ID = 0x07
local SIMPLE_METERING_ID = 0x0702
local ELECTRICAL_MEASUREMENT_ID = 0x0B04
local version = require "version"

local lazy_handler
if version.api >= 15 then
  lazy_handler = require "st.utils.lazy_handler"
else
  lazy_handler = require
end

local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("switch(%d)")
  return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
end

local function endpoint_to_component(device, ep)
  local switch_comp = string.format("switch%d", ep)
  if device.profile.components[switch_comp] ~= nil then
    return switch_comp
  else
    return "main"
  end
end

local device_init = function(driver, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)

  local configuration = configurationMap.get_device_configuration(device)
  if configuration ~= nil then
    for _, attribute in ipairs(configuration) do
      device:add_configured_attribute(attribute)
    end
  end

  local ias_zone_config_method = configurationMap.get_ias_zone_config_method(device)
  if ias_zone_config_method ~= nil then
    device:set_ias_zone_config_method(ias_zone_config_method)
  end
  local device_lib = require "st.device"
  if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
    local find_child = require "lifecycle_handlers.find_child"
    device:set_find_child(find_child)
  end
end

local handle_refresh = function(driver, device, cmd)

  -- This sends ReadReportingConfiguration commands for all coinfigured attributes on the device
  local device_management = require "st.zigbee.device_management"
  local socket = require "cosock.socket"
  local log = require "log"
  local messages = require "st.zigbee.messages"
  local zcl_messages = require "st.zigbee.zcl"
  local data_types = require "st.zigbee.data_types"
  local zcl_cmds = require "st.zigbee.zcl.global_commands"
  local constants = require "st.zigbee.constants"
  local configured_attrs = device:get_field("__configured_attributes") or {}
--[[
  device:configure() -- alt to send configuration commands again
--]]

--[[
  log.info_with({hub_logs = true}, "Re-sending ConfigureReporting for attributes: " .. tostring(configured_attrs))
  for cluster, attrs in pairs(configured_attrs) do
    for _, ep in pairs(device.zigbee_endpoints) do
      if device:supports_server_cluster(cluster, ep.id) then
        for _, config in pairs(attrs) do
          device:send(device_management.attr_config(device, config):to_endpoint(ep.id))
        end
      end
    end
  end
  socket.sleep(2)
--]]

--[[
  log.info_with({hub_logs = true}, "Sending ReadReportingConfiguration for attributes: " .. tostring(configured_attrs))
  for cluster, attrs in pairs(configured_attrs) do
    for _, ep in pairs(device.zigbee_endpoints) do
      if device:supports_server_cluster(cluster, ep.id) then
        local attr_records = {}
        for _, config in pairs(attrs) do
          table.insert(attr_records, zcl_cmds.ReadReportingConfiguration.ReadReportingConfigurationAttributeRecord(0, config.attribute))
        end
        local read_reporting_body = zcl_cmds.ReadReportingConfiguration(attr_records)
        local addr_header = messages.AddressHeader(constants.HUB.ADDR, constants.HUB.ENDPOINT, device:get_short_address(), device:get_endpoint(cluster), constants.HA_PROFILE_ID, cluster)
        local zcl_header = zcl_messages.ZclHeader(
          {
            cmd = data_types.ZCLCommandId(read_reporting_body.ID)
          }
        )
        local message_body = zcl_messages.ZclMessageBody({
          zcl_header = zcl_header,
          zcl_body = read_reporting_body
        })
        local tx_msg = messages.ZigbeeMessageTx(
          {
            address_header = addr_header,
            body = message_body
          }
        )
        device:send(tx_msg:to_endpoint(ep.id))
      end
    end
  end
--]]
end

local zigbee_switch_driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.colorControl,
    capabilities.colorTemperature,
    capabilities.powerMeter,
    capabilities.energyMeter,
    capabilities.motionSensor,
    capabilities.illuminanceMeasurement,
    capabilities.relativeHumidityMeasurement,
    capabilities.temperatureMeasurement,
  },
  -- sub_drivers = require("sub_drivers"),
  zigbee_handlers = {
    global = {
      [SIMPLE_METERING_ID] = {
        [CONFIGURE_REPORTING_RESPONSE_ID] = configurationMap.handle_reporting_config_response
      },
     [ELECTRICAL_MEASUREMENT_ID] = {
        [CONFIGURE_REPORTING_RESPONSE_ID] = configurationMap.handle_reporting_config_response
      }
    }
  },
  current_config_version = 1,
  lifecycle_handlers = {
    init = configurationMap.reconfig_wrapper(device_init),
    added = lazy_handler("lifecycle_handlers.device_added"),
    infoChanged = lazy_handler("lifecycle_handlers.info_changed"),
    doConfigure = lazy_handler("lifecycle_handlers.do_configure"),
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = handle_refresh
    },
  },
  health_check = false,
}
defaults.register_for_default_handlers(zigbee_switch_driver_template,
  zigbee_switch_driver_template.supported_capabilities,
  {native_capability_cmds_enabled = true, native_capability_attrs_enabled = true}
)
local zigbee_switch = ZigbeeDriver("zigbee_switch", zigbee_switch_driver_template)
zigbee_switch:run()
