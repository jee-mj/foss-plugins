; Operator-owned staging, explicitly includes console (unlike upstream NSIS).
Unicode true
!include "x64.nsh"
Name "0xFX source build"
OutFile "${OUTPUT}"
InstallDir "$PROGRAMFILES64\0xFX-source"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
Section "Applications and notices"
  SetOutPath "$INSTDIR"
  File /r "payload\Applications"
  File /r "payload\Notices"
  File "payload\LICENSE"
  File "payload\README.md"
  File "payload\INSTALL.txt"
SectionEnd
Section "CLAP"
  SetOutPath "$COMMONFILES64\CLAP"
  File "payload\CLAP\0xFX.clap"
SectionEnd
Section "VST3"
  SetOutPath "$COMMONFILES64\VST3"
  File /r "payload\VST3\0xFX.vst3"
SectionEnd
