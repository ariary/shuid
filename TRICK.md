##### ⏳...coming soon

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
