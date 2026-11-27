# intro-to-interrupts: start here

Teaching material: "Intro to Interrupts on the BBC Micro (part #2)", Kieran Connell's vABUG Masterclass #2 (10 Sept 2020). A set of small 6502 / beebasm examples (vsync, 100 Hz timer, screen, sprite plotting) on one disc, with the tutorial text in `readme.asm`. Docs + example code.

| | |
|---|---|
| GitHub | https://github.com/kieranhj/intro-to-interrupts (public) |
| Local path | D:\beeb\mine\intro-to-interrupts (moved from OneDrive\BEEB\Repos\intro-to-interrupts on 2026-11-22) |
| Branch | master (only branch) |
| Last commit | 2020-09-14: Fairly critical typo! |

## What's in here
- `readme.asm` - the tutorial itself (long commented text, also goes on the disc); `README.md` is just a title.
- `source/` - `vsync-example.asm`, `100hz-example.asm`, `screen-example.asm` (+ `screen.bas`), `sprite-example.asm` + `sprite-plot.asm`, `make-disc.asm`.
- `data/` - `sprite.png` / `sprite.bin`.
- `bin/` - `beebasm.exe` (current 64-bit build since 2026-11-22), `jsbeeb.bat`, `runme.url`.
- `build/` (gitignored) - listings and `intro-to-interrupts.ssd`.

## Build and run
- `make`: the same steps as `make.bat` (assemble the four examples, then `build\intro-to-interrupts.ssd`). Tested 2026-11-22, works. `make help` lists targets.
- `make.bat` works too. Its old 32-bit `bin\beebasm.exe` needed a missing VC++ 2010 DLL, so it was replaced with the current build on 2026-11-22.
- Run: jsbeeb-kieranhj, the local jsbeeb clone it used, was deleted on 2026-11-27 (the fork is on GitHub), and `run.bat` with it; open the disc at https://bbc.xania.org or in b2. (`bin\jsbeeb.bat` and `bin\runme.url` are leftovers of that setup.)

## Local changes
- None: working tree clean, no stashes, no snapshot branches.

## Status and next steps
- Finished talk material (2020). Nothing outstanding found.

## See also
- `readme.asm` (the tutorial text).
