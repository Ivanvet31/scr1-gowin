CROSS = riscv32-none-elf-
CC = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy

CFLAGS = -march=rv32imc -mabi=ilp32 -O2 -nostartfiles -T tcm.ld

all: firmware.hex

firmware.elf: crt0.S main.c
	$(CC) $(CFLAGS) crt0.S main.c -o firmware.elf

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

firmware.hex: firmware.bin
	python3 bin2hex.py firmware.bin firmware.hex

clean:
	rm -f *.elf *.bin *.hex
