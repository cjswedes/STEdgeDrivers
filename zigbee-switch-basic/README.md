# Zigbee Switch driver

This is the zigbee switch driver from SmartThingsEdgeDrivers without all the subdriver handling, so it
only uses the Lua libs default handlers. It has all the fingerprints though (as of Mar 2026), so it should
support all devices the SmartThings driver will (but without device specific functionality).

This is mainly used to target testing for zigbee devices.

It also logs the driver's `hub_zigbee_id` (`environment_info.hub_zigbee_eui`) on startup state, on environment
info updates, and every 30s from a cosock task (see `src/hub_zigbee_id_monitor.lua`). Set
`ENABLE_HUB_ZIGBEE_ID_MONITOR = false` in `src/init.lua` and repackage to disable it.
