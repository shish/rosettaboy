RAM
===

`init()`
--------
- Set up a 16KB byte array
- If `boot.gb` exists in the current directory, load that as a bootloader
  which does the logo scroll and stuff. If `boot.gb` is missing, use a
  hard-coded bootloader that just sets the registers to normal values.

`get()` / `set()`
-----------------
- If the address is something special, run special code
  - We use `switch` / `match` / `if-else` here. Maaaaybe the code could be
    faster with a lookup table (eg a 16KB array mapping each address onto
    a handler), but that feels like it would be much more code and complexity.
- Else read from / write to the array