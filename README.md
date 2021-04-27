# PIC18-handwriting
A PIC18 library and toolkit for driving 4-wire resistive touchscreens, to read and recognize handwriting.

# Use
The code should compile and run as-is. To use the touchpad on an EasyPic Pro v7 microntroller, the touchscreen's ribbon cable must be plugged in, and the lower 4 switched on switch four should be turned ON (to the right), to connect ports E and F to the touchpanel.

Any other devices connected to ports E and F should be disconnected as they may interfere with touchpad operation, as should devices connected to PORTS H and J which will affect output display and control respectively. PORTD will flash to show operation and that may cause error to devices attached.

# Extending
Adding new characters is easy; simply add a line to character_lib.s in the same format of 16 values corresponding to the 16 pixels of the touchscreen. Then increment the counter in line 7, and append the ASCII value for the character you have added to the line labeled "characters", currently line 26.

Increasing character resolution does not require architectural changes but is more fiddly. The characters grids in character_lib.s will need to be updated, as will several of the loop and divider variables used throughout. They are all commented.
