"""Generalized reviewed Miserere adapter: native offline CMake graph only."""
import re
import sys
from pathlib import Path

def adapt(text, juce, dependencies):
    text, count = re.subn(r'include\(cmake/CPM\.cmake\).*?CPMAddPackage\(\s*NAME JUCE.*?\n\)',
                         f'add_subdirectory("{juce}" JUCE EXCLUDE_FROM_ALL)',text,count=1,flags=re.S)
    assert count == 1, 'upstream JUCE provisioning changed'
    for name, path in dependencies.items():
        text,count = re.subn(r'CPMAddPackage\(\s*NAME '+re.escape(name)+r'\s.*?\n\)',
                            f'set({name}_SOURCE_DIR "{path}")',text,count=1,flags=re.S)
        assert count == 1, f'upstream {name} provisioning changed'
    for old,new in [('FORMATS AU VST3 Standalone','FORMATS VST3\n    VST3_AUTO_MANIFEST FALSE'),
                    ('COPY_PLUGIN_AFTER_BUILD TRUE','COPY_PLUGIN_AFTER_BUILD FALSE'),
                    ('    juce::juce_recommended_lto_flags\n','')]:
        assert text.count(old) == 1, old
        text = text.replace(old,new)
    assert text.count('enable_testing()') == 1
    text = text.split('enable_testing()',1)[0]
    # Fail closed on remaining CMake provisioning, rather than silently skip it.
    active = '\n'.join(line.split('#',1)[0] for line in text.splitlines())
    assert not re.search(r'CPMAddPackage|FetchContent|ExternalProject|file\s*\(\s*DOWNLOAD|execute_process\s*\(',active,re.I), 'remaining network/process provisioning'
    return text

if __name__ == '__main__':
    dependencies = dict(argument.split('=',1) for argument in sys.argv[2:])
    path = Path('CMakeLists.txt')
    path.write_text(adapt(path.read_text(),sys.argv[1],dependencies))
