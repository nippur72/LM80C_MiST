// LM80C for the MiST
//
// Antonino Porcino, nino.porcino@gmail.com
//
// Derived from source code by Till Harbaum (c) 2015
//

// Uppercase names are the one defined in the LM80C.pdf schematic
// There are also some FPGA uppercase PIN names



// TODO audio
// TODO add scandoubler/scanlines
// TODO YPbPr
// TODO true/ita keyboard
								   
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

osd osd (
   .clk_sys    ( vdp_clk    ),	

   // spi for OSD
   .SPI_DI     ( SPI_DI     ),
   .SPI_SCK    ( SPI_SCK    ),
   .SPI_SS3    ( SPI_SS3    ),

   .R_in       ( vdp_r      ),
   .G_in       ( vdp_g      ),
   .B_in       ( vdp_b      ),
	
   .HSync      ( vdp_hs     ),
   .VSync      ( vdp_vs     ),
	
   .R_out      ( osd_r      ),
   .G_out      ( osd_g      ),
   .B_out      ( osd_b      )   
);

assign VGA_R = osd_r;
assign VGA_G = osd_g;
assign VGA_B = osd_b;
assign VGA_HS = vdp_hs & vdp_vs;
assign VGA_VS = 1;


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @user_io ***************************************/
/******************************************************************************************/
/******************************************************************************************/
       
// menu configuration string passed to user_io
localparam conf_str = {
	"LM80C;PRG;", // must be UPPERCASE
	"T3,Reset"
};

localparam conf_str_len = $size(conf_str)>>3;

wire [7:0] status;       // the status register is controlled by the user_io module

wire st_power_on = status[0];
wire st_reset    = status[3];

