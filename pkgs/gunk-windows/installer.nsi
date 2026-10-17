; Operator installer, independent of upstream's manual-copy ZIP target.
Unicode true
!include "x64.nsh"
Name "JQ Gunk 0.2.2 (operator source build)"
OutFile "${OUTPUT}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
ShowInstDetails show
Page instfiles

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "This VST3 requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd

Section "VST3, factory data and notices (current user)"
  SetShellVarContext current
  SetOutPath "$LOCALAPPDATA\Programs\Common\VST3"
  File /r "payload/VST3/*"
  SetOutPath "$APPDATA\JQGunk"
  File /r "payload/AppData/JQGunk/*"
  SetOutPath "$LOCALAPPDATA\Programs\JQGunk\Notices"
  File /r "payload/Notices/*"
  File "payload/INSTALL.txt"
SectionEnd
