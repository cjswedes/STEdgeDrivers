# Subdriver stress test

Driver with many subdrivers to handle different messages.

Driver spins up X devices which will be setup to be toggled by a routine that is triggered by the Routine trigger device.
Capability event is emitted for each cmd to allow for pairing the timing of the device cmd/events. `toggle-device.sh`
script can be used to toggle the trigger device at a regular interval

This is used in conjunction with logs analysis to measure the latency in a situation where a routine is triggering
all devices to be toggled at once.

The config drivers
* the subdriver can handle distribution for which subdriver handles which devices
* the number of total devices/subdrivers
* if random healthstate changes are issued for devices
