"""Build-graph-only SDL source substitution; no DSP or platform-guard changes."""
from pathlib import Path

p = Path('CMakeLists.txt')
text = p.read_text()
start = text.index('# ── SDL2 detection')
end = text.index('# Detect SDL2 architecture', start)
text = text[:start] + '''# Operator source-built SDL2, using the same cross compiler as 0xFX.
add_subdirectory(deps/SDL2-source EXCLUDE_FROM_ALL)
set(SDL2_FOUND TRUE)
set(SDL2_INCLUDE_DIRS "${CMAKE_SOURCE_DIR}/deps/SDL2-source/include;${CMAKE_BINARY_DIR}/deps/SDL2-source/include")
set(SDL2_LIBRARIES SDL2::SDL2-static)
''' + text[end:]
needle = '"${MINGW_SDL2_DIR}/lib/libSDL2main.a"'
assert text.count(needle) == 2
text = text.replace(needle, 'SDL2::SDL2main')
p.write_text(text)
