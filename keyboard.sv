
module keyboard ( 
	input clk,
	input reset,

	// ps2 interface	
	input ps2_clk,
	input ps2_data,	
		
	// lm80c interface
	output reg [7:0] KM [7:0],       // the 8x8 keyboard matrix (low active)
	output reg resetkey	            // 1=hardware reset key pressed
);


`include "ps2keys.v"

wire [7:0] kdata;  // keyboard data byte, 0xE0 = extended key, 0xF0 release key
wire valid;        // 1 = data byte contains valid keyboard data 
wire error;        // not used here

reg key_status;
reg key_extended;

wire [15:0] key = { (key_extended ? 8'he0 : 8'h00) , kdata };


always @(posedge clk) begin
	if(reset) begin		
      key_status <= 1'b1;
      key_extended <= 1'b0;
		KM[0] <= 8'b11111111;
		KM[1] <= 8'b11111111;
		KM[2] <= 8'b11111111;
		KM[3] <= 8'b11111111;
		KM[4] <= 8'b11111111;
		KM[5] <= 8'b11111111;
		KM[6] <= 8'b11111111;
		KM[7] <= 8'b11111111;			
	end 
	else begin		
			
		// ps2 decoder has received a valid byte
		if(valid) begin
			if(kdata == 8'he0) 
				// extended key code
            key_extended <= 1'b1;
         else if(kdata == 8'hf0)
				// release code
            key_status <= 1'b1;
         else begin
			   // key press
				key_extended <= 1'b0;
				key_status   <= 1'b0;
				
				case(key)	
					PS2_KEY_F11         : begin resetkey <= ~key_status; end 
				   PS2_KEY_SHIFT_RIGHT : begin KM[1][3] <= key_status; end										
					
					KEY_HELP      : begin KM[7][7] <= key_status; end
					KEY_F3        : begin KM[7][6] <= key_status; end
					KEY_F2        : begin KM[7][5] <= key_status; end
					KEY_F1        : begin KM[7][4] <= key_status; end
					KEY_AT        : begin KM[7][3] <= key_status; end
					KEY_POUND     : begin KM[7][2] <= key_status; end
					KEY_RETURN    : begin KM[7][1] <= key_status; end
					KEY_INST_DEL  : begin KM[7][0] <= key_status; end
					KEY_RIGHT     : begin KM[6][7] <= key_status; end
					KEY_PLUS      : begin KM[6][6] <= key_status; end
					KEY_EQUAL     : begin KM[6][5] <= key_status; end
					KEY_ESC       : begin KM[6][4] <= key_status; end
					KEY_SLASH     : begin KM[6][3] <= key_status; end
					KEY_SEMICOLON : begin KM[6][2] <= key_status; end
					KEY_ASTERISK  : begin KM[6][1] <= key_status; end
					KEY_LEFT      : begin KM[6][0] <= key_status; end
					KEY_UP        : begin KM[5][7] <= key_status; end
					KEY_MINUS     : begin KM[5][6] <= key_status; end
					KEY_COLON     : begin KM[5][5] <= key_status; end
					KEY_DOT       : begin KM[5][4] <= key_status; end
					KEY_COMMA     : begin KM[5][3] <= key_status; end
					KEY_L         : begin KM[5][2] <= key_status; end
					KEY_P         : begin KM[5][1] <= key_status; end
					KEY_DOWN      : begin KM[5][0] <= key_status; end
					KEY_0         : begin KM[4][7] <= key_status; end
					KEY_O         : begin KM[4][6] <= key_status; end
					KEY_K         : begin KM[4][5] <= key_status; end
					KEY_M         : begin KM[4][4] <= key_status; end
					KEY_N         : begin KM[4][3] <= key_status; end
					KEY_J         : begin KM[4][2] <= key_status; end
					KEY_I         : begin KM[4][1] <= key_status; end
					KEY_9         : begin KM[4][0] <= key_status; end
					KEY_8         : begin KM[3][7] <= key_status; end
					KEY_U         : begin KM[3][6] <= key_status; end
					KEY_H         : begin KM[3][5] <= key_status; end
					KEY_B         : begin KM[3][4] <= key_status; end
					KEY_V         : begin KM[3][3] <= key_status; end
					KEY_G         : begin KM[3][2] <= key_status; end
					KEY_Y         : begin KM[3][1] <= key_status; end
					KEY_7         : begin KM[3][0] <= key_status; end
					KEY_6         : begin KM[2][7] <= key_status; end
					KEY_T         : begin KM[2][6] <= key_status; end
					KEY_F         : begin KM[2][5] <= key_status; end
					KEY_C         : begin KM[2][4] <= key_status; end
					KEY_X         : begin KM[2][3] <= key_status; end
					KEY_D         : begin KM[2][2] <= key_status; end
					KEY_R         : begin KM[2][1] <= key_status; end
					KEY_5         : begin KM[2][0] <= key_status; end
					KEY_4         : begin KM[1][7] <= key_status; end
					KEY_E         : begin KM[1][6] <= key_status; end
					KEY_S         : begin KM[1][5] <= key_status; end
					KEY_Z         : begin KM[1][4] <= key_status; end
					KEY_SHIFT     : begin KM[1][3] <= key_status; end					
					KEY_A         : begin KM[1][2] <= key_status; end
					KEY_W         : begin KM[1][1] <= key_status; end
					KEY_3         : begin KM[1][0] <= key_status; end
					KEY_2         : begin KM[0][7] <= key_status; end
					KEY_Q         : begin KM[0][6] <= key_status; end
					KEY_CBM       : begin KM[0][5] <= key_status; end
					KEY_SPACE     : begin KM[0][4] <= key_status; end
					KEY_RUN_STOP  : begin KM[0][3] <= key_status; end
					KEY_CTRL      : begin KM[0][2] <= key_status; end
					KEY_CLR_HOME  : begin KM[0][1] <= key_status; end
					KEY_1         : begin KM[0][0] <= key_status; end
					
				endcase
			end
		end		
	end
end

// the ps2 decoder has been taken from the zx spectrum core
ps2_intf ps2_keyboard (
	.CLK		 ( clk       ),
	.nRESET	 ( !reset    ),
	
	// PS/2 interface
	.PS2_CLK  ( ps2_clk   ),
	.PS2_DATA ( ps2_data  ),
	
	// Byte-wide data interface - only valid for one clock
	// so must be latched externally if required
	.DATA		  ( kdata  ),
	.VALID	  ( valid  ),
	.ERROR	  ( error  )
);

endmodule
