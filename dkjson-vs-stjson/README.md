# dkjson vs st.json comparison driver

This driver attempts to validate the `encode`/`decode` apis for dkjson and st.json
and assert that they are equal.

Spawns a cosock task on device init to run the tests