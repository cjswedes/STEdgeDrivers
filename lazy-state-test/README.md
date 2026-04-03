# Lazy state test

This is a version of the subdriver stress test driver that has handlers setup to test the lazy loading of
device state via the hubs RPC.

Its configured to have 2 devices with a preference to control if the handlers access state or not for capabilities.
* The access type is controlled based on which device is having the command (direct index into state table or get_latest_state api)

On, off, switchLevel all do the state access. Refresh looks at where the state cache table is actually stored.
