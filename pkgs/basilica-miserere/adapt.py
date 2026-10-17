"""Offline, native VST3-only CMake graph adaptation; no DSP/source edits."""

import re
import sys
from pathlib import Path

path = Path("CMakeLists.txt")
text = path.read_text()
text, count = re.subn(
    r"include\(cmake/CPM\.cmake\).*?CPMAddPackage\(\s*NAME JUCE.*?\n\)",
    f'add_subdirectory("{sys.argv[1]}" JUCE EXCLUDE_FROM_ALL)',
    text,
    count=1,
    flags=re.S,
)
assert count == 1, "upstream JUCE provisioning changed"
for old, new in [
    ("FORMATS AU VST3 Standalone", "FORMATS VST3\n    VST3_AUTO_MANIFEST FALSE"),
    ("COPY_PLUGIN_AFTER_BUILD TRUE", "COPY_PLUGIN_AFTER_BUILD FALSE"),
    ("    juce::juce_recommended_lto_flags\n", ""),
]:
    assert text.count(old) == 1, old
    text = text.replace(old, new)
# The upstream Catch2 graph is unconditional. Omit it rather than download or
# discover/execute tests that instantiate audio/GUI objects in this package build.
assert text.count("enable_testing()") == 1
text = text.split("enable_testing()", 1)[0]
assert "CPMAddPackage" not in text
path.write_text(text)
