
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

## The tricks

`BINFMT` module allow us to define a new type of binary for the device. For that we have to specify an **interpreter** that will interprets it.

For example it is possible to exec python script as follow if we register `*.py` with the interpret `/usr/bin/python`:
```shell
./my_script.py
```


The idea is therefore to register a specific SUID file to `BINFMT` module with custom interpreter (which we control).
