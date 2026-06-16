An I2C EEPROM simulator at http://target:8108 has a locked manufacturer page.
Sending a two-step unlock sequence to reserved addresses 0xFE and 0xFF
opens the hidden page at 0x80–0x83.

Hint: look for magic bytes like 0xA5 / 0x5A or 0x55 / 0xAA.
