// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "axi_bus.sv"
`include "debug_bus.sv"

`define AXI_ADDR_WIDTH         32
`define AXI_DATA_WIDTH         32
`define AXI_ID_MASTER_WIDTH     2
`define AXI_ID_SLAVE_WIDTH      4
`define AXI_USER_WIDTH          1

module pulpino_top
  #(
    parameter USE_ZERO_RISCY       = 0,
    parameter RISCY_RV32F          = 0,
    parameter ZERO_RV32M           = 1,
    parameter ZERO_RV32E           = 0
  )
  (
    // Clock and Reset
    input logic               clk /*verilator clocker*/,
    input logic               rst_n,

    input  logic              clk_sel_i,
    input  logic              clk_standalone_i,
    input  logic              testmode_i,
    input  logic              fetch_enable_i,
    input  logic              scan_enable_i,

    //SPI Slave
    input  logic              spi_clk_i /*verilator clocker*/,
    input  logic              spi_cs_i /*verilator clocker*/,
    output logic [1:0]        spi_mode_o,
    output logic              spi_sdo0_o,
    output logic              spi_sdo1_o,
    output logic              spi_sdo2_o,
    output logic              spi_sdo3_o,
    input  logic              spi_sdi0_i,
    input  logic              spi_sdi1_i,
    input  logic              spi_sdi2_i,
    input  logic              spi_sdi3_i,

    //SPI Master
    output logic              spi_master_clk_o,
    output logic              spi_master_csn0_o,
    output logic              spi_master_csn1_o,
    output logic              spi_master_csn2_o,
    output logic              spi_master_csn3_o,
    output logic [1:0]        spi_master_mode_o,
    output logic              spi_master_sdo0_o,
    output logic              spi_master_sdo1_o,
    output logic              spi_master_sdo2_o,
    output logic              spi_master_sdo3_o,
    input  logic              spi_master_sdi0_i,
    input  logic              spi_master_sdi1_i,
    input  logic              spi_master_sdi2_i,
    input  logic              spi_master_sdi3_i,

    input  logic              scl_pad_i,
    output logic              scl_pad_o,
    output logic              scl_padoen_o,
    input  logic              sda_pad_i,
    output logic              sda_pad_o,
    output logic              sda_padoen_o,

    output logic              uart_tx,
    input  logic              uart_rx,
    output logic              uart_rts,
    output logic              uart_dtr,
    input  logic              uart_cts,
    input  logic              uart_dsr,

    input  logic       [31:0] gpio_in,
    output logic       [31:0] gpio_out,
    output logic       [31:0] gpio_dir,
    output logic [31:0] [5:0] gpio_padcfg,

    // JTAG signals
    input  logic              tck_i,
    input  logic              trstn_i,
    input  logic              tms_i,
    input  logic              tdi_i,
    output logic              tdo_o,

    // PULPino specific pad config
    output logic [31:0] [5:0] pad_cfg_o,
    output logic       [31:0] pad_mux_o
  );

  logic        clk_int;

  logic        fetch_enable_int;
  logic        core_busy_int;
  logic        clk_gate_core_int;
  logic [31:0] irq_to_core_int;

  logic        lock_fll_int;
  logic        cfgreq_fll_int;
  logic        cfgack_fll_int;
  logic [1:0]  cfgad_fll_int;
  logic [31:0] cfgd_fll_int;
  logic [31:0] cfgq_fll_int;
  logic        cfgweb_n_fll_int;
  logic        rstn_int;
  logic [31:0] boot_addr_int;

  /*******************************/
  /*                             */
  /* Fault Injection Block Begin */
  /*                             */
  /*******************************/
  reg [31:0] ram [0:63];
  integer f_regfile, f_regfile_dump;
  integer i;
  
  /****************************/
  /*                          */
  /* Read fault configuration */
  /*                          */
  /****************************/
  initial begin 
    $readmemh("/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_config.data", ram);
  end

  /*******************/
  /*                 */
  /* Prevent hang on */
  /*                 */
  /*******************/
  //parameter simtime = 1273800ns;   // gcd
  //parameter simtime = 1973800ns;   // sw gcd + hw gcd
  parameter simtime = 48102880ns;  // adaline
  //parameter simtime   = 481028800ns; // qsort

  parameter timeout   = simtime;

  always @(posedge clk) begin
    if($realtime > simtime + timeout && ram[0] == 1) begin
      $stop;
    end
  end

  /***************************/
  /*                         */
  /*   Dump register file    */
  /*                         */
  /***************************/
  initial begin
    f_regfile_dump = $fopen("trace_core_regfile_dump.log", "w");
  end
  final begin
    $fclose(f_regfile_dump);
  end
  always @(negedge clk) begin 
    if(ram[0] == 0) begin
      $fwrite(f_regfile_dump, "%d,", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles);
      
      if(ram[1] == core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o && ram[1] != 0) begin
        for(i = 0; i < ram[1] - 1; i = i + 1) begin
          $fwrite(f_regfile_dump, "%8h,", core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[i]);
        end       
        $fwrite(f_regfile_dump, "%8h,", core_region_i.CORE.RISCV_CORE.regfile_wdata);
        for(i = ram[1] + 1; i < 32; i = i + 1) begin
          $fwrite(f_regfile_dump, "%8h,", core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[i]);
        end
      end else begin
        for(i = 0; i < 32; i = i + 1) begin
          $fwrite(f_regfile_dump, "%8h,", core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[i]);
        end
      end
      $fwrite(f_regfile_dump, "\n");
    end   
  end

  /***************************/
  /*                         */
  /* Data Register Injection */
  /*                         */
  /***************************/
  always @(negedge clk) begin
    if(ram[0] == 1 && ram[5] == 0) begin // ram[0] => 0: fault-free sim, 1: fault sim, ram[5] => 0: datareg injection
      if(core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles >= ram[3] && 
         core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles < ram[4]) begin
   
        $display("PC: %25h, Datareg: %25d, Bitpos: %25d, BeginCycle: %25d, EndCycle: %25d", 
                                           core_region_i.CORE.RISCV_CORE.pc_id+67200/*adaline offset*/, 
                                           ram[1], ram[2], 
                                           ram[3], ram[4]);
   
        if(ram[1] == core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o) begin
          $display("             %25d, we_en:%25d, re_req: %25d, %25d, %25h", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
                                                                       core_region_i.CORE.RISCV_CORE.regfile_we_wb, 
                                                                       core_region_i.CORE.RISCV_CORE.dbg_reg_rreq, 
                                                                       core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o, 
                                                                       core_region_i.CORE.RISCV_CORE.regfile_wdata);
          $fwrite(f_regfile_dump, "cycle,%25d,%d,%8h,\n", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
                                                         core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o, 
                                                         core_region_i.CORE.RISCV_CORE.regfile_wdata);

          force core_region_i.CORE.RISCV_CORE.regfile_wdata[ram[2]] = ~core_region_i.CORE.RISCV_CORE.regfile_wdata[ram[2]];

          $display("             %25d, we_en:%25d, re_req: %25d, %25d, %25h", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
                                                                 core_region_i.CORE.RISCV_CORE.regfile_we_wb, 
                                                                 core_region_i.CORE.RISCV_CORE.dbg_reg_rreq, 
                                                                 core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o, 
                                                                 core_region_i.CORE.RISCV_CORE.regfile_wdata);
          $fwrite(f_regfile_dump, "cycle,%25d,%d,%8h,\n", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
                                                  	 core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o, 
							 core_region_i.CORE.RISCV_CORE.regfile_wdata);
        end else begin
          $display("             %25d, re_req:%25d, %25d, %25h", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
                                                    core_region_i.CORE.RISCV_CORE.dbg_reg_rreq,
                                                    ram[1], 
                                                    core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[ram[1]]);       
          $fwrite(f_regfile_dump, "cycle,%25d,%d,%8h,\n", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
							 ram[1], 
							 core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[ram[1]]);

          force core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[ram[1]][ram[2]] = ~core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[ram[1]][ram[2]];

          $display("             %25d, re_req:%25d, %25d, %25h", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
                                                                 core_region_i.CORE.RISCV_CORE.dbg_reg_rreq,
                                                                 ram[1], 
                                                                 core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[ram[1]]);
          $fwrite(f_regfile_dump, "cycle,%25d,%d,%8h,\n", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, 
							 ram[1], 
							 core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[ram[1]]);
        end
    
      end else begin
        release core_region_i.CORE.RISCV_CORE.regfile_wdata;
        release core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem;
      end
    end
  end

  /**************************************/
  /*                                    */
  /* CPU Pipeline IF/ID Latch Injection */
  /*                                    */
  /**************************************/
  always @(negedge clk) begin
    if(ram[0] == 1 && ram[5] == 2) begin // ram[0] => 0: fault-free sim, 1: fault sim, ram[5] => 2: IF Pipeline Latch Injection
      if(core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles >= ram[3] && 
         core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles < ram[4]) begin
        $display("%d, IF Instr Rdata: %25h, Bitpos: %25d, BeginCycle: %25d, EndCycle: %25d", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, core_region_i.CORE.RISCV_CORE.if_stage_i.instr_rdata_id_o, ram[2], ram[3], ram[4]);

        force core_region_i.CORE.RISCV_CORE.if_stage_i.instr_rdata_id_o[ram[2]] = ~core_region_i.CORE.RISCV_CORE.if_stage_i.instr_rdata_id_o[ram[2]];

        $display("%d, IF Instr Rdata: %25h, Bitpos: %25d, BeginCycle: %25d, EndCycle: %25d", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles, core_region_i.CORE.RISCV_CORE.if_stage_i.instr_rdata_id_o, ram[2], ram[3], ram[4]);
      end else begin
        release core_region_i.CORE.RISCV_CORE.if_stage_i.instr_rdata_id_o;
      end
    end
  end

  /*************************************************************/
  /*                                                           */
  /* Dump Regfile From Injection Cycle to Injection Cycle + 10 */
  /*                                                           */
  /*************************************************************/
  initial begin
    f_regfile = $fopen("trace_core_regfile_10_cycles.log", "w");
  end
  final begin
    $fclose(f_regfile);
  end

  always @(negedge clk) begin
    if(ram[0] == 1) begin
      if(core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles >= ram[3] && 
         core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles < ram[4]+10) begin
        $fwrite(f_regfile, "cycles,%d,", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles);
        $fwrite(f_regfile, "%h,", core_region_i.CORE.RISCV_CORE.id_stage_i.pc_id_i+70884);
        for(i = 0; i < 31; i = i + 1)
          $fwrite(f_regfile, "%h,", core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[i]);
        $fwrite(f_regfile, "\n");
        //if(core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles == ram[4]+9) // Early stop
          //$stop();
      end
    end else if(ram[0] == 0) begin
      $fwrite(f_regfile, "cycles,%d,", core_region_i.CORE.RISCV_CORE.riscv_tracer_i.cycles);
      $fwrite(f_regfile, "%h,", core_region_i.CORE.RISCV_CORE.id_stage_i.pc_id_i+70884);
      for(i = 0; i < 31; i = i + 1)
        $fwrite(f_regfile, "%h,", core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[i]);
      $fwrite(f_regfile, "\n");
    end
  end
  /*******************************/
  /*                             */
  /* Fault Injection Block End   */
  /*                             */
  /*******************************/



  AXI_BUS
  #(
    .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( `AXI_ID_SLAVE_WIDTH ),
    .AXI_USER_WIDTH ( `AXI_USER_WIDTH     )
  )
  slaves[2:0]();

  AXI_BUS
  #(
    .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH   ( `AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH ( `AXI_USER_WIDTH      )
  )
  masters[2:0]();

  DEBUG_BUS
  debug();

  //----------------------------------------------------------------------------//
  // Clock and reset generation
  //----------------------------------------------------------------------------//
  clk_rst_gen
  clk_rst_gen_i
  (
      .clk_i            ( clk              ),
      .rstn_i           ( rst_n            ),

      .clk_sel_i        ( clk_sel_i        ),
      .clk_standalone_i ( clk_standalone_i ),
      .testmode_i       ( testmode_i       ),
      .scan_i           ( 1'b0             ),
      .scan_o           (                  ),
      .scan_en_i        ( scan_enable_i    ),

      .fll_req_i        ( cfgreq_fll_int   ),
      .fll_wrn_i        ( cfgweb_n_fll_int ),
      .fll_add_i        ( cfgad_fll_int    ),
      .fll_data_i       ( cfgd_fll_int     ),
      .fll_ack_o        ( cfgack_fll_int   ),
      .fll_r_data_o     ( cfgq_fll_int     ),
      .fll_lock_o       ( lock_fll_int     ),

      .clk_o            ( clk_int          ),
      .rstn_o           ( rstn_int         )

    );

  //----------------------------------------------------------------------------//
  // Core region
  //----------------------------------------------------------------------------//
  core_region
  #(
    .AXI_ADDR_WIDTH       ( `AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH       ( `AXI_DATA_WIDTH      ),
    .AXI_ID_MASTER_WIDTH  ( `AXI_ID_MASTER_WIDTH ),
    .AXI_ID_SLAVE_WIDTH   ( `AXI_ID_SLAVE_WIDTH  ),
    .AXI_USER_WIDTH       ( `AXI_USER_WIDTH      ),
    .USE_ZERO_RISCY       (  USE_ZERO_RISCY      ),
    .RISCY_RV32F          (  RISCY_RV32F         ),
    .ZERO_RV32M           (  ZERO_RV32M          ),
    .ZERO_RV32E           (  ZERO_RV32E          )
  )
  core_region_i
  (
    .clk            ( clk_int           ),
    .rst_n          ( rstn_int          ),

    .testmode_i     ( testmode_i        ),
    .fetch_enable_i ( fetch_enable_int  ),
    .irq_i          ( irq_to_core_int   ),
    .core_busy_o    ( core_busy_int     ),
    .clock_gating_i ( clk_gate_core_int ),
    .boot_addr_i    ( boot_addr_int     ),

    .core_master    ( masters[0]        ),
    .dbg_master     ( masters[1]        ),
    .data_slave     ( slaves[1]         ),
    .instr_slave    ( slaves[0]         ),
    .debug          ( debug             ),

    .tck_i          ( tck_i             ),
    .trstn_i        ( trstn_i           ),
    .tms_i          ( tms_i             ),
    .tdi_i          ( tdi_i             ),
    .tdo_o          ( tdo_o             )
  );

  //----------------------------------------------------------------------------//
  // Peripherals
  //----------------------------------------------------------------------------//
  peripherals
  #(
    .AXI_ADDR_WIDTH      ( `AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH      ( `AXI_DATA_WIDTH      ),
    .AXI_SLAVE_ID_WIDTH  ( `AXI_ID_SLAVE_WIDTH  ),
    .AXI_MASTER_ID_WIDTH ( `AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH      ( `AXI_USER_WIDTH      )
  )
  peripherals_i
  (
    .clk_i           ( clk_int           ),
    .rst_n           ( rstn_int          ),

    .axi_spi_master  ( masters[2]        ),
    .debug           ( debug             ),

    .spi_clk_i       ( spi_clk_i         ),
    .testmode_i      ( testmode_i        ),
    .spi_cs_i        ( spi_cs_i          ),
    .spi_mode_o      ( spi_mode_o        ),
    .spi_sdo0_o      ( spi_sdo0_o        ),
    .spi_sdo1_o      ( spi_sdo1_o        ),
    .spi_sdo2_o      ( spi_sdo2_o        ),
    .spi_sdo3_o      ( spi_sdo3_o        ),
    .spi_sdi0_i      ( spi_sdi0_i        ),
    .spi_sdi1_i      ( spi_sdi1_i        ),
    .spi_sdi2_i      ( spi_sdi2_i        ),
    .spi_sdi3_i      ( spi_sdi3_i        ),

    .slave           ( slaves[2]         ),

    .uart_tx         ( uart_tx           ),
    .uart_rx         ( uart_rx           ),
    .uart_rts        ( uart_rts          ),
    .uart_dtr        ( uart_dtr          ),
    .uart_cts        ( uart_cts          ),
    .uart_dsr        ( uart_dsr          ),

    .spi_master_clk  ( spi_master_clk_o  ),
    .spi_master_csn0 ( spi_master_csn0_o ),
    .spi_master_csn1 ( spi_master_csn1_o ),
    .spi_master_csn2 ( spi_master_csn2_o ),
    .spi_master_csn3 ( spi_master_csn3_o ),
    .spi_master_mode ( spi_master_mode_o ),
    .spi_master_sdo0 ( spi_master_sdo0_o ),
    .spi_master_sdo1 ( spi_master_sdo1_o ),
    .spi_master_sdo2 ( spi_master_sdo2_o ),
    .spi_master_sdo3 ( spi_master_sdo3_o ),
    .spi_master_sdi0 ( spi_master_sdi0_i ),
    .spi_master_sdi1 ( spi_master_sdi1_i ),
    .spi_master_sdi2 ( spi_master_sdi2_i ),
    .spi_master_sdi3 ( spi_master_sdi3_i ),

    .scl_pad_i       ( scl_pad_i         ),
    .scl_pad_o       ( scl_pad_o         ),
    .scl_padoen_o    ( scl_padoen_o      ),
    .sda_pad_i       ( sda_pad_i         ),
    .sda_pad_o       ( sda_pad_o         ),
    .sda_padoen_o    ( sda_padoen_o      ),

    .gpio_in         ( gpio_in           ),
    .gpio_out        ( gpio_out          ),
    .gpio_dir        ( gpio_dir          ),
    .gpio_padcfg     ( gpio_padcfg       ),

    .core_busy_i     ( core_busy_int     ),
    .irq_o           ( irq_to_core_int   ),
    .fetch_enable_i  ( fetch_enable_i    ),
    .fetch_enable_o  ( fetch_enable_int  ),
    .clk_gate_core_o ( clk_gate_core_int ),

    .fll1_req_o      ( cfgreq_fll_int    ),
    .fll1_wrn_o      ( cfgweb_n_fll_int  ),
    .fll1_add_o      ( cfgad_fll_int     ),
    .fll1_wdata_o    ( cfgd_fll_int      ),
    .fll1_ack_i      ( cfgack_fll_int    ),
    .fll1_rdata_i    ( cfgq_fll_int      ),
    .fll1_lock_i     ( lock_fll_int      ),
    .pad_cfg_o       ( pad_cfg_o         ),
    .pad_mux_o       ( pad_mux_o         ),
    .boot_addr_o     ( boot_addr_int     )
  );


  //----------------------------------------------------------------------------//
  // Axi node
  //----------------------------------------------------------------------------//

  axi_node_intf_wrap
  #(
    .NB_MASTER      ( 3                    ),
    .NB_SLAVE       ( 3                    ),
    .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH   ( `AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH ( `AXI_USER_WIDTH      )
  )
  axi_interconnect_i
  (
    .clk       ( clk_int    ),
    .rst_n     ( rstn_int   ),
    .test_en_i ( testmode_i ),

    .master    ( slaves     ),
    .slave     ( masters    ),

    .start_addr_i ( { 32'h1A10_0000, 32'h0010_0000, 32'h0000_0000 } ),
    .end_addr_i   ( { 32'h1A11_FFFF, 32'h001F_FFFF, 32'h000F_FFFF } )
  );



endmodule

