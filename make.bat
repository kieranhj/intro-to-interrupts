@echo off
echo Building examples...
bin\beebasm.exe -i source\vsync-example.asm -v > build\vsync.txt
bin\beebasm.exe -i source\100hz-example.asm -v > build\100hz.txt
bin\beebasm.exe -i source\screen-example.asm -v > build\screen.txt
bin\beebasm.exe -i source\plot-example.asm -v > build\plot.txt
echo Building disc image...
bin\beebasm.exe -i source\make-disc.asm -do build\intro-to-interrupts.ssd