user_io #
(
	.STRLEN(conf_str_len),
	.PS2DIV(24)              // CLOCK / 25 approx = 15 Khz
)
user_io ( 
	.conf_str   ( conf_str   ),

	.SPI_CLK    ( SPI_SCK    ),
	.SPI_SS_IO  ( CONF_DATA0 ),
	.SPI_MISO   ( SPI_DO     ),
	.SPI_MOSI   ( SPI_DI     ),

	.status     ( status     ),
	
	.clk_sys    ( CLOCK ),
	.clk_sd     ( CLOCK ),       // sd card clock
	 
	// ps2 interface
	.ps2_kbd_clk    ( ps2_kbd_clk    ),
	.ps2_kbd_data   ( ps2_kbd_data   ),	
	
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

wire [ 7:0] port_B;
wire        reset_key;

keyboard keyboard 
(
	.reset    ( !pll_locked  ),
	.clk      ( CLOCK        ),

	.ps2_clk  ( ps2_kbd_clk  ),
	.ps2_data ( ps2_kbd_data ),
	
	.port_A   ( port_A    ),
	.port_B   ( port_B    ),
	.reset_key( reset_key )	
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
wire        cpu_rd_n;
wire        cpu_wr_n;
wire        cpu_mreq_n;
wire        cpu_m1_n;
wire        cpu_iorq_n;

// use names defined in the schematic
wire WR;
wire RD;
wire IORQ;
wire M1;

// t80cpu was taken from https://github.com/sorgelig/Amstrad_MiST by sorgelig

t80pa cpu
(
	.reset_n ( ~RESET        ),  
	
	.clk     ( CLOCK         ),   
	.cen_p   ( cpu_ena       ),   // CPU enable (positive edge)
	.cen_n   ( ~cpu_ena      ),   // CPU enable (negative edge)

	.a       ( A             ),   
	.DO      ( cpu_dout      ),   
	.di      ( cpu_din       ),   
	
	.rd_n    ( RD            ),   
	.wr_n    ( WR            ),   
	
	.iorq_n  ( cpu_iorq_n    ),   
	.mreq_n  ( MREQ          ),   

	.int_n   ( INT           ),   
	.nmi_n   ( VDP_INT       ),   

	.m1_n    ( M1            ),   
	.rfsh_n  ( 0             ),   
	.busrq_n ( 1             ),   
	.wait_n  ( 1             )    
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @address decoder********************************/
/******************************************************************************************/
/******************************************************************************************/
 
wire PIO_SEL = (A[7:4] == 'b0000) & (MREQ & ~IORQ);
wire CTC_SEL = (A[7:4] == 'b0001) & (MREQ & ~IORQ);
wire SIO_SEL = (A[7:4] == 'b0010) & (MREQ & ~IORQ);
wire VDP_SEL = (A[7:4] == 'b0011) & (MREQ & ~IORQ);
wire PSG_SEL = (A[7:4] == 'b0100) & (MREQ & ~IORQ);

wire U20A = ~IORQ | VDP_SEL;
 
wire CSR = RD | U20A;
wire CSW = WR | U20A;

wire BDIR = WR | PSG_SEL;
wire BC   = A[0] | PSG_SEL;

wire [7:0] cpu_din = (
	PIO_SEL ? 0 :
	CTC_SEL ? 0 :
	SIO_SEL ? 0 :
	VDP_SEL ? vdp_dout :
	PSG_SEL ? psg_dout : sdram_dout	
);

wire RAM_SEL =  A[15] & ~MREQ;
wire ROM_SEL = ~A[15] & ~MREQ;

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @vdp *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire VDP_INT;

wire vdp_hs;
wire vdp_vs;

wire [0:7] vdp_r_;		
wire [0:7] vdp_g_;
wire [0:7] vdp_b_;

wire [0:5] vdp_r__ = vdp_r_[2:5];		
wire [0:5] vdp_g__ = vdp_g_[2:5];
wire [0:5] vdp_b__ = vdp_b_[2:5];

wire [5:0] vdp_r = vdp_r__;
wire [5:0] vdp_g = vdp_g__;
wire [5:0] vdp_b = vdp_b__;

wire vram_ce;
wire vram_oe;
wire vram_we;

wire [0:13] vram_a;        
wire [0:7]  vram_din;      // TODO attenzione agli indici invertiti!?
wire [0:7]  vram_dout;

wire [7:0] vdp_dout;
		
vdp18_core vdp
(
	.clock_i       ( CLOCK       ),
	.clk_en_10m7_i ( vdp_clk     ),

	.reset_n_i     ( ~RESET      ),
	
   .csr_n_i       ( CSR         ),
   .csw_n_i       ( CSW         ),
	
   .mode_i        ( A[1] ),
		
   .int_n_o       ( VDP_INT     ),
	
   .cd_i          ( cpu_dout    ),
   .cd_o          ( vdp_dout    ),
		
	.vram_ce_o		( vram_ce     ),
	.vram_oe_o		( vram_oe     ),
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
  .address( vram_a    ),
  .clock  ( vpd_clk   ),
  .data   ( vram_din  ),                       
  .wren   ( vram_we   ),                       
  .q      ( vram_dout )
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @psg *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] CHANNEL_A; // PSG Output channel A
wire [7:0] CHANNEL_B; // PSG Output channel B
wire [7:0] CHANNEL_C; // PSG Output channel C

wire [7:0] psg_dout;

AY8912 AY8912
(
	.CLK   ( CLK2        ),
	.CE    ( 1           ),
	.RESET ( RESET       ),
	.BDIR  ( BDIR        ),
	.BC    ( BC          ),
	
	.CHANNEL_A( CHANNEL_A ),
	.CHANNEL_B( CHANNEL_B ),
	.CHANNEL_C( CHANNEL_C ),
	
	.DI( cpu_dout ),
	.DO( psg_dout ),
	
);

/*
module AY8912
(
   input        SEL,
	input  [7:0] IO_in,
	output [7:0] IO_out
);
*/

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @ctc *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] ctc_dout;
wire INT;

z80ctc_top z80ctc_top
(
	.clock     ( CLOCK      ),
	.clock_ena ( 1          ),
	.reset     ( RESET      ),
	.din       ( cpu_dout   ),
	.dout      ( ctc_dout   ),
	.cpu_din   ( cpu_din    ),
	.ce_n      ( CTC_SEL    ),
	.cs        ( A[1:0]     ),
	.m1_n      ( cpu_m1_n   ),
	.iorq_n    ( cpu_iorq_n ),
	.rd_n      ( cpu_rd_n   ),
   .int_n     ( INT        )
	
	// trigger 0-3 are not connected
	// daisy chain not available in this Z80CTC implementation
);



/******************************************************************************************/
/******************************************************************************************/
/***************************************** @pll *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire pll_locked;
wire vdp_clk;
wire ram_clk;
wire CLOCK;
wire CLK2;

pll pll (
	 .inclk0 ( CLOCK_27[0] ),
	 .locked ( pll_locked  ),     // PLL is running stable
	 .c0     ( vdp_clk     ),     // 10.738635 MHz
	 .c1     ( ram_clk     ),     // CLOCK * 8
	 .c2     ( CLOCK       ),     // 3.686400 MHz
	 .c3     ( CLK2        )      // CLOCK / 2 for the PSG
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @sdram *****************************************/
/******************************************************************************************/
/******************************************************************************************/
							
// SDRAM control signals
assign SDRAM_CKE = pll_locked; // was: 1'b1;
assign SDRAM_CLK = ram_clk;

wire [24:0] sdram_addr   ;
wire        sdram_wr     ;
wire        sdram_rd     ;
wire [7:0]  sdram_dout   ; 
wire [7:0]  sdram_din    ; 

always @(*) begin
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
	else begin
		sdram_din    = cpu_dout;
		sdram_addr   = A;
		sdram_wr     = ~WR & ~MREQ & RAM_SEL;
		sdram_rd     = ~RD & ~MREQ;
	end	
end


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


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @reset *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// stops the cpu when booting, downloading or erasing
wire cpu_ena   = ~boot_completed | is_downloading | eraser_busy;

// reset while booting or when the physical reset key is pressed
wire RESET = ~boot_completed | reset_key; 


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @audio *****************************************/
/******************************************************************************************/
/******************************************************************************************/

wire audio;

// TODO audio 
dac #(.C_bits(16)) dac_AUDIO_L
(
	.clk_i  ( CLOCK      ),
   .res_n_i( pll_locked ),	
	.dac_i  ( { 16'b0 }  ),
	.dac_o  ( audio      )
);

always @(posedge CLOCK) begin
	AUDIO_L <= audio;
	AUDIO_R <= audio;
end


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @debug *****************************************/
/******************************************************************************************/
/******************************************************************************************/

wire debug = 0;

// debug keyboard on the LED
always @(posedge CLOCK) begin
	LED_ON <= debug;
end

reg LED_ON = 0;

assign LED = ~LED_ON;


endmodule