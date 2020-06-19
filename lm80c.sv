module lm80c
(	
	input RESET,
	input WAIT,
	
   // clocks
	input sys_clock,		
	input vdp_clock,	
	
	input vdp_ena,
	input z80_ena,	
	input psg_ena,
		
	// video
	output [5:0] R,
	output [5:0] G,
	output [5:0] B,
	output       HS,
	output       VS,
	
	// audio
	output [7:0] CHANNEL_L, 
   output [7:0] CHANNEL_R, 
	
	// keyboard	
	input [7:0] KM[7:0],
	
	// RAM interface
	output [15:0] ram_addr,
	output  [7:0] ram_din,
	input   [7:0] ram_dout,
	output        ram_rd,
	output        ram_wr,	

	// sdram test interface
	output reg [15:0] x_sdram_addr,
	output reg  [7:0] x_sdram_din,
	input       [7:0] x_sdram_dout,
	output            x_sdram_rd,
	output            x_sdram_wr	
);

assign ram_addr = A;
assign ram_din  = cpu_dout;
assign ram_rd   = MREQ & RD & ~IORQ;
assign ram_wr   = MREQ & WR & ~IORQ & RAM_SEL;

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @t80 *******************************************/
/******************************************************************************************/
/******************************************************************************************/
	
//
// Z80 CPU
//
	
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
	
	.clk     ( sys_clock     ), 
	
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

wire [7:0] pio_dout = 8'b0;  // PIO not implemented yet
wire [7:0] sio_dout = 8'b1;  // SIO not implemented yet

