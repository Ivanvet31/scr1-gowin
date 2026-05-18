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

   ///////////////////////
   // AHB BUS INTERFACE //
   ///////////////////////
   wire [31:0] dmem_haddr;
   wire        dmem_hwrite;
   wire [ 1:0] dmem_htrans;
   wire [31:0] dmem_hwdata;

   wire        dmem_hready;
   wire [31:0] dmem_hrdata;
   wire        dmem_hresp;

   //////////////////////////
   // CORE 0 (mhartid = 0) //
   //////////////////////////
   scr1_top_ahb u_cpu
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

      .imem_hprot     (),
      .imem_hburst    (),
      .imem_hsize     (),
      .imem_htrans    (),
      .imem_hmastlock (),
      .imem_haddr     (),
      .imem_hready    (1'b1),
      .imem_hrdata    (32'd0),
      .imem_hresp     (1'b0),

      .dmem_hprot     (),
      .dmem_hburst    (),
      .dmem_hsize     (),
      .dmem_hmastlock (),
      .dmem_haddr     (dmem_haddr),
      .dmem_hwrite    (dmem_hwrite),
      .dmem_hwdata    (dmem_hwdata),
      .dmem_htrans    (dmem_htrans),
      .dmem_hready    (dmem_hready),
      .dmem_hrdata    (dmem_hrdata),
      .dmem_hresp     (dmem_hresp)
      );

   ////////////////////////
   // AHB TO VRAM BRIDGE //
   ////////////////////////
   reg [31:0] ahb_addr_r;
   reg        ahb_wr_r;
   reg        ahb_sel_r;

   wire       vram_sel = (dmem_haddr >= 32'hFF100000) && (dmem_haddr < 32'hFF101000);

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         ahb_addr_r <= 32'd0;
         ahb_wr_r   <= 1'b0;
         ahb_sel_r  <= 1'b0;
      end else if (dmem_hready) begin
         ahb_addr_r <= dmem_haddr;
         ahb_wr_r   <= dmem_hwrite;
         ahb_sel_r  <= vram_sel & dmem_htrans[1];
      end
   end

   wire        vram_wr_en   = ahb_sel_r & ahb_wr_r;
   wire [11:0] vram_wr_addr = ahb_addr_r[11:0];

   wire [ 7:0] vram_wr_data = (ahb_addr_r[1:0] == 2'b00) ? dmem_hwdata[ 7: 0] :
               (ahb_addr_r[1:0] == 2'b01) ? dmem_hwdata[15: 8] :
               (ahb_addr_r[1:0] == 2'b10) ? dmem_hwdata[23:16] :
               dmem_hwdata[31:24];

   assign dmem_hready = 1'b1;
   assign dmem_hresp  = 1'b0;
   assign dmem_hrdata = 32'd0;

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
