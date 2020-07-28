# Environmental Sensors

In August 4, 2019 I built a circuit using a TMP117 temperature sensor,
Si7021 Humidity sensor, and SGP30 Air Quality sensor. It displays the
data on a 16x2 LCD display. The microcontroller used here is an MSP430G2553.

I never posted the source code because it didn't seem that useful to
others. The code itself is written in assembly and I ended up using a
software i2c instead of the built-in hardware. I've recently received
emails asking for the source, so here it is.

To build it, it requires naken_asm and the Makefile will need to be
modified for your environment (just the path to the include files).

For more information on the circuit:

https://www.mikekohn.net/micro/environmental_sensors.php

