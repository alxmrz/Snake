clear:
	@[ -f './bin/snake' ] && rm './bin/snake' || true
compile:
	fasm main.asm
link:
	gcc -no-pie main.o $$(pkg-config --cflags --libs sdl2 SDL2_ttf)  -o ./bin/snake
build: clear compile link
run:
	./bin/snake
bar: build run
run-example:
	fasm example.asm example.o
	ld example.o -o ./bin/example.out -dynamic-linker /lib64/ld-linux-x86-64.so.* -lc -lSDL2
	./bin/example.out