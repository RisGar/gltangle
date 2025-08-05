all: build/gltangle

build/gltangle: $(wildcard src/*.gleam)
	gleam build
	gleam run -m gleescript -- --out ./build

clean:
	@if [ -e build/gltangle ]; then trash -F build/gltangle; fi

.PHONY: all clean
