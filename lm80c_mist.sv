// LM80C for the MiST
//
// Antonino Porcino, nino.porcino@gmail.com
//

// TODO mist hardware reset button
// TODO sdram (test out port)
// TODO sprite bug
// TODO bug volume 1,15:volume 2,15:volume 3,15:sound 3,200,200
// TODO eliminare z80ena
// TODO italian keyboard
// TODO sio, pio dummy modules
// TODO color problem (check pixel to pixel, vsync>200?)
// TODO async VDP design


// top level module
								   
module lm80c_mist
( 
   input [1:0] 	CLOCK_27,      // 27 MHz board clock 
	
	// SDRAM interface
	inout  [15:0] 	SDRAM_DQ, 		// SDRAM Data bus 16 Bits
	output [12:0] 	SDRAM_A, 		// SDRAM Address bus 13 Bits
	output        	SDRAM_DQML, 	// SDRAM Low-byte Data Mask
	output        	SDRAM_DQMH, 	// SDRAM High-byte Data Mask
	output        	SDRAM_nWE, 		// SDRAM Write Enable
	output       	SDRAM_nCAS, 	// SDRAM Column Address Strobe
	output        	SDRAM_nRAS, 	// SDRAM Row Address Strobe
	output        	SDRAM_nCS, 		// SDRAM Chip Select
	output [1:0]  	SDRAM_BA, 		// SDRAM Bank Address
	output 			SDRAM_CLK, 		// SDRAM Clock
	output        	SDRAM_CKE, 		// SDRAM Clock Enable
  
   // SPI (serial-parallel) interface to ARM io controller
   output      	SPI_DO,
	input       	SPI_DI,
   input       	SPI_SCK,
   input 			SPI_SS2,
   input 			SPI_SS3,
   input 			SPI_SS4,
	input       	CONF_DATA0, 

	// VGA interface
   output 			VGA_HS,
   output 	 		VGA_VS,
   output [5:0] 	VGA_R,
   output [5:0] 	VGA_G,
   output [5:0] 	VGA_B,
	
	// other
	output         LED,
	input          UART_RX,
	output         AUDIO_L,
	output         AUDIO_R
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @pll *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire pll_locked;
wire sys_clock;      // cpu x 8 = 29491200
wire sdram_clock;    // cpu x 8 with -2.5ns offset for the SDRAM module
wire CLOCK;          // cpu = 3686400
wire vdp_clock;      // cpu x 3 = 11059200 (closest integer multiple to 10738635)
wire vdp_clock2x;    // vpd_clock x 2 = 22118400 for the scandoubler

pll pll (
	 .inclk0 ( CLOCK_27[0] ),
	 .locked ( pll_locked  ),     
	 .c0     ( sys_clock   ),     
	 .c1     ( vdp_clock   ),     
	 .c2     ( sdram_clock ),     
	 .c3     ( vdp_clock2x ),
	 .c4     ( CLOCK       )     
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @ena *******************************************/
/******************************************************************************************/
/******************************************************************************************/

reg [3:0] cnt = 0;

always @(posedge sys_clock) begin
	cnt <= cnt + 1;	
end

wire z80_ena = cnt == 0 || cnt == 8;
wire psg_ena = cnt == 0;


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @reset *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// RESET goes into: t80a, vdp, psg, ctc

// reset while booting or when the physical reset key is pressed
wire RESET = ~ROM_loaded | reset_key | eraser_busy; 

// stops the cpu when booting, downloading or erasing
wire WAIT = ~ROM_loaded | is_downloading | (debugger_busy | ~debug_done);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @lm80c *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// video
wire [5:0] R;
wire [5:0] G;
wire [5:0] B;
wire       HS;
wire       VS;

// audio
wire [7:0] CHANNEL_L;
wire [7:0] CHANNEL_R;

// keyboard
wire [7:0] row_select;
wire [7:0] column_bits;

// ram
wire [15:0] ram_addr;
wire [7:0]  ram_dout;
wire [7:0]  ram_din;
wire        ram_rd;
wire        ram_wr;	

lm80c lm80c
(	
	.RESET ( RESET ),
	.WAIT  ( WAIT  ),
	
   // clocks
	.sys_clock ( sys_clock ),
	.vdp_clock ( vdp_clock ),
	.z80_ena   ( z80_ena   ),
	.psg_ena   ( psg_ena   ),
			
	// video
	.R  ( R  ),
	.G  ( G  ),
	.B  ( B  ),
	.HS ( HS ),
	.VS ( VS ),
	
	// audio
	.CHANNEL_L( CHANNEL_L ),
   .CHANNEL_R( CHANNEL_R ), 
	
	// keyboard
	.KM(KM),	
	
	// RAM interface
	.ram_addr ( ram_addr   ),
	.ram_dout ( ram_dout   ),	
	.ram_din  ( sdram_dout ),
	.ram_rd   ( ram_rd     ),
	.ram_wr   ( ram_wr     )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @keyboard **************************************/
/******************************************************************************************/
/******************************************************************************************/
		 
wire ps2_kbd_clk;
wire ps2_kbd_data;

wire reset_key;
wire [7:0] KM[7:0];

keyboard keyboard 
(
	.reset    ( !pll_locked  ),
	.clk      ( sys_clock    ),

	.KM       ( KM           ),	
	.resetkey ( reset_key    ),

	.ps2_clk  ( ps2_kbd_clk  ),
	.ps2_data ( ps2_kbd_data )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @user_io ***************************************/
/******************************************************************************************/
/******************************************************************************************/
       
// menu configuration string passed to user_io
localparam conf_str = {
	"LM80C;PRG;", // must be UPPERCASE	
	"T3,Hard reset"	
};

localparam conf_str_len = $size(conf_str)>>3;

wire [7:0] status;       // the status register is controlled by the user_io module

wire st_power_on = status[0];
wire st_reset    = status[3];

wire scandoubler_disable;
wire ypbpr;
wire no_csync;

user_io #
(
	.STRLEN(conf_str_len),
	.PS2DIV(14)              // ps2 clock divider: CLOCK / 14 must be approx = 15 Khz
)
user_io ( 
	.conf_str   ( conf_str   ),

	.SPI_CLK    ( SPI_SCK    ),
	.SPI_SS_IO  ( CONF_DATA0 ),
	.SPI_MISO   ( SPI_DO     ),
	.SPI_MOSI   ( SPI_DI     ),

	.scandoubler_disable ( scandoubler_disable ),
	.ypbpr               ( ypbpr               ),
	.no_csync            ( no_csync            ),
	
	.status     ( status     ),
	
	.clk_sys    ( sys_clock ),
	.clk_sd     ( sys_clock ),       // sd card clock
	 
	// ps2 interface
	.ps2_kbd_clk    ( ps2_kbd_clk    ),
	.ps2_kbd_data   ( ps2_kbd_data   ),	
	
	// sd card interface
	.img_mounted( img_mounted ),
	.img_size   ( img_size    ) 
);

wire        img_mounted; // rising edge if a new image is mounted
wire [31:0] img_size;    // size of image in bytes


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @mist_video ************************************/
/******************************************************************************************/
/******************************************************************************************/

mist_video 
#
(
	.SYNC_AND(1)
) 
mist_video
(
	.clk_sys(vdp_clock2x),       // twice the VDP clock for the scandoubler

	// OSD SPI interface
   .SPI_DI(SPI_DI),
   .SPI_SCK(SPI_SCK),
   .SPI_SS3(SPI_SS3),

	.scanlines(2'b00),           // scanlines (00-none 01-25% 10-50% 11-75%)	
	.ce_divider(1),              // non-scandoubled pixel clock divider 0 - clk_sys/4, 1 - clk_sys/2

	.scandoubler_disable(1),     // 0 = HVSync 31KHz, 1 = CSync 15KHz	
	.no_csync(no_csync),         // 1 = disable csync without scandoubler	
	.ypbpr(ypbpr),               // 1 = YPbPr output on composite sync
	
	.rotate(2'b00),              // Rotate OSD [0] - rotate [1] - left or right	
	.blend(0),                   // composite-like blending

	// video input
	.R(R),
	.G(G),
	.B(B),
	.HSync(HS),
	.VSync(VS),

	// MiST video output signals
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);

		
/******************************************************************************************/
/******************************************************************************************/
/***************************************** @downloader ************************************/
/******************************************************************************************/
/******************************************************************************************/

wire        is_downloading;
wire [24:0] download_addr;
wire [7:0]  download_data;
wire        download_wr;
wire        ROM_loaded;

wire [23:0] ioctl_fileext;
wire [31:0] ioctl_filesize;      	

// ROM download helper
downloader 
#(
	.ROM_START_ADDR(25'h0000), // start of ROM 
	.PRG_START_ADDR(25'h8241), // start of BASIC program in free RAM, firmware 3.13.3
	.PTR_PROGND    (25'h81BB)  // pointer to end of basic program
)
downloader (
	
	// new SPI interface
   .SPI_DO ( SPI_DO  ),
	.SPI_DI ( SPI_DI  ),
   .SPI_SCK( SPI_SCK ),
   .SPI_SS2( SPI_SS2 ),
   .SPI_SS3( SPI_SS3 ),
   .SPI_SS4( SPI_SS4 ),
	
	// signal indicating an active rom download
	.downloading ( is_downloading  ),
   .ROM_done    ( ROM_loaded      ),	
	         
   // external ram interface
   .clk   ( CLOCK         ),
   .wr    ( download_wr   ),
   .addr  ( download_addr ),
   .data  ( download_data )	
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @eraser ****************************************/
/******************************************************************************************/
/******************************************************************************************/

wire eraser_busy;
wire eraser_wr;
wire [24:0] eraser_addr;
wire [7:0]  eraser_data;

eraser eraser(
	.clk      ( CLOCK       ),
	.ena      ( 1           ),
	.trigger  ( st_reset    ),	
	.erasing  ( eraser_busy ),
	.wr       ( eraser_wr   ),
	.addr     ( eraser_addr ),
	.data     ( eraser_data )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @sdram *****************************************/
/******************************************************************************************/
/******************************************************************************************/
							
assign SDRAM_CKE = pll_locked; // was: 1'b1 in lesson4/soc.v
assign SDRAM_CLK = ~sys_clock; // sdram_clock;

wire [24:0] sdram_addr   ;
wire        sdram_wr     ;
wire        sdram_rd     ;
wire [7:0]  sdram_dout   ; 
wire [7:0]  sdram_din    ; 

wire [7:0]  true_sdram_dout ; 

always @(*) begin
	if(is_downloading && download_wr) begin
		sdram_din    = download_data;
		sdram_addr   = download_addr;
		sdram_wr     = download_wr;
		sdram_rd     = 1'b1;
	end	
	else if(eraser_busy) begin		
		sdram_din    = eraser_data;
		sdram_addr   = eraser_addr;
		sdram_wr     = eraser_wr;
		sdram_rd     = 1'b1;		
	end	
	else if(debugger_busy) begin		
		sdram_din    = debug_data_wr;		
		sdram_addr   = debug_addr;
		sdram_wr     = debug_wr;
		sdram_rd     = 1'b1;		
	end	
	else begin
		sdram_din    = ram_dout;
		sdram_addr   = ram_addr;
		sdram_wr     = ram_wr;
		sdram_rd     = ram_rd;
	end	
end

// sdram module taken from from lesson4\sdram.v and 
// modified to output the "initialized" signal

// the sdram has the following requirements:
//
// - "sys_clock": 8x faster than cpu so that cpu reads in 1 cpu cycle
// - "sdram_clock": 8x faster -2.5ns delayed clock so that SDRAM sees stable cpu signals
// - timing constraints in .sdc file
// - can't be accessed before it's initialized ("initialized" pin)

wire sdram_initialized;

sdram sdram 
(
	// interface to the MT48LC16M16 chip
   .sd_data        ( SDRAM_DQ                  ),
   .sd_addr        ( SDRAM_A                   ),
   .sd_dqm         ( {SDRAM_DQMH, SDRAM_DQML}  ),
   .sd_cs          ( SDRAM_nCS                 ),
   .sd_ba          ( SDRAM_BA                  ),
   .sd_we          ( SDRAM_nWE                 ),
   .sd_ras         ( SDRAM_nRAS                ),
   .sd_cas         ( SDRAM_nCAS                ),

   // system interface
   .clk            ( sys_clock                 ),
   .clkref         ( CLOCK                     ),
   .init           ( !pll_locked               ),
	//.initialized    ( sdram_initialized         ),

   // cpu interface	
   .din            ( sdram_din                 ),
   .addr           ( sdram_addr                ),
   .we             ( sdram_wr                  ),
   .oe         	 ( 1 /*sdram_rd*/            ),	
   .dout           ( true_sdram_dout                )	
);

sysram sysram 
(
  .clock  ( sys_clock        ),
  .address( sdram_addr[15:0] ),  
  .data   ( sdram_din        ),                       
  .wren   ( sdram_wr         ),                       
  .q      ( sdram_dout       )
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @audio *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// TODO audio 
dac #(.C_bits(8)) dac_L
(
	.clk_i  ( sys_clock       ),
   .res_n_i( pll_locked      ),	
	.dac_i  ( CHANNEL_L       ),
	.dac_o  ( AUDIO_L       )
);

// TODO audio 
dac #(.C_bits(8)) dac_R
(
	.clk_i  ( sys_clock       ),
   .res_n_i( pll_locked      ),	
	.dac_i  ( CHANNEL_R       ),
	.dac_o  ( AUDIO_R         )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @debug *****************************************/
/******************************************************************************************/
/******************************************************************************************/

reg        debugger_busy;
wire       debug_done;
reg  [7:0] debug_counter;

reg [15:0] debug_addr;
wire [7:0] debug_data_rd;
reg  [7:0] debug_data_wr;
reg        debug_wr;

reg debug;

assign LED = ~debug;

// debugs that ROM is loaded correctly (first 4 bytes checked)
always @(posedge CLOCK) begin
	if(RESET) begin
		debugger_busy <= 0;	
		debug_addr    <= 'hffff;
		debug_counter <= 0;
		debug_done    <= 0;
		debug         <= 0;
	end
	else begin
		
		if(!debug_done) begin
			debugger_busy <= 1;
			debug_addr    <= debug_addr + 1;
			debug_wr      <= 0;			
			
			if(debug_addr == 0 && sdram_dout == 'hf3) debug_counter <= debug_counter + 1;
			if(debug_addr == 1 && sdram_dout == 'hc3) debug_counter <= debug_counter + 1;
			if(debug_addr == 2 && sdram_dout == 'h5a) debug_counter <= debug_counter + 1;
			if(debug_addr == 3 && sdram_dout == 'h02) debug_counter <= debug_counter + 1;

			if(debug_addr == 4) begin
				debugger_busy <= 0;
				debug_done <= 1;
			end
			
			//if(debug_counter == 4) debug <= 1;					
		end
		
		debug <= sdram_dout != true_sdram_dout;
	end
end

/*
// simulate a fictional LED peripheral
reg [7:0] LED_latch = 0;

reg [7:0] state;

always @(posedge sys_clock) begin
	if(RESET) begin
		LED_latch <= 0;
		state <= 0;
	end
	else begin
		debug <= (LED_latch != 0);

		//debug <= debug1;
		
		//if(state == 0 && INT_n == 1)            state <= 1;
		//if(state == 1 && INT_n == 0)            state <= 2;
		//if(state == 2 && z80_ena && IORQ && M1) state <= 3;
		//if(state == 3 && z80_ena && IORQ && M1 && ctc_dout == 'h46) state <= 4;
		
		// LED_latch <= (state == 4);		
		
		if(LED_SEL && WR) begin
			LED_latch <= cpu_dout;			
		end
	end
end
*/

endmodule

