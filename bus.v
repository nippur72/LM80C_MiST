/*
module bus 
(	
	input    cpu_clk,	        // 
	input    RESET,           // initialize at power up
	input    BLANK,           // blank signal - nothing is done	
		
	// cpu interface
   output           CPUCK,       // CPU clock to CPU (F14M / 4) - (not used on the MiST, we use F14M & CPUENA)
	output reg       CPUENA,      // CPU enabled signal
	output           WAIT_n,      // WAIT (TODO handle wait states)
	input            MREQ_n,      // MEMORY REQUEST (not used--yet) indicates the bus holds a valid memory address
	input            IORQ_n,      // IO REQUEST 0=read from I/O
	input            RD_n,        // READ       0=cpu reads
	input            WR_n,        // WRITE      0=cpu writes
	input     [15:0] A,           // 16 bit address bus
	input      [7:0] DO,          // 8 bit data output from cpu
	output reg [7:0] DI,          // 8 bit data input for cpu
	
	// keyboard 	
	input [ 6:0] KD,  
   input        CASIN,

   input [31:0] joystick_0,
	input [31:0] joystick_1,
	
	// sdram interface
	output reg [24:0] sdram_addr, // sdram address  
	input       [7:0] sdram_dout, // sdram data ouput
   output reg  [7:0] sdram_din,  // sdram data input
	output reg        sdram_wr,   // sdram write
	output reg        sdram_rd,   // sdram read	
	
	// output to CRT screen
	output hsync,
	output vsync,
	output [5:0] r,
	output [5:0] g,
	output [5:0] b,
	
	output reg BUZZER,
	output reg CASOUT,   // mapped I/O bit 2  		
	
	input  alt_font,
	output [2:0] cnt,
	
	input          img_mounted, 
   input   [31:0] img_size    
);

// negated signals (easier to read)
wire MREQ   = ~MREQ_n;
wire WR     = ~WR_n;
wire RD     = ~RD_n;
wire IORQ   = ~IORQ_n;

reg MREQ_old;
reg skip_beat;

always@(posedge cpu_clk) begin
	if(RESET) begin
	end
	else begin		   
		
		// === CPU cyles ===
		// CPU_cnt == 3    nothing
		// CPU_cnt == 0    CPU does 1 cycle
		// CPU_cnt == 1    RAM is read or written according to MREQ, RD and WR
		// CPU_cnt == 2    CPU samples bus / turns off write
									
		// detect MREQ state changes
		if(CPU_cnt == 3) begin
			MREQ_old <= MREQ;
			if(MREQ_old == 0 && MREQ == 1) begin
				skip_beat <= 1;					
			end
			else skip_beat <= 0;
		end
		
		// CPU does one cycle
		if(CPU_cnt == 0) begin			
			CPUENA <= !skip_beat;			
		end			
		else
			CPUENA <= 0;
		
		// RAM is read or written	
		if(CPU_cnt == 1) begin
			sdram_rd <= 1; 
			sdram_addr <= cpuReadAddress;
			if(MREQ && WR && !skip_beat)	begin				
				if(mapped_io) begin											
					caps_lock_bit            <= DO[6];
					vdc_graphic_mode_enabled <= DO[3];
					CASOUT                   <= DO[2];					
					BUZZER                   <= DO[0];
				end
				else begin
					sdram_wr <= bank_is_ram;
					sdram_din <= DO;  						
				end		   
			end
		end

		// CPU samples bus, written is stopped	
		if(CPU_cnt == 2) begin
			if(MREQ && !skip_beat) begin
				if(RD) begin					
					if(mapped_io) begin											
						DI[7] <= CASIN;					
						DI[6:0] <= KD;						      
					end				
					else 
						DI <= sdram_dout; // read from RAM/ROM						
				end			
				if(WR)	begin
					// terminate write
					sdram_wr <= 0;  
				end					
			end
		end
				
		// Z80 IO 
		if(CPU_cnt == 2 && IORQ && !skip_beat) begin
			if(RD) begin				
				if(A[7:0] == 'h2b) begin
					// joystick0 8 directions: ---FEWSN					
					// Mist: 0-right, 1-left, 2-down, 3-up, 4-A, 5-B, 6-SELECT, 7-START, 8-X, 9-Y, 10-L, 11-R, 12-L2, 13-R2, 15-L3, 15-R
					DI[7] <= 1;					
					DI[6] <= 1;					
					DI[5] <= 1;					
					DI[4] <= ~joystick_0[4];					
					DI[3] <= ~joystick_0[0];
					DI[2] <= ~joystick_0[1];
					DI[1] <= ~joystick_0[2];
					DI[0] <= ~joystick_0[3];
				end
				else if(A[7:0] == 'h27) begin
					// joystick0 fire buttons      				
					DI[7] <= 1;					
					DI[6] <= 1;					
					DI[5] <= 1;					
					DI[4] <= ~joystick_0[5];					
					DI[3] <= 1;
					DI[2] <= 1;
					DI[1] <= 1;
					DI[0] <= 1;
				end
				else if(A[7:0] == 'h2e) begin
					// joystick1 8 directions
					DI[7] <= 1;					
					DI[6] <= 1;					
					DI[5] <= 1;					
					DI[4] <= ~joystick_1[4];					
					DI[3] <= ~joystick_1[0];
					DI[2] <= ~joystick_1[1];
					DI[1] <= ~joystick_1[2];
					DI[0] <= ~joystick_1[3];
				end
				else if(A[7:0] == 'h2d) begin
					// joystick1 fire buttons      				
					DI[7] <= 1;					
					DI[6] <= 1;					
					DI[5] <= 1;					
					DI[4] <= ~joystick_1[5];					
					DI[3] <= 1;
					DI[2] <= 1;
					DI[1] <= 1;
					DI[0] <= 1;
				end
				else if(A[7:0] == 'ha0) DI <= hsw;						
				else if(A[7:0] == 'ha1) DI <= hbp;						
				else if(A[7:0] == 'ha2) DI <= hfp;						
				else
					DI <= { DI[7:1], 1'b1 }; // value returned from unused ports
					
				//case 0x00: return printerReady;                  				
				//case 0x10:
				//case 0x11:
				//case 0x12:
				//case 0x13:
				//case 0x14:
				//	return emulate_fdc ? floppy_read_port(port & 0xFF) : 0xFF;  
			end
			if(WR) begin
				case(A[7:0])
					'h40: banks[0] <= DO[3:0];
					'h41: banks[1] <= DO[3:0];
					'h42: banks[2] <= DO[3:0];
					'h43: banks[3] <= DO[3:0];
					'h44:
						begin	
							vdc_page_7         <= ~DO[3];
							vdc_text80_enabled <= DO[0]; 
							vdc_border_color   <= DO[7:4];
							
							if(DO[2:1] == 'b00)  vdc_graphic_mode_number <= 5;              											
							if(DO[2:0] == 'b010) vdc_graphic_mode_number <= 4;
							if(DO[2:0] == 'b011) vdc_graphic_mode_number <= 3;
							if(DO[2:0] == 'b110) vdc_graphic_mode_number <= 2;
							if(DO[2:0] == 'b111) vdc_graphic_mode_number <= 1;
							if(DO[2:1] == 'b10)  vdc_graphic_mode_number <= 0;                  
						end
					'h45:
						begin
							vdc_text80_foreground <= DO[7:4];
							vdc_text80_background <= DO[3:0];         
						end
					'h0d: ;
						// printerWrite(value);
					'h0e: ;
						// printer port duplicated here							
					'h10: ;
					'h11: ;
					'h12: ;
					'h13: ;
					'h14: ;
					'ha0: hsw <= DO;						
					'ha1: hbp <= DO;						
					'ha2: hfp <= DO;						
					
						//if(emulate_fdc) floppy_write_port(port & 0xFF, value); 
						//return;     				
				endcase				
			end
		end										
	end
end 
					 									
	// ******************************************************************************						 					

	// bank switching
	wire        bank_is_ram   = A >= 'h8000;	
	wire [24:0] cpuReadAddress = { 9'd0, A };		
		
endmodule
*/

