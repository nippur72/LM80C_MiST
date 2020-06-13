// LM80C for the MiST
//
// Antonino Porcino, nino.porcino@gmail.com
//
// Derived from source code by Till Harbaum (c) 2015
//

// Uppercase names are symbols defined in the official LM80C.pdf schematic
//
// (FPGA pins are also uppercase)


// TODO sdram
// TODO isolate LM80C in a module
// TODO stereo output
// TODO italian keyboard
// TODO add mist_video
// TODO modify BASTXT and PRGEND vectors in downloader
// TODO sio, pio dummy modules
// TODO parametrize downloader, share with Laser500_MiST
// TODO color problem


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
/***************************************** @osd *******************************************/
/******************************************************************************************/
/******************************************************************************************/

// on screen display

wire [5:0] osd_r;
wire [5:0] osd_g;
wire [5:0] osd_b;

osd 
#
(
	.OSD_AUTO_CE(0)
)
osd (
/*
   .clk_sys    ( ram_clock  ),	
	.ce         ( vdp_ena    ),
*/
	.clk_sys    ( vdp_clock  ),
	.ce         ( 1          ),	

   // spi for OSD
   .SPI_DI     ( SPI_DI     ),
   .SPI_SCK    ( SPI_SCK    ),
   .SPI_SS3    ( SPI_SS3    ),

   .R_in       ( test_r      ),
   .G_in       ( test_g      ),
   .B_in       ( test_b      ),
	
   .HSync      ( test_hs    ),
   .VSync      ( test_vs    ),

/*	
   .R_in       ( vdp_r      ),
   .G_in       ( vdp_g      ),
   .B_in       ( vdp_b      ),
	
   .HSync      ( vdp_hs     ),
   .VSync      ( vdp_vs     ),
*/	
	
   .R_out      ( osd_r      ),
   .G_out      ( osd_g      ),
   .B_out      ( osd_b      )   
);

assign VGA_R = osd_r;
assign VGA_G = osd_g;
assign VGA_B = osd_b;
assign VGA_HS = ~(~test_hs | ~test_vs);
//assign VGA_HS = ~(vdp_hs ^ vdp_vs);
//assign VGA_HS = ~(~vdp_hs | ~vdp_vs);
assign VGA_VS = 1;


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @user_io ***************************************/
/******************************************************************************************/
/******************************************************************************************/
       
// menu configuration string passed to user_io
localparam conf_str = {
	"LM80C;PRG;", // must be UPPERCASE
	"O1,Synchronous VDP,On,Off;",
	"O2,Center VDP frame,On,Off;",
	"T3,Hard reset"	
};

localparam conf_str_len = $size(conf_str)>>3;

wire [7:0] status;       // the status register is controlled by the user_io module

wire st_power_on     = status[0];
wire st_sync_vpd     = ~status[1];  // 1=VDP has a synchronous clock, 0=original async clock
wire st_center_frame = ~status[2];  // 0=use original VDP output, 1=center frame
wire st_reset        = status[3];


user_io #
(
	.STRLEN(conf_str_len),
	.PS2DIV(14)              // ps2 clock divider: CLOCK / 24 must be approx = 15 Khz
)
user_io ( 
	.conf_str   ( conf_str   ),

	.SPI_CLK    ( SPI_SCK    ),
	.SPI_SS_IO  ( CONF_DATA0 ),
	.SPI_MISO   ( SPI_DO     ),
	.SPI_MOSI   ( SPI_DI     ),

	.status     ( status     ),
	
	.clk_sys    ( ram_clock ),
	.clk_sd     ( ram_clock ),       // sd card clock
	 
	// ps2 interface
	.ps2_kbd_clk    ( ps2_kbd_clk    ),
	.ps2_kbd_data   ( ps2_kbd_data   ),	
	
	// sd card interface
	.img_mounted( img_mounted ),
	.img_size   ( img_size    ) 
);

wire          img_mounted; //rising edge if a new image is mounted
wire   [31:0] img_size;    // size of image in bytes


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @keyboard **************************************/
/******************************************************************************************/
/******************************************************************************************/
		 
