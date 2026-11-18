"""Validate a complete Universal 2 ZIP without pretending to launch macOS."""
import pathlib
import plistlib
import struct
import sys
import zipfile


def validate(path):
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, 'Corrupt ZIP member'
        entries = {entry.filename: entry for entry in archive.infolist()}
        plist_path = next(n for n in entries if n.endswith('.app/Contents/Info.plist'))
        base = plist_path.removesuffix('Info.plist')
        info = plistlib.loads(archive.read(plist_path))
        assert info['CFBundleIdentifier'] == 'com.alm1ghtyf1tch.tothefarside'
        executable = base + 'MacOS/' + info['CFBundleExecutable']
        assert entries[executable].external_attr >> 16 & 0o111, 'Executable permission missing'
        binary = archive.read(executable)
        magic, count = struct.unpack_from('>II', binary)
        assert magic == 0xCAFEBABE and 1 < count < 10, 'Not a Universal 2 executable'
        cpus = set()
        for index in range(count):
            cpu, _, offset, length, _ = struct.unpack_from('>IIIII', binary, 8 + index * 20)
            cpus.add(cpu)
            image = binary[offset:offset + length]
            assert struct.unpack_from('<I', image)[0] == 0xFEEDFACF
            ncmds = struct.unpack_from('<I', image, 16)[0]
            command = 32
            signed = False
            for _ in range(ncmds):
                cmd, size = struct.unpack_from('<II', image, command)
                assert size >= 8 and command + size <= len(image)
                if cmd == 0x1D:
                    pos, length = struct.unpack_from('<II', image, command + 8)
                    signed = length > 0 and pos + length <= len(image)
                command += size
            assert signed, 'Missing embedded code signature'
        assert {0x01000007, 0x0100000C} <= cpus, 'Intel/ARM64 slice missing'
        assert any(n.startswith(base + 'Resources/') and n.endswith('.pck') for n in entries), 'Game pack missing'
        print(f'PASS: {pathlib.Path(path).name}: complete app, bundle metadata, x86_64 + ARM64, executable permissions, embedded signatures and game pack')
        print('Archive validation only; macOS launch and Gatekeeper approval require a Mac.')


if __name__ == '__main__':
    validate(sys.argv[1])
