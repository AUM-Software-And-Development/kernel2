catall:
	cat boot.bin bytetable.bin kernel.bin editor.bin > temp.bin;\
	dd if=zero of=os.bin bs=512 count=2880;\
	dd if=temp.bin of=os.bin conv=notrunc;\
	rm temp.bin
	# pads binary with zeros to reach actual floppy size.

fasmall:
	fasm ../boot.asm
	mv ../boot.bin ./
	fasm ../kernel.asm
	mv ../kernel.bin ./
	fasm ../bytetable.asm
	mv ../bytetable.bin ./
	fasm ../editor.asm
	mv ../editor.bin ./

rbios:
	rm *.bin
	make fasmall
	make catall

rboot:
	rm *.bin
	make fasmall
	make catall
	qemu-system-i386 -fda os.bin

sboot:
	make fasmall
	make catall
	qemu-system-i386 -fda os.bin

bios:
	qemu-system-i386 -cdrom os.iso

boot:
	qemu-system-i386 -fda os.bin

