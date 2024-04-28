comp:
	fasm main.asm
link:
	ld -m elf_i386 test.o -o snake
spc:
	gcc -no-pie main.o -o ./bin/snake
run-asm: comp spc
	./bin/snake
run-example:
	fasm example.asm example.o
	ld example.o -o ./bin/example.out -dynamic-linker /lib64/ld-linux-x86-64.so.* -lc -lSDL2
	./bin/example.out