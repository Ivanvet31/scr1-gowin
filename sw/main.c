#include <stdint.h>

#define VRAM_BASE ((volatile uint8_t*) 0xFF100000)

static inline uint32_t get_core_id() {
    uint32_t hartid;
    __asm__ volatile ("csrr %0, mhartid" : "=r" (hartid));
    return hartid;
}

void print_char(int x, int y, char c) {
    if (x >= 0 && x < 80 && y >= 0 && y < 40) {
        VRAM_BASE[y * 80 + x] = (uint8_t)c;
    }
}

void print_string(int x, int y, const char* str) {
    int curr_x = x;
    while (*str) {
        print_char(curr_x++, y, *str++);
    }
}

void delay(uint32_t count) {
    for (volatile uint32_t i = 0; i < count; i++);
}

int main() {
    uint32_t core_id = get_core_id();

    if (core_id == 0) {
      // core 0 is cleaning the screen and writing the frame (#)
        for (int i = 0; i < 3200; i++) VRAM_BASE[i] = 0x20;
        
        for (int x = 0; x < 80; x++) {
            print_char(x, 0, '#');
            print_char(x, 39, '#');
        }
        print_string(2, 2, "CORE 0 is initializing the system...");
    } else {
      // core 1 waits for  core 0 to finish the cleaning
        delay(100000); 
        print_string(2, 4, "CORE 1 is online and sharing VRAM!");
    }

    // for both cores
    int counter = 0;
    while (1) {
        char c = '0' + (counter % 10);

        if (core_id == 0) {
            print_string(2, 6, "Core 0 tick: ");
            print_char(16, 6, c);
            
	    // core 0 is using *
            print_char(20 + (counter % 40), 6, '*');
            print_char(20 + ((counter - 1) % 40), 6, ' '); 
        } 
        else if (core_id == 1) {
            print_string(2, 8, "Core 1 tick: ");
            print_char(16, 8, c);

	    // cpre 1 is using @
            print_char(20 + (counter % 40), 8, '@');
            print_char(20 + ((counter - 1) % 40), 8, ' '); 
        }

        counter++;
        delay(500000); // for smoother animation
    }

    return 0;
}
