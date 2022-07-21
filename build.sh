#!/bin/bash

usage(){
    echo "usage: ./build.sh \$COMMAND \$RULE_NAME \$INTERPRETER_LANG"
    echo -e "\t\$INTERPRETER_LANG value can be: go, c, nim"
    echo -e "\t\$COMMAND should not embed '%' character. If it is the case, change the code of the script accordingly"
    exit 92
}

if [[ $# -ne 3 ]]; then
    usage
fi

# Take params
export COMMAND=$1
export RULE_NAME=$2
export INTERPRETER_LANG=$3
if [ $INTERPRETER_LANG != "go" ] && [ $INTERPRETER_LANG != "c" ] && [ $INTERPRETER_LANG != "nim" ]; then
    echo "wrong \$INTERPRETER value!"
    usage
fi

# Reconstruct COMMAND var to pass through sed + fit INTERPRETER_LANG syntax:
# tricky and ugly part to make it digestible for 1) Sed execution (/ is forbidden), 2) C execve function
# hope % is not part of your command
COMMAND_IN_INTERPRETER_LANG=""
if [ $INTERPRETER_LANG == "go" ]; then
    # nothing special, just a filter for sed
    COMMAND_IN_INTERPRETER_LANG=$(echo $COMMAND | tr / %)
fi
if [ $INTERPRETER_LANG == "nim" ] || [ $INTERPRETER_LANG == "c" ]; then
    # filter for sed + adapt to fit code
    for args in $COMMAND; do
        args=$(printf "\"${args}\"" | tr "/" "%")
        COMMAND_IN_INTERPRETER_LANG=$COMMAND_IN_INTERPRETER_LANG"\\"$args"\\,"
    done
fi

# Use template to construct interpreter code
echo "[*] Build interpreter"
INTERPRETER="src/interpreter/interpreter."$INTERPRETER_LANG
cp $INTERPRETER.tpl $INTERPRETER
sed -i "s/CUSTOM_PAYLOAD/${COMMAND_IN_INTERPRETER_LANG}/g" $INTERPRETER # put command in template
sed -i 's/%/\//g' $INTERPRETER  # undo sed filter
sed -i "s/CUSTOM_RULE_NAME/${RULE_NAME}/g" $INTERPRETER # put rule name in template

# Compile interpreter
if [ $INTERPRETER_LANG == "go" ]; then
    # nothing special, just a filter for sed
    go build -o bin/interpreter $INTERPRETER
fi
if [ $INTERPRETER_LANG == "nim" ]; then
    nim -o:bin/interpreter c -d:release --opt:size --verbosity:0 $INTERPRETER
fi
if [ $INTERPRETER_LANG == "c" ]; then
    gcc $INTERPRETER -o bin/interpreter
fi
# build b64 encoded version
base64 -w0 < bin/interpreter > bin/interpreter.b64

# Compile shuid
echo "[*] Build shuid with interpreter embeded"
nim -o:bin/shuid c -d:RULE_NAME="${RULE_NAME}"  --verbosity:0 src/shuid.nim
