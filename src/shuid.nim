import osproc
import terminal

proc checkBinfmt(unprivileged:bool):bool=
  ## Different checks to verify that the binfmt config allow the exploit
  ## - check if BINFMT module is loaded in kernel(config file)
  ## - check if BINFMT is mount
  ## - check if BINFMT is enabled 
  ## - check if the register file is writable by user if unprivileged mode
  
  # # search module in boot config files
  # let moduleExist = execCmdEx("grep 'BINFMT_MISC' /boot/config-`uname -r`").exitCode
  # if moduleExist != 1:
  #   styledEcho("⚠️ Do not find ",fgYellow,"BINFMT_MISC module ",fgWhite,"in /boot/config directory")
  
  # is mount?
  let isMount = execCmdEx("mount | grep binfmt_misc")
  if isMount.exitCode != 0:
    styledEcho("⚠️ Failed to ",fgYellow,"execute mount",fgWhite,": ",isMount.output)
    styledEcho("❌ binfmt kernel feature",fgRed," seems to be disabled")
    return false
  elif isMount.output == "":
    styledEcho("⚠️ binfmt is ",fgYellow,"not mounted")
    styledEcho("❌ binfmt kernel feature",fgRed," seems to be disabled")
    styledEcho(fgBlue, "Try mounting binfmt: mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc")
    return false

  # check if enable
  #TODO: No output??
  let enabled = execCmdEx("cat /proc/sys/fs/binfmt_misc/status").output
  echo enabled
  case enabled
  of "1","enabled": discard
  else: 
    styledEcho("❌ binfmt kernel feature",fgRed," seems to be disabled")
    styledEcho(fgBlue, "Try enabling binfmt with: echo 1 > /proc/sys/fs/binfmt_misc/status")
    return false
  
  # register writable
  if unprivileged:
    let isRegisterWritable = execCmdEx("test -w /proc/sys/fs/binfmt_misc/register").exitCode
    if isRegisterWritable!=0:
      styledEcho("⚠️ /proc/sys/fs/binfmt_misc/register ",fgRed," is not writable by users")
      #TODO: ask user if he wants to continue (with an alternative)

  return true

proc searchSuid(dir, file: string,chooseFile: bool): string=
  if file != "":
    return file
  return "toto"

proc exploit(suid, payload: string): void=
  #[
  Obtain Magic number
  Interpreter (nim/C)
    -> Execute suid after
  ]#
  echo("\n🌒  binfmt has been exploited to maintain privileged persistence.")
  echo "\e[2mWelcome in the shadow\e[0m"

proc shuid(
  unprivileged = false, 
  check = true, 
  file = "", 
  searchDir="/bin", 
  chooseFile = false, 
  payload = "/bin/sh",
  noExec=false
  ): void =
  if check:
    if checkBinfmt(unprivileged):
      styledEcho("✔️  binfmt kernel feature is",fgGreen," enabled")
    else: quit(QuitSuccess)

  # Search SUID file to hide our payload
  let suid = searchSuid(searchDir,file,chooseFile)
  if suid != "": exploit(suid,payload)
  else:
    styledEcho("❌ No SUID file in ",fgRed,searchDir)
    quit(QuitSuccess)


when isMainModule:
  import cligen;  dispatch shuid, help={"unprivileged": "run in unprivileged mode (binfmt not writable)",
  "check": "perform exploit requirement checks",
  "file": "SUID file to use",
  "searchDir": "directory use to find SUID file",
  "chooseFile": "choose SUID file to use from the list (if not taken randomly)",
  "payload": "payload to execute to maintain peristance (run with privileged permissions)",
  "noExec": "do not exec SUID file"
  }