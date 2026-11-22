# So that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# Same steps as make.bat, but with the shared beebasm: the bundled bin\beebasm.exe
# no longer starts on this machine (missing DLL). Override with BEEBASM=bin\beebasm.exe.
BEEBASM ?= ..\..\Bin\beebasm.exe

.PHONY: all build help

all: build

build:
	if not exist build mkdir build
	$(BEEBASM) -i source\vsync-example.asm -v > build\vsync.txt
	$(BEEBASM) -i source\100hz-example.asm -v > build\100hz.txt
	$(BEEBASM) -i source\screen-example.asm -v > build\screen.txt
	$(BEEBASM) -i source\sprite-example.asm -v > build\sprite.txt
	$(BEEBASM) -i source\make-disc.asm -do build\intro-to-interrupts.ssd

help:
	@echo make        - assemble the examples and build build\intro-to-interrupts.ssd (the steps of make.bat)
	@echo make help   - this list
	@echo run.bat copies the disc into ..\jsbeeb-kieranhj\discs and opens jsbeeb (not run by make)
