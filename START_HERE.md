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
- `bin/` - an old `beebasm.exe`, `jsbeeb.bat`, `runme.url`.
- `build/` (gitignored) - listings and `intro-to-interrupts.ssd`.

## Build and run
- `make`: the same steps as `make.bat` (assemble the four examples, then `build\intro-to-interrupts.ssd`) but with the shared beebasm `..\..\Bin\beebasm.exe`. Tested 2026-11-22, works. `make help` lists targets.
- `make.bat` itself no longer works: the bundled `bin\beebasm.exe` fails to start (missing DLL, exit 0xC0000135).
- Run: `run.bat` copies the disc into `..\jsbeeb-kieranhj\discs` and opens `bin\runme.url` (a local jsbeeb on localhost:8000, started by `bin\jsbeeb.bat`, which still points at `OneDrive\BEEB\Repos\jsbeeb-kieranhj` and uses Python 2). Easier: open the .ssd at https://bbc.xania.org.

## Local changes
- None: working tree clean, no stashes, no snapshot branches.

## Status and next steps
- Finished talk material (2020). Nothing outstanding found.

## See also
- `readme.asm` (the tutorial text). D:\beeb\mine\jsbeeb-kieranhj (the local jsbeeb run.bat expects).
