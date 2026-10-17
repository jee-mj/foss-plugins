"""Build-graph-only adaptations for the pinned Miserere/JUCE sources."""
from pathlib import Path
import sys


def replace_once(path, old, new):
    text = path.read_text()
    assert text.count(old) == 1, (path, old)
    path.write_text(text.replace(old, new))


root = Path('.')
cmake = root / 'CMakeLists.txt'
text = cmake.read_text()
start = text.index('include(cmake/CPM.cmake)')
end = text.index('# ==============================================================================', start)
text = text[:start] + 'add_subdirectory(JUCE)\n\n' + text[end:]
text = text[:text.index('enable_testing()')]
cmake.write_text(text)
replace_once(cmake, 'FORMATS AU VST3 Standalone', 'FORMATS VST3\n    VST3_AUTO_MANIFEST FALSE')
replace_once(cmake, 'COPY_PLUGIN_AFTER_BUILD TRUE', 'COPY_PLUGIN_AFTER_BUILD FALSE')
# LTO is an optimization, not DSP behavior; avoid excess link-time memory use.
replace_once(cmake, '    juce::juce_recommended_lto_flags\n', '')

helper = root / 'JUCE/extras/Build/juceaide/CMakeLists.txt'
helper.write_text('''# Native helper from the identical JUCE source pin.
add_executable(juceaide IMPORTED GLOBAL)
set_target_properties(juceaide PROPERTIES IMPORTED_LOCATION "''' + sys.argv[1] + '''")
add_executable(juce::juceaide ALIAS juceaide)
''')
# attrib is a Windows shell utility, not needed for bundle contents. Keep both
# the generated desktop.ini and the copied Plugin.ico; don't execute Windows.
utils = root / 'JUCE/extras/Build/CMake/JUCEUtils.cmake'
replace_once(utils, '            COMMAND attrib +s "${desktop_ini}"\n', '')
replace_once(utils, '            COMMAND attrib +s "${output_folder}"\n', '')
