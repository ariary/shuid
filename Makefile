build.and.run.shuid:
	@echo "Only for debugging purpose";nim -o:bin/shuid c -r -d:INTERPRETER_CONTENT="`base64  -w0 < bin/interpreter`" src/shuid.nim

build.shuid:
	nim -o:bin/shuid c -d:INTERPRETER_CONTENT="`base64  -w0 < bin/interpreter`" src/shuid.nim