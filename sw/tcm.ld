OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY {
  TCM (rwx) : ORIGIN = 0xF0000000, LENGTH = 64K
}

SECTIONS {
  .text : {
    *(.text.crt*)
    *(.text .text.*)
  } >TCM

  .rodata : { *(.rodata*) *(.srodata*) } >TCM
  .data : { *(.data*) *(.sdata*) } >TCM
  .bss : { 
    __bss_start = .;
    *(.bss*) *(.sbss*) 
    __bss_end = .;
  } >TCM

  .stack ORIGIN(TCM) + LENGTH(TCM) - 2K : {
    __stack_top = .;
  } >TCM
}
