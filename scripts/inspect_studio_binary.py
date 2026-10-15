"""Small read-only Roblox binary chunk audit; handles current Rojo LZ4 output."""
from pathlib import Path
import struct


def u32(data, pos):
    if pos < 0 or pos + 4 > len(data):
        raise ValueError('truncated u32')
    return struct.unpack_from('<I', data, pos)[0]


def read_string(data, pos):
    length = u32(data, pos)
    start = pos + 4
    if length > len(data) - start:
        raise ValueError('truncated string')
    return data[start:start + length].decode('utf-8'), start + length


def decode_lz4(data, expected):
    if expected > 64 * 1024 * 1024:
        raise ValueError('chunk too large')
    pos = 0
    result = bytearray()

    def length(n):
        nonlocal pos
        if n == 15:
            while True:
                if pos >= len(data):
                    raise ValueError('truncated LZ4 length')
                value = data[pos]
                pos += 1
                n += value
                if value != 255:
                    break
        return n

    while pos < len(data):
        token = data[pos]
        pos += 1
        count = length(token >> 4)
        if count > len(data) - pos or count > expected - len(result):
            raise ValueError('invalid LZ4 literal')
        result.extend(data[pos:pos + count])
        pos += count
        if pos == len(data):
            break
        if pos + 2 > len(data):
            raise ValueError('truncated LZ4 match')
        offset = data[pos] | (data[pos + 1] << 8)
        pos += 2
        if offset <= 0 or offset > len(result):
            raise ValueError('invalid LZ4 offset')
        count = length(token & 15) + 4
        if count > expected - len(result):
            raise ValueError('oversized LZ4 match')
        for _ in range(count):
            result.append(result[-offset])
    if len(result) != expected:
        raise ValueError('LZ4 size mismatch')
    return bytes(result)


def parse(path):
    data = Path(path).read_bytes()
    if len(data) < 32 or data[:14] != b'<roblox!\x89\xff\r\n\x1a\n':
        raise ValueError('unsupported Roblox binary header')
    pos = 32
    classes = {}
    names = []
    sources = []
    ended = False
    while pos < len(data):
        if pos + 16 > len(data):
            raise ValueError('truncated chunk header')
        kind, compressed, original, reserved = struct.unpack_from('<4sIII', data, pos)
        if reserved:
            raise ValueError('nonzero reserved chunk field')
        size = compressed or original
        if size > len(data) - pos - 16:
            raise ValueError('truncated chunk body')
        body = data[pos + 16:pos + 16 + size]
        pos += 16 + size
        if compressed:
            body = decode_lz4(body, original)
        if kind == b'INST':
            class_id = u32(body, 0)
            class_name, index = read_string(body, 4)
            count = u32(body, index + 1)
            if class_id in classes or count > 1000000:
                raise ValueError('duplicate/oversized class')
            classes[class_id] = (class_name, count)
        elif kind == b'PROP':
            class_id = u32(body, 0)
            property_name, index = read_string(body, 4)
            if class_id not in classes or index >= len(body):
                raise ValueError('unknown property class / truncated type')
            property_type = body[index]
            index += 1
            if property_name in ('Name', 'Source') and property_type == 1:
                values = names if property_name == 'Name' else sources
                for _ in range(classes[class_id][1]):
                    value, index = read_string(body, index)
                    values.append(value)
                if index != len(body):
                    raise ValueError('trailing string property bytes')
        elif kind == b'END\0':
            if body != b'</roblox>':
                raise ValueError('invalid END chunk')
            ended = True
            break
    if not ended or pos != len(data):
        raise ValueError('missing END or trailing bytes')
    return classes, names, sources
