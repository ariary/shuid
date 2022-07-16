proc shuid(
  unprivileged = false, 
  check = true, 
  file = "", 
  searchDir="/bin", 
  chooseFile = false, 
  payload = "/bin/sh",
  noExec=false
  ): void = echo chooseFile

when isMainModule:
  import cligen;  dispatch shuid, help={"unprivileged": "run in unprivileged mode (binfmt not writable)",
  "check": "perform exploit requirement checks",
  "file": "SUID file to use",
  "searchDir": "directory use to find SUID file",
  "chooseFile": "choose SUID file to use from the list (if not taken randomly)",
  "payload": "payload to execute to maintain peristance (run with privileged permissions)",
  "noExec": "do not exec SUID file"
  }