wire ps2_kbd_clk;
wire ps2_kbd_data;

wire [7:0] port_B;
wire       reset_key;

wire debug1;

assign psg_IOA_out = 255;
assign psg_IOB_in  = 255;

keyboard keyboard 
(
	.reset    ( !pll_locked  ),
	.clk      ( ram_clock    ),

	.ps2_clk  ( ps2_kbd_clk  ),
	.ps2_data ( ps2_kbd_data ),
	
	.column_bits ( psg_IOA_in  ),
	.row_select  ( psg_IOB_out ),
	
	.reset_key( reset_key    ),
	.debug1   ( debug1       )
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
wire        boot_completed;

// ROM download helper
downloader downloader (
	
	// new SPI interface
   .SPI_DO ( SPI_DO  ),
	.SPI_DI ( SPI_DI  ),
   .SPI_SCK( SPI_SCK ),
   .SPI_SS2( SPI_SS2 ),
   .SPI_SS3( SPI_SS3 ),
   .SPI_SS4( SPI_SS4 ),
	
	// signal indicating an active rom download
	.downloading ( is_downloading  ),
   .ROM_done    ( boot_completed  ),	
	         
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
/***************************************** @t80 *******************************************/
/******************************************************************************************/
/******************************************************************************************/
	
//
// Z80 CPU
//
	
// CPU control signals
wire [15:0] A;
wire [7:0]  cpu_dout;

wire WR_n;
wire RD_n;
wire IORQ_n;
wire MREQ_n;
wire M1_n;

wire WR   = ~WR_n;
wire RD   = ~RD_n;
wire IORQ = ~IORQ_n;
wire MREQ = ~MREQ_n;
wire M1   = ~M1_n;

// t80cpu was taken from https://github.com/sorgelig/Amstrad_MiST by sorgelig

t80pa cpu
(
	.reset_n ( ~RESET        ),  
	
	.clk     ( ram_clock     ), 
	
	.CEN_p   ( z80_ena       ),	

	.a       ( A             ),   
	.DO      ( cpu_dout      ),   
	.di      ( cpu_din       ),   
	
	.rd_n    ( RD_n          ),   
	.wr_n    ( WR_n          ),   
	
	.iorq_n  ( IORQ_n        ),   
	.mreq_n  ( MREQ_n        ),   

	.int_n   ( INT_n         ),   
	.nmi_n   ( VDP_INT_n     ),   

	.m1_n    ( M1_n          ),   
	.rfsh_n  ( 0             ),   
	.busrq_n ( 1             ),   
	.wait_n  ( ~WAIT         )    
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @address decoder********************************/
/******************************************************************************************/
/******************************************************************************************/

reg PIO_SEL;
reg CTC_SEL;
reg SIO_SEL;
reg VDP_SEL;
reg PSG_SEL;
reg LED_SEL;
reg CSR;
reg CSW;
reg BDIR;
reg BC;
reg RAM_SEL;
reg ROM_SEL;

reg [7:0] cpu_din;


always @(posedge ram_clock) begin

	PIO_SEL <= (A[7:4] == 'b0000) & IORQ & ~MREQ;
	CTC_SEL <= (A[7:4] == 'b0001) & IORQ & ~MREQ;
	SIO_SEL <= (A[7:4] == 'b0010) & IORQ & ~MREQ;
	VDP_SEL <= (A[7:4] == 'b0011) & IORQ & ~MREQ;
	PSG_SEL <= (A[7:4] == 'b0100) & IORQ & ~MREQ;

	// debug LED on port 255
	LED_SEL <= (A[7:0] == 255) & IORQ & ~MREQ;
	 
	CSR <= RD_n | (IORQ_n | ~VDP_SEL);
	CSW <= WR_n | (IORQ_n | ~VDP_SEL);

	BDIR = ~(~WR | ~PSG_SEL);
	BC   = ~(A[0] | ~PSG_SEL);

	//RAM_SEL <=  A[15] & MREQ;
	RAM_SEL <= MREQ && (A > 32767 && A < 49152);
	ROM_SEL <= MREQ & A[15]==0;

	if(RD) begin
		cpu_din <= (
			PIO_SEL ? 0         :
			CTC_SEL ? ctc_dout  :
			SIO_SEL ? 0         :
			VDP_SEL ? vdp_dout  :
			PSG_SEL ? psg_dout  :
		   LED_SEL ? LED_latch : sdram_dout	
		);		
	end
	else if(IORQ && M1) begin
		cpu_din <= ctc_dout;
	end

end

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @vdp *******************************************/
/******************************************************************************************/
/******************************************************************************************/

// this TMS9918A implementation is from 
// https://github.com/wsoltys/mist-cores/tree/master/fpga_colecovision/src/vdp18

wire VDP_INT_n;


wire vdp_hs;
wire vdp_vs;

wire [0:7] vdp_r_;		
wire [0:7] vdp_g_;
wire [0:7] vdp_b_;

wire [5:0] vdp_r = { vdp_r_[0],vdp_r_[1],vdp_r_[2],vdp_r_[3],vdp_r_[4],vdp_r_[5] } ;
wire [5:0] vdp_g = { vdp_g_[0],vdp_g_[1],vdp_g_[2],vdp_g_[3],vdp_g_[4],vdp_g_[5] } ;
wire [5:0] vdp_b = { vdp_b_[0],vdp_b_[1],vdp_b_[2],vdp_b_[3],vdp_b_[4],vdp_b_[5] } ;

wire vram_ce;
wire vram_oe;
wire vram_we;

wire [0:13] vram_a;        
wire [0:7]  vram_din;      // TODO attenzione agli indici invertiti!?
wire [0:7]  vram_dout;

wire [7:0] vdp_dout;
		
vdp18_core
  
#(
	.is_pal_g(0)     // NTSC	
) 

vdp
(
	/*
	.clk_i         ( ram_clock   ),
	.clk_en_10m7_i ( vdp_ena     ),
	*/
	
	.clk_i         ( vdp_clock   ),
	.clk_en_10m7_i ( 1           ),

	.reset_n_i     ( ~RESET      ),
	
   .csr_n_i       ( CSR         ),
   .csw_n_i       ( CSW         ),
	
   .mode_i        ( A[1]        ),
		
   .int_n_o       ( VDP_INT_n   ),
	
   .cd_i          ( cpu_dout    ),
   .cd_o          ( vdp_dout    ),
		
   .vram_we_o     ( vram_we     ),
   .vram_a_o      ( vram_a      ),
   .vram_d_o      ( vram_din    ),
   .vram_d_i      ( vram_dout   ),
	
   .rgb_r_o       ( vdp_r_  ),
   .rgb_g_o       ( vdp_g_  ),
   .rgb_b_o       ( vdp_b_  ),
	
   .hsync_n_o     ( vdp_hs ),
   .vsync_n_o     ( vdp_vs )

);

vram vram
(
  .address( vram_a     ),
  //.clock  ( ram_clock  ),
  //.clock  ( tms_clock  ),
  .clock  ( vdp_clock  ),
  .data   ( vram_din   ),                       
  .wren   ( vram_we    ),                       
  .q      ( vram_dout  )
);

// @test
reg [15:0] hcnt;
reg [15:0] vcnt;
reg flip = 0;

always @(posedge vdp_clock) begin
	if(RESET) begin
		hcnt <= -38; //-{ 8'b0, LED_latch };
		vcnt <= 0;
	end
	else begin
		flip = ~flip;
		if(flip) begin
			hcnt <= hcnt + 1;
			if(hcnt == 341) begin
				hcnt <= 0;
				vcnt <= vcnt + 1;
				if(vcnt == 260) vcnt <= 0;
			end
		end
	end	
end

wire test_vs = st_center_frame ? (vcnt < 4  ? 0 : 1) : vdp_hs;
wire test_hs = st_center_frame ? (hcnt < 20 ? 0 : 1) : vdp_vs;

wire [15:0] stripe = hcnt / 32;

wire blank   = (vcnt < 8) || (hcnt < 60 || hcnt > 340);

wire [5:0] test_r = st_center_frame ? (blank ? 0 : vdp_r) : vdp_r;
wire [5:0] test_g = st_center_frame ? (blank ? 0 : vdp_g) : vdp_r;
wire [5:0] test_b = st_center_frame ? (blank ? 0 : vdp_b) : vdp_r;


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @psg *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] CHANNEL_A; // PSG Output channel A
wire [7:0] CHANNEL_B; // PSG Output channel B
wire [7:0] CHANNEL_C; // PSG Output channel C

wire [7:0] psg_dout;

wire [7:0] psg_IOA_in;
wire [7:0] psg_IOA_out;

wire [7:0] psg_IOB_in;
wire [7:0] psg_IOB_out;

YM2149 YM2149
(
	.CLK   ( ram_clock   ),
	.CE    ( psg_ena     ),
	.RESET ( RESET       ),
	.BDIR  ( BDIR        ),
	.BC    ( BC          ),
	
	.CHANNEL_A( CHANNEL_A ),
	.CHANNEL_B( CHANNEL_B ),
	.CHANNEL_C( CHANNEL_C ),
	
	.DI( cpu_dout ),
	.DO( psg_dout ),

	.SEL( 0 ),                   // 0=normal freq, 1=x2 freq
	
	.IOA_in  ( psg_IOA_in  ),
	.IOA_out ( psg_IOA_out ),	
	.IOB_in  ( psg_IOB_in  ),
	.IOB_out ( psg_IOB_out )	
	
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @ctc *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] ctc_dout;
wire INT_n;

z80ctc_top z80ctc_top
(
	.clock     ( ram_clock  ),
	.clock_ena ( z80_ena    ),
	.reset     ( RESET      ),
	.din       ( cpu_dout   ),
	.dout      ( ctc_dout   ),
	.cpu_din   ( cpu_din    ),
	.ce_n      ( ~CTC_SEL   ),
	.cs        ( A[1:0]     ),
	.m1_n      ( M1_n       ),
	.iorq_n    ( IORQ_n     ),
	.rd_n      ( RD_n       ),
   .int_n     ( INT_n      )
	
	// trigger 0-3 are not connected
	// daisy chain not available in this Z80CTC implementation
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @pll *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire ram_clock;
wire CLOCK;
wire F11M;
wire F10M;

wire pll_locked = pll_sys_locked & pll_tms9918_locked;
wire pll_sys_locked;
wire pll_tms9918_locked;

pll pll (
	 .inclk0 ( CLOCK_27[0] ),
	 .locked ( pll_sys_locked  ),     
	 .c0     ( ram_clock       ),     
	 .c2     ( CLOCK           ),     
	 .c1     ( F11M            ),     
);


pll_tms9918 pll_tms9918 (
	 .inclk0 ( CLOCK_27[0]         ),
	 .locked ( pll_tms9918_locked  ),     
	 .c0     ( F10M                ),    
);


wire vdp_clock = st_sync_vpd ? F11M : F10M;

reg [3:0] cnt = 0;

always @(posedge ram_clock) begin
	cnt <= cnt + 1;	
end

wire z80_ena = cnt == 0 || cnt == 8;
wire psg_ena = cnt == 0;


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @sdram *****************************************/
/******************************************************************************************/
/******************************************************************************************/
							
// SDRAM control signals
//assign SDRAM_CKE = pll_locked; // was: 1'b1;
//assign SDRAM_CLK = ram_clock;

wire [24:0] sdram_addr   ;
wire        sdram_wr     ;
wire        sdram_rd     ;
wire [7:0]  sdram_dout   ; 
wire [7:0]  sdram_din    ; 

always @(posedge ram_clock) begin
	if(is_downloading) begin
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
		sdram_din     = debug_data_wr;		
		sdram_addr    = debug_addr;
		sdram_wr      = debug_wr;
		sdram_rd      = 1'b1;		
	end	
	else begin
		sdram_din    = cpu_dout;
		sdram_addr   = A;
		sdram_wr     = WR & MREQ & RAM_SEL;
		sdram_rd     = RD & MREQ;
	end	
end

sysram sysram 
(
  .address( sdram_addr[15:0] ),
  .clock  ( ram_clock        ),
  .data   ( sdram_din        ),                       
  .wren   ( sdram_wr         ),                       
  .q      ( sdram_dout       )
);

/*
// sdram from zx spectrum core	
sdram sdram (
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
   .clk            ( ram_clock                 ),
   .clkref         ( CLOCK                     ),
   .init           ( !pll_locked               ),

   // cpu interface	
   .din            ( sdram_din                 ),
   .addr           ( sdram_addr                ),
   .we             ( sdram_wr                  ),
   .oe         	 ( sdram_rd                  ),	
   .dout           ( sdram_dout                )	
);
*/

/*
// sdram from fpgacoleco
sdram sdram (
                                  
	// interface to the MT48LC16M16 chip
   .SDRAM_DQ       ( SDRAM_DQ                  ),
   .SDRAM_A        ( SDRAM_A                   ),
   .SDRAM_DQMH     ( SDRAM_DQMH                ),
   .SDRAM_DQML     ( SDRAM_DQML                ),
   .SDRAM_nCS      ( SDRAM_nCS                 ),
   .SDRAM_BA       ( SDRAM_BA                  ),
   .SDRAM_nWE      ( SDRAM_nWE                 ),
   .SDRAM_nRAS     ( SDRAM_nRAS                ),
   .SDRAM_nCAS     ( SDRAM_nCAS                ),
	.SDRAM_CKE      ( SDRAM_CKE                 ),
	
	.wtbt           ( 2'b00                     ),

   // system interface
   .clk            ( !ram_clock                ),   
   .init           ( !pll_locked               ),

   // cpu interface	
	.dout           ( sdram_dout                ),	
   .din            ( sdram_din                 ),
   .addr           ( sdram_addr                ),
   .we             ( sdram_wr                  ),
   .rd         	 ( sdram_rd                  )	   
);
*/


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @reset *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// stops the cpu when booting, downloading or erasing
wire WAIT = ~boot_completed | is_downloading | eraser_busy | debugger_busy;

// reset while booting or when the physical reset key is pressed
// RESET goes into: t80a, vdp, psg, ctc
wire RESET = ~boot_completed | reset_key | eraser_busy; 

reg [63:0] long_counter;
always @(posedge ram_clock) begin
	if(RESET) begin
		long_counter <= 0;
	end
	else begin
		long_counter <= long_counter + 1;
	end		
end

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @audio *****************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [9:0] channel_sum = CHANNEL_A + CHANNEL_B + CHANNEL_C;
wire [15:0] dac_audio_in = { channel_sum, 6'b000000 };
wire dac_audio_out; 

// TODO audio 
dac #(.C_bits(16)) dac_AUDIO_L
(
	.clk_i  ( ram_clock     ),
   .res_n_i( pll_locked    ),	
	.dac_i  ( dac_audio_in  ),
	.dac_o  ( dac_audio_out )
);

always @(posedge ram_clock) begin
	AUDIO_L <= dac_audio_out;
	AUDIO_R <= dac_audio_out;
end


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @debug *****************************************/
/******************************************************************************************/
/******************************************************************************************/




reg        debugger_busy;
wire       debug_done;
wire [7:0] debug_data_rd;
reg  [7:0] debug_data_wr;
reg [15:0] debug_addr;
reg        debug_wr;

reg  [7:0] debug_counter;
reg  [7:0] debug_ok;

reg debug;

assign LED = ~debug;

/*
// debugs that ROM is loaded correctly (first 4 bytes checked)
always @(posedge ram_clock) begin
	if(!RESET) begin
		debugger_busy <= 0;	
		debug_addr    <= 'hffff;
		debug_counter <= 0;
		debug_done    <= 0;
		debug         <= 0;
	end
	else begin
		if(z80_ena) begin
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
				
				if(debug_counter == 4) debug <= 1;					
			end
			
		end
	end
end
*/

// simulate a fictional LED peripheral
reg [7:0] LED_latch = 0;

reg [7:0] state;

always @(posedge ram_clock) begin
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


endmodule

