Unlock the EEPROM manufacturer page via a two-step write sequence,
then concatenate 4 secret bytes from 0x80–0x83.

API:
  POST /i2c/write {"addr":N, "data":N}
  POST /i2c/read  {"addr":N}  → {"data":N}
  POST /flag      {"secret":"8hex"}

Unlock sequence:
  write 0xA5 → 0xFE
  write 0x5A → 0xFF
