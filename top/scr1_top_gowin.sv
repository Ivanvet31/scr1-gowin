module scr1_top_gowin
  (
   input wire        clk,
   input wire        rst_n,

   // LCD Interface
   output wire       lcd_clk,
   output wire       lcd_en,
   output wire [5:0] lcd_r,
   output wire [5:0] lcd_g,
   output wire [5:0] lcd_b
   );

   ///////////////////
   // DUAL CORE AHB //
   ///////////////////
   wire [31:0] haddr_0, haddr_1;
   wire        hwrite_0, hwrite_1;
   wire [ 1:0] htrans_0, htrans_1;
   wire [31:0] hwdata_0, hwdata_1;
   wire        hready_0, hready_1;

   //////////////////////////
   // CORE 0 (mhartid = 0) //
   //////////////////////////
   scr1_top_ahb u_cpu0
     (
      .pwrup_rst_n    (rst_n),
      .rst_n          (rst_n),
      .cpu_rst_n      (rst_n),
      .test_mode      (1'b0),
      .test_rst_n     (1'b1),
      .clk            (clk),
      .rtc_clk        (clk),

      .fuse_mhartid   (32'd0), // <= core id 0
      .irq_lines      (16'd0),
      .soft_irq       (1'b0),
      .fuse_idcode    (32'd0),
      .trst_n         (1'b1),
      .tck            (1'b0),
      .tms            (1'b0),
      .tdi            (1'b0),
      .tdo            (),
      .tdo_en         (),
      .sys_rst_n_o    (),
      .sys_rdc_qlfy_o (),

      .imem_hready    (1'b1),
      .imem_hrdata    (32'd0),
      .imem_hresp     (1'b0),
      .imem_hprot     (),
      .imem_hburst    (),
      .imem_hsize     (),
      .imem_htrans    (),
      .imem_hmastlock (),
      .imem_haddr     (),

      .dmem_haddr     (haddr_0),
      .dmem_hwrite    (hwrite_0),
      .dmem_hwdata    (hwdata_0),
      .dmem_htrans    (htrans_0),
      .dmem_hready    (hready_0),
      .dmem_hrdata    (32'd0),
      .dmem_hresp     (1'b0),
      .dmem_hprot     (),
      .dmem_hburst    (),
      .dmem_hsize     (),
      .dmem_hmastlock ()
      );

   //////////////////////////
   // CORE 1 (mhartid = 1) //
   //////////////////////////
   scr1_top_ahb u_cpu1
     (
      .pwrup_rst_n    (rst_n),
      .rst_n          (rst_n),
      .cpu_rst_n      (rst_n),
      .test_mode      (1'b0),
      .test_rst_n     (1'b1),
      .clk            (clk),
      .rtc_clk        (clk),

      .fuse_mhartid   (32'd1), // <= core id 1
      .irq_lines      (16'd0),
      .soft_irq       (1'b0),

      .fuse_idcode    (32'd0),
      .trst_n         (1'b1),
      .tck            (1'b0),
      .tms            (1'b0),
      .tdi            (1'b0),
      .tdo            (),
      .tdo_en         (),
      .sys_rst_n_o    (),
      .sys_rdc_qlfy_o (),

      .imem_hready    (1'b1),
      .imem_hrdata    (32'd0),
      .imem_hresp     (1'b0),
      .imem_hprot     (),
      .imem_hburst    (),
      .imem_hsize     (),
      .imem_htrans    (),
      .imem_hmastlock (),
      .imem_haddr     (),

      .dmem_haddr     (haddr_1),
      .dmem_hwrite    (hwrite_1),
      .dmem_hwdata    (hwdata_1),
      .dmem_htrans    (htrans_1),
      .dmem_hready    (hready_1),
      .dmem_hrdata    (32'd0),
      .dmem_hresp     (1'b0),
      .dmem_hprot     (),
      .dmem_hburst    (),
      .dmem_hsize     (),
      .dmem_hmastlock ()
      );

   ///////////////////////////////
   // AHB arbiter & VRAM bridge //
   ///////////////////////////////
   wire req0 = (haddr_0 >= 32'hFF100000) && (haddr_0 < 32'hFF101000) && htrans_0[1];
   wire req1 = (haddr_1 >= 32'hFF100000) && (haddr_1 < 32'hFF101000) && htrans_1[1];

   // ready logic (core 0 has gigher priority)
   assign hready_0 = 1'b1;
   assign hready_1 = ~req0;


   reg        active_data_0, active_data_1;
   reg [11:0] addr_dp_0, addr_dp_1;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         active_data_0 <= 1'b0;
         active_data_1 <= 1'b0;
      end else begin
         active_data_0 <= hready_0 ? (req0 & hwrite_0) : 1'b0;
         active_data_1 <= hready_1 ? (req1 & hwrite_1) : 1'b0;
      end
   end

   always @(posedge clk) begin
      if (hready_0) addr_dp_0 <= haddr_0[11:0];
      if (hready_1) addr_dp_1 <= haddr_1[11:0];
   end


   wire        vram_wr_en   = active_data_0 | active_data_1;
   wire [11:0] vram_wr_addr = active_data_0 ? addr_dp_0 : addr_dp_1;
   wire [31:0] active_hwdata= active_data_0 ? hwdata_0  : hwdata_1;

   wire [ 7:0] vram_wr_data = (vram_wr_addr[1:0] == 2'b00) ? active_hwdata[ 7: 0] :
               (vram_wr_addr[1:0] == 2'b01) ? active_hwdata[15: 8] :
               (vram_wr_addr[1:0] == 2'b10) ? active_hwdata[23:16] :
               active_hwdata[31:24];

   ////////////////
   // SCREEN DRV //
   ////////////////
   cp866_screen_drv u_lcd
     (
      .rst_n        (rst_n),
      .clk          (clk),
      .lcd_clk      (lcd_clk),
      .lcd_en       (lcd_en),
      .lcd_r        (lcd_r),
      .lcd_g        (lcd_g),
      .lcd_b        (lcd_b),
      .vram_wr_en   (vram_wr_en),
      .vram_wr_addr (vram_wr_addr),
      .vram_wr_data (vram_wr_data)
      );

endmodule
