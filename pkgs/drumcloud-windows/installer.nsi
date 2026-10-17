; Operator-authored installer; upstream provides a manual-copy ZIP, not this setup.
Unicode true
!include "x64.nsh"
Name "DrumCloud 1.9.0-beta.8 (operator source build)"
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

Section "VST3, CLAP and notices"
  SetOutPath "$COMMONFILES64\VST3"
  File /r "payload/VST3/*"
  SetOutPath "$COMMONFILES64\CLAP"
  File /r "payload/CLAP/*"
  SetOutPath "$COMMONFILES64\DrumCloud\Notices"
  File /r "payload/Notices/*"
SectionEnd
