# Lan child test

Driver to test the online/offline behavior of lan devices with children

The handlers are hooked up as follows:
- switch on: nothing
- switch off: set offline
- switch level: emit level event, set online if level above 80
- refresh: set online

This can exercise device health on the platform. Note how emitting an
event without setting the device online manually results in being displayed
as online in the app.
