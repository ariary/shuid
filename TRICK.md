
### The mechanism
***To obtain persistence:*** the process consists of executing a **legit SUID binary** with **elevated privileged** without interfering with its normal use so that:
* the command does not look suspicious
* if another user makes it, he won't see anything suspicious too and payload will be executed anyway


For example:
```shell
$ sudo ping 198.102.238.1
reply from 198.102.238.1 time=60ms
reply from 198.102.238.1 time=72ms
...

```
Will trigger the payload with root privilege, and nothing suspicious occurs.

## The trick

`BINFMT` module allows us to define a new type of binary type for the device. For that we have to specify an **interpreter** that will be automatically called to treat the new binary type when it is executed.

For example it is possible to execute python script as follow if we register `*.py` with the interpreter `/usr/bin/python`:
```shell
./my_script.py
```


The idea is therefore to register a specific SUID file to `BINFMT` module with custom interpreter (which we control).
