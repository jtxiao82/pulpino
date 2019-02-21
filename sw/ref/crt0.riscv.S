// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

#include "pulpino.h"

#define EXCEPTION_STACK_SIZE 96


/* ========================================================= [ entry ] === */
  .section .text

reset_handler:

  /* set 0 in mtvec (base for IVT) */
  csrrw x0, mtvec, x0

  /* set all registers to zero */
  mv  x1, x0
  mv  x2, x1
  mv  x3, x1
  mv  x4, x1
  mv  x5, x1
  mv  x6, x1
  mv  x7, x1
  mv  x8, x1
  mv  x9, x1
  mv x10, x1
  mv x11, x1
  mv x12, x1
  mv x13, x1
  mv x14, x1
  mv x15, x1
  mv x16, x1
  mv x17, x1
  mv x18, x1
  mv x19, x1
  mv x20, x1
  mv x21, x1
  mv x22, x1
  mv x23, x1
  mv x24, x1
  mv x25, x1
  mv x26, x1
  mv x27, x1
  mv x28, x1
  mv x29, x1
  mv x30, x1
  mv x31, x1

  /* stack initilization */
  la   x2, _stack_start

_start:
  .global _start

  /* clear BSS */
  la x26, _bss_start
  la x27, _bss_end

main_entry:
  addi   x10, x0, 0
  addi   x11, x0, 0x1
  jal  uart_set_cfg;

  /* jump to main program entry point (argc = argv = 0) */
  addi x10, x0, 0
  addi x11, x0, 0
  jal x1, main
  mv s0, a0
  jal  uart_wait_tx_done;
  mv a0, s0
  /* if program exits call exit routine from library */
  jal  x1, exit


  .global _init
  .global _fini
_init:
_fini:
  # These don't have to do anything since we use init_array/fini_array.
  ret

/* =================================================== [ exceptions ] === */
/* This section has to be down here, since we have to disable rvc for it  */

  .section .vectors, "ax"
  .option norvc;

  // external interrupts are handled by the same callback
  // until compiler supports IRQ routines
  #.org 0x00
  #.rept 23
  #nop                       // unused
  #.endr

  #jal x0, ISR_I2C_ASM 	    // 23: i2c
  #jal x0, ISR_UART_ASM 	    // 24: uart
  #jal x0, ISR_GPIO_ASM 	    // 25: gpio
  #jal x0, ISR_SPIM0_ASM     // 26: spim	end of transmission
  #jal x0, ISR_SPIM1_ASM     // 27: spim R/T finished
  #jal x0, ISR_TA_OVF_ASM    // 28: timer A overflow
  #jal x0, ISR_TA_CMP_ASM    // 29: timer A compare
  #jal x0, ISR_TB_OVF_ASM    // 30: timer B overflow
  #jal x0, ISR_TB_CMP_ASM    // 31: timer B compare


  // reset vector
  .org 0x80
  jal x0, reset_handler

  // illegal instruction exception
  #.org 0x84
  #jal x0, illegal_insn_handler

  // ecall handler
  #.org 0x88
  #jal x0, ecall_insn_handler
