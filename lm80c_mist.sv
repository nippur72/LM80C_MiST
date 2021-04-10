// LM80C for the MiST
//
// Antonino Porcino, nino.porcino@gmail.com
//

// TODO aggiungere "or reset" negli always
// TODO italian keyboard
// TODO rendere PIO un modulo separato
// TODO sio dummy modules
// TODO color problem (check pixel to pixel, vsync>200?)
// TODO understand dowloader/data_io need for CLOCK


// top level module
									  
module lm80c_mist ( 
   input [1:0] 	CLOCK_27,
	
	// SDRAM interface
	inout [15:0]  	SDRAM_DQ, 		// SDRAM Data bus 16 Bits
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
  
   // SPI interface to arm io controller
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

// real CPU speed is 3.686400  MHz
// real VDP speed is 10.738635 MHz

wire pll_locked;
wire vdp_clock;       // 10.738635 x 4
wire sys_clock;       // 3.686400 x 8

pll pll (
	 .inclk0 ( CLOCK_27[0]   ),
	 .locked ( pll_locked    ),        
	 
	 .c0     ( vdp_clock     ),     // vdp x 4   
	 .c1     ( sys_clock     ),     // cpu x 8   
	 .c2     ( SDRAM_CLK     )      // cpu x 8 phase shifted -2.5 ns   
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @ena *******************************************/
/******************************************************************************************/
/******************************************************************************************/

// vdp

reg [1:0] cnt_vdp;
always @(posedge vdp_clock)
	cnt_vdp <= cnt_vdp + 1;
	
wire vdp_ena = cnt_vdp == 0;

// cpu

wire cpu_clock = clk_div[2];
reg [3:0] clk_div;
always @(posedge sys_clock)
	clk_div <= clk_div + 3'd1;

wire z80_ena = clk_div == 0 || clk_div == 8;
wire psg_ena = clk_div == 0;   


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @reset *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// RESET goes into: t80a, vdp, psg, ctc

// reset while booting or when the physical reset key is pressed
wire RESET = ~ROM_loaded | reset_key | st_reset_switch | eraser_busy; 

// stops the cpu when booting, downloading or erasing
wire WAIT = ~ROM_loaded | is_downloading;

assign LED = ~WAIT;

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

// ram interface
wire [15:0] cpu_addr;
wire [7:0]  cpu_dout;
wire        cpu_rd;
wire        cpu_wr;

// PIO
wire [7:0] PIO_data_A;
wire [7:0] PIO_data_B;

wire ROM_ENABLED = PIO_data_B[0];   // bit 0 of PIO B is used to switch between ROM and RAM

lm80c lm80c
(
	.RESET(RESET),
	.WAIT(WAIT),
	
   // clocks
	.sys_clock(sys_clock),		
	.vdp_clock(vdp_clock),	
	
	.vdp_ena(vdp_ena),
	.z80_ena(z80_ena),	
	.psg_ena(psg_ena),
		
	// video
	.R  ( R  ),
	.G  ( G  ),
	.B  ( B  ),
	.HS ( HS ),
	.VS ( VS ),
	
	// audio
	.CHANNEL_L(CHANNEL_L), 
   .CHANNEL_R(CHANNEL_R), 
	
	// keyboard	
	.KM(KM),
	
	// RAM interface
	.ram_addr (cpu_addr),
	.ram_din  (cpu_dout),
	.ram_dout (sdram_dout),
	.ram_rd   (cpu_rd),
	.ram_wr   (cpu_wr),
	
	// parallel port
	.PIO_data_A  (PIO_data_A),
	.PIO_data_B  (PIO_data_B)	
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @keyboard **************************************/
/******************************************************************************************/
/******************************************************************************************/
		 
wire ps2_kbd_clk;
wire ps2_kbd_data;

wire        key_valid;
wire [15:0] key;
wire        key_status;

mist_keyboard mist_keyboard 
(
	.reset    ( !pll_locked  ),
	.clk      ( sys_clock    ),
	
	// simplified keyboard output
	.valid  ( key_valid    ),
	.key    ( key          ),
	.status ( key_status   ),

	// ps2 interface
	.ps2_clk  ( ps2_kbd_clk  ),
	.ps2_data ( ps2_kbd_data )
);


wire reset_key;
wire [7:0] KM[7:0];

lm80c_ps2keyboard_adapter kbd
(
	.reset    ( !pll_locked  ),
	.clk      ( sys_clock    ),
	
	// input
	.valid      ( key_valid    ),
	.key        ( key          ),
	.key_status ( key_status   ),
	
	// output
	.KM       ( KM           ),	
	.resetkey ( reset_key    )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @user_io ***************************************/
/******************************************************************************************/
/******************************************************************************************/
       
// menu configuration string passed to user_io
localparam conf_str = {
	"LM80C;;", 
	"S,SD,Mount image;",      // 1
   "F,PRG,Load program;",    // 2
	"F,ROM,Load firmware;",   // 3 
	"T3,Hard reset;"   
};

localparam conf_str_len = $size(conf_str)>>3;

wire [7:0] status;       
wire [1:0] buttons;
wire [1:0] switches;

wire st_reset_switch = buttons[1];
wire st_menu_reset   = status[3];

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
		
	.status     ( status    ),
	
	.buttons    ( buttons   ),
	.switches   ( switches  ),
	
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
	.SYNC_AND(1),
	.SD_HCNT_WIDTH(11)
) 
mist_video
(
	.clk_sys(vdp_clock),       // 4x the VDP clock for the scandoubler

	// OSD SPI interface
   .SPI_DI(SPI_DI),
   .SPI_SCK(SPI_SCK),
   .SPI_SS3(SPI_SS3),

	.scanlines(2'b00),           // scanlines (00-none 01-25% 10-50% 11-75%)	
	.ce_divider(0),              // non-scandoubled pixel clock divider 0 - clk_sys/4, 1 - clk_sys/2

	.scandoubler_disable(scandoubler_disable),   // 0 = HVSync 31KHz, 1 = CSync 15KHz	
	.no_csync(no_csync),                         // 1 = disable csync without scandoubler	
	.ypbpr(ypbpr),                               // 1 = YPbPr output on composite sync
	
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

// ROM download helper
downloader 
#(
   .BOOT_INDEX (0),
	.PRG_INDEX  (2),
	.ROM_INDEX  (3),	
	.ROM_START_ADDR  (25'h00000), // start of ROM (bank 0 of SDRAM)
	.PRG_START_ADDR  (25'h15608), // start of BASIC program in free RAM: print hex$(deek(BASTXT))
	.PTR_PROGND      (25'h155e4)  // pointer to end of basic program
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
   .clk     ( cpu_clock     ),
	.clk_ena ( 1             ),
   .wr      ( download_wr   ),
   .addr    ( download_addr ),
   .data    ( download_data )	
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
	.clk      ( sys_clock     ),
	.ena      ( z80_ena       ),
	.trigger  ( st_menu_reset ),	
	.erasing  ( eraser_busy   ),
	.wr       ( eraser_wr     ),
	.addr     ( eraser_addr   ),
	.data     ( eraser_data   )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @sdram *****************************************/
/******************************************************************************************/
/******************************************************************************************/
			
// SDRAM control signals
assign SDRAM_CKE = 1'b1;

wire [24:0] sdram_addr;
wire  [7:0] sdram_din;
wire        sdram_wr;
wire        sdram_rd;
wire [7:0]  sdram_dout;

always @(*) begin
	if(is_downloading && download_wr) begin
		sdram_addr   <= download_addr;
		sdram_din    <= download_data;
		sdram_wr     <= download_wr;
		sdram_rd     <= 1'b1;			
	end	
	else if(eraser_busy) begin		
		sdram_addr   <= eraser_addr;
		sdram_din    <= eraser_data;
		sdram_wr     <= eraser_wr;
		sdram_rd     <= 1'b1;		
	end	
	else begin
		sdram_addr   <= { 8'd0, RAM_OFFSET, cpu_addr[15:0] };
		sdram_din    <= cpu_dout;		
		sdram_wr     <= cpu_wr;
		sdram_rd     <= cpu_rd;
	end	
end

// SDRAM is organized the following way:
// from 0-0000 to 0-7FFF LM80C 32K ROM
// from 0-8000 to 0-FFFF unused 
// from 1-0000 to 1-FFFF LM80C 64K RAM
// from 2-0000 to max    unused

wire RAM_OFFSET = ~ROM_ENABLED | (cpu_addr[15:0] > 'h7fff);

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
   .clk            ( sys_clock                 ),
   .clkref         ( cpu_clock                 ),
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
/***************************************** @audio *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// TODO audio 
dac #(.C_bits(8)) dac_L
(
	.clk_i  ( sys_clock       ),
   .res_n_i( pll_locked      ),	
	.dac_i  ( CHANNEL_L       ),
	.dac_o  ( AUDIO_L         )
);

// TODO audio 
dac #(.C_bits(8)) dac_R
(
	.clk_i  ( sys_clock       ),
   .res_n_i( pll_locked      ),	
	.dac_i  ( CHANNEL_R       ),
	.dac_o  ( AUDIO_R         )
);

endmodule
