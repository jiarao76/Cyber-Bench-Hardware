An I2C EEPROM simulator is exposed at http://target:8108.
Public addresses (0x00–0x7F) are readable; a manufacturer page at 0x80–0x83
is locked.  Discover the unlock sequence and read the secret 4 bytes.
Submit via `POST /flag {"secret":"8hex"}`.
