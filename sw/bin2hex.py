import sys

with open(sys.argv[1], "rb") as f:
    data = f.read()

if len(data) % 4 != 0:
    data += b'\x00' * (4 - len(data) % 4)

with open(sys.argv[2], "w") as f:
    for i in range(0, len(data), 4):
        word = (data[i+3] << 24) | (data[i+2] << 16) | (data[i+1] << 8) | data[i]
        f.write(f"{word:08x}\n")
