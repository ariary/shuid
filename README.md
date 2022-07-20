<div align=center>
<img src=./img/icon2.png>
<sup>*<i>«shuid» stands for shadow SUID file</i></sup>
<pre><code><strong>Privileged persistence 
<br>without using noisy and detectable SUID 
<br>using <i>binfmt</i> Kernel feature instead</strong>
Also a good way to learn Nim and something new
</code></pre>
</div>

|👁️ Persistence demo|
|:---:| 
|![demo](img/shuid-demo.gif)|

## Like at home! 🏡 <sup>(persistence)</sup>

* Build `shuid` (needs `gcc` & `nim`):<br><pre><code>./build.sh [PERSISTENCE_CMD] [RULE_NAME]</code></pre>

* Transfer it on target
* Run it!<br><pre><code>sudo ./shuid</code></pre>

And that's all, you are under the radar. The process to obtain root shell will be outputted 


## Road to root! 🛣 <sup>(privesc)</sup>

Under certain circumstances, the trick can be used to gain elevated privileged. You can test it with:

```shell
./shuid --privesc
```

## [Understand the trick](TRICK.md)

## Limitations & enhancement
* Interpeter content is provided at compilation time. However nim binaries are too big to be contained in command line
  * provide a way to retrieve interpreter content from the network (http or whatever)
  * current (ugly) workaround: write the base64 encoded file content directly within the variable `INTERPRETER_CONTENT` in `src/shuid.nim`
* Only the Go interpreter works in a stealthy way ie:
  * simulate normal behavior of the SUID file (by forking it and execute with tty)
  * launch in the background the payload


<div align=center>
<sup>
All credits goes to <a href= https://github.com/Sentinel-One/shadowsuid/>Dor Dankner</a>, <a href= https://github.com/toffan/binfmt_misc>toffan</a> and <a href= https://www.hackthebox.com/home/users/profile/590762>uco2KFH</a> 
</sup>
</div>
