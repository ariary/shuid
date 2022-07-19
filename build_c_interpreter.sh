#!/bin/bash

#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "usage: ./build.sh \$COMMAND $\RULE_NAME"
    exit 92
fi

export COMMAND=$1
# Tricky and ugly part to make it digestible for 1) Sed execution (/ is forbidden), 2) C execve function
# Hope % is not part of your command
COMMAND_C=""
for args in $1; do
    args=$(printf "\"${args}\"" | tr "/" "%")
    COMMAND_C=$COMMAND_C"\\"$args"\\,"
done
# COMMAND_C="\"$COMMAND_C\""
export RULE_NAME=$2
# use template to construct .c
echo "[*] Build interpreter"
INTERPRETER="src/interpreter/interpreter.c"
cp $INTERPRETER.tpl $INTERPRETER
sed -i "s/CUSTOM_PAYLOAD/${COMMAND_C}/g" $INTERPRETER
sed -i 's/%/\//g' $INTERPRETER
# sed -i "s/CUSTOM_RULE_NAME/${RULE_NAME}/g" $INTERPRETER
# compile interpreter
gcc $INTERPRETER -o bin/interpreter
# compile shuid
echo "[*] Build shuid with interpreter embeded"
nim -o:bin/shuid c -d:INTERPRETER_CONTENT="`base64  -w0 < bin/interpreter`" -d:RULE_NAME="${RULE_NAME}"  --verbosity:0 src/shuid.nim