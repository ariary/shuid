build.and.run.shuid:
	@echo "Only for debugging purpose";nim -o:bin/shuid c -r -d:InterpreterContent="`cat bin/interpreter`" src/shuid.nim

build.shuid:
	nim -o:bin/shuid c -d:InterpreterContent="`cat bin/interpreter`" src/shuid.nim