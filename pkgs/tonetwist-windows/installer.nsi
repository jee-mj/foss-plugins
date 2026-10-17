; Operator-packaged source build. Not an upstream installer.
Unicode true
!include "x64.nsh"
Name "ToneTwist (operator source build)"
OutFile "${OUTPUT}"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
ShowInstDetails show
Page instfiles

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "This package requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd

Section "Six products: VST3, CLAP and notices"
  SetOutPath "$COMMONFILES64\VST3"
  File /r "payload/VST3/*"
  SetOutPath "$COMMONFILES64\CLAP"
  File /r "payload/CLAP/*"
  SetOutPath "$COMMONFILES64\ToneTwist\Notices"
  File /r "payload/Notices/*"
SectionEnd
