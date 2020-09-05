\ ******************************************************************
\ *	Make Intro to Interrupts disc.
\ ******************************************************************

PUTFILE "build\vsync.bin", "vsync", &1900
PUTFILE "build\100hz.bin", "100hz", &1900
PUTFILE "build\screen.bin", "screen", &2000
PUTFILE "build\sprite.bin", "sprite", &1900
PUTBASIC "source\screen.bas", "scrbas"
