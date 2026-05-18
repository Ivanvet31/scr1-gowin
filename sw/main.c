#include <stdint.h>

// VRAM base addr
#define VRAM_BASE ((volatile uint8_t*) 0xFF100000)

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

void clear_screen() {
    for (int i = 0; i < 3200; i++) {
        VRAM_BASE[i] = 0x20;
    }
}

int main() {
    clear_screen();
    
    for (int x = 0; x < 80; x++) {
        print_char(x, 0, '#');
        print_char(x, 39, '#');
    }
    
    print_string(25, 10, "SCR1 core is writing...");
    print_string(23, 12, "listen and learn");
    
    VRAM_BASE[14 * 80 + 36] = 0x8F; 
    VRAM_BASE[14 * 80 + 37] = 0xE0; 
    VRAM_BASE[14 * 80 + 38] = 0xA8; 
    VRAM_BASE[14 * 80 + 39] = 0xA2; 
    VRAM_BASE[14 * 80 + 40] = 0xA5; 
    VRAM_BASE[14 * 80 + 41] = 0xE2; 
    print_string(42, 14, "~~~");

    while (1) {
        __asm__ volatile("wfi"); 
    }
    return 0;
}