always @(posedge sys_clock) begin

	PIO_SEL <= (A[7:4] == 'b0000) & IORQ & ~MREQ;
	CTC_SEL <= (A[7:4] == 'b0001) & IORQ & ~MREQ;
	SIO_SEL <= (A[7:4] == 'b0010) & IORQ & ~MREQ;
	VDP_SEL <= (A[7:4] == 'b0011) & IORQ & ~MREQ;
	PSG_SEL <= (A[7:4] == 'b0100) & IORQ & ~MREQ;	
	
	LED_SEL <= (A[7:0]>=200 || A[7:0]<=254) & IORQ & ~MREQ;
	 
	CSR <= RD_n | (IORQ_n | ~VDP_SEL);
	CSW <= WR_n | (IORQ_n | ~VDP_SEL);

	BDIR = ~(~WR | ~PSG_SEL);
	BC   = ~(A[0] | ~PSG_SEL);

	//RAM_SEL <=  A[15] & MREQ;
	RAM_SEL <= MREQ && (A > 32767 && A < 49152);
	ROM_SEL <= MREQ & A[15]==0;

	if(RD && IORQ) 
		cpu_din <=  PIO_SEL ? pio_dout :
						CTC_SEL ? ctc_dout :
						SIO_SEL ? sio_dout :
						VDP_SEL ? vdp_dout :
						PSG_SEL ? psg_dout :
						LED_SEL ? led_dout : A[7:0];		

	if(RD && MREQ) 
		cpu_din <= ram_dout;
		
	if(IORQ && M1) 
		cpu_din <= ctc_dout;
	
end

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @vdp *******************************************/
/******************************************************************************************/
/******************************************************************************************/

// this TMS9918A implementation is from 
// https://github.com/wsoltys/mist-cores/tree/master/fpga_colecovision/src/vdp18
// modified to draw +5 dot pixels so to match the 10.7 Mhz speed

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
	.clk_i         ( vdp_clock   ),
	.clk_en_10m7_i ( vdp_ena     ),
	
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
  .clock  ( vdp_clock  ),  
  .address( vram_a     ),  
  .data   ( vram_din   ),                       
  .wren   ( vram_we    ),                       
  .q      ( vram_dout  )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @test ******************************************/
/******************************************************************************************/
/******************************************************************************************/

reg [15:0] hcnt;
reg [15:0] vcnt;
reg flip = 0;

always @(posedge vdp_clock) begin
	if(vdp_ena) begin	
		if(RESET) begin
			hcnt <= -36;
			vcnt <= 0;
		end
		else begin
			flip = ~flip;
			if(flip) begin
				hcnt <= hcnt + 1;
				if(hcnt == 341+5) begin
					hcnt <= 0;
					vcnt <= vcnt + 1;
					if(vcnt == 260) vcnt <= 0;
				end
			end
		end	
	end
end

wire test_vs = 1 ? (vcnt < 4  ? 0 : 1) : vdp_hs;
wire test_hs = 1 ? (hcnt < 20 ? 0 : 1) : vdp_vs;

wire blank   = (vcnt < 8) || (hcnt < 60 || hcnt > 340);

wire [5:0] test_r = 1 ? (blank ? 0 : vdp_r) : vdp_r;
wire [5:0] test_g = 1 ? (blank ? 0 : vdp_g) : vdp_r;
wire [5:0] test_b = 1 ? (blank ? 0 : vdp_b) : vdp_r;

assign R  = test_r;
assign G  = test_g;
assign B  = test_b;
assign HS = test_hs;
assign VS = test_vs;


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @psg *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] CHANNEL_A; // PSG Output channel A
wire [7:0] CHANNEL_B; // PSG Output channel B
wire [7:0] CHANNEL_C; // PSG Output channel C

wire [7:0] psg_dout;

YM2149 YM2149
(
	.CLK   ( sys_clock   ),
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
	
	.IOA_in  ( KB  ),
	.IOB_out ( KA  )	
	
);

wire [8:0] sum_L = CHANNEL_A + CHANNEL_C;
wire [8:0] sum_R = CHANNEL_A + CHANNEL_C;

assign CHANNEL_L = sum_L[8:1];
assign CHANNEL_R = sum_R[8:1];


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @keyboard **************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] KA; 
wire [7:0] KB = ((KA[ 0] == 0) ? KM[ 0] : 8'b11111111) &
                ((KA[ 1] == 0) ? KM[ 1] : 8'b11111111) & 
			       ((KA[ 2] == 0) ? KM[ 2] : 8'b11111111) &
				    ((KA[ 3] == 0) ? KM[ 3] : 8'b11111111) &
				    ((KA[ 4] == 0) ? KM[ 4] : 8'b11111111) &
				    ((KA[ 5] == 0) ? KM[ 5] : 8'b11111111) &
				    ((KA[ 6] == 0) ? KM[ 6] : 8'b11111111) &
				    ((KA[ 7] == 0) ? KM[ 7] : 8'b11111111) ;		

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @ctc *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire [7:0] ctc_dout;
wire INT_n;

z80ctc_top z80ctc_top
(
	.clock     ( sys_clock  ),
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
/***************************************** @ena *******************************************/
/******************************************************************************************/
/******************************************************************************************/


always @(posedge sys_clock) begin
	if(z80_ena) begin
		if(LED_SEL) begin
			if(WR && A[7:0] == 200) begin x_sdram_wr  <= 0;	x_sdram_addr[ 7:0] <= cpu_dout; end
			if(WR && A[7:0] == 201) begin x_sdram_wr  <= 0;	x_sdram_addr[15:8] <= cpu_dout; end
			if(A[7:0] == 202) begin
				if(WR) begin
					x_sdram_din <= cpu_dout;			
					x_sdram_wr  <= 1;
				end 
				if(RD) begin
					x_sdram_wr  <= 0;					
				end				
			end			
		end
	end
end

wire [7:0] led_dout = (RD && A[7:0] == 200) ? x_sdram_addr[ 7:0] :
			             (RD && A[7:0] == 201) ? x_sdram_addr[15:8] :
							 (RD && A[7:0] == 202) ? x_sdram_dout       : 'hfe;			

endmodule

