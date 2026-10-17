"""Data-only installer extraction validation (shared by positive/negative checks)."""


def validate(payload, extracted, helper):
    expected = {}
    for path in payload.rglob("*"):
        if path.is_file():
            relative = path.relative_to(payload)
            if relative.parts[0] == "VST3":
                target = "$LOCALAPPDATA/Programs/Common/VST3/" + relative.relative_to("VST3").as_posix()
            elif relative.parts[:2] == ("AppData", "JQGunk"):
                target = "$APPDATA/JQGunk/" + relative.relative_to("AppData/JQGunk").as_posix()
            elif relative.parts[0] == "Notices":
                target = "$LOCALAPPDATA/Programs/JQGunk/Notices/" + relative.relative_to("Notices").as_posix()
            else:
                assert relative.as_posix() == "INSTALL.txt", relative
                target = "$LOCALAPPDATA/Programs/JQGunk/Notices/INSTALL.txt"
            assert target not in expected, target
            expected[target] = path.read_bytes()
    payload_count = len(expected)
    expected["$PLUGINSDIR/System.dll"] = helper.read_bytes()
    actual = {}
    for path in extracted.rglob("*"):
        assert not path.is_symlink(), path
        if path.is_file():
            actual[path.relative_to(extracted).as_posix()] = path.read_bytes()
    assert set(actual) == set(expected), {
        "missing": sorted(set(expected) - set(actual)),
        "unexpected": sorted(set(actual) - set(expected)),
    }
    for name, data in expected.items():
        assert actual[name] == data, f"installer content differs: {name}"
    return payload_count
