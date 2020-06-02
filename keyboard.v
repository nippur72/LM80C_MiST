
module keyboard ( 
	input clk,
	input reset,

	// ps2 interface	
	input ps2_clk,
	input ps2_data,
	
	// VTL chip interface
   input      [ 7:0] port_A,   
	output     [ 7:0] port_B,   	
	
	output reset_key
	
);

reg resetkey;

wire [7:0] KA = port_A;
assign port_B = KD;				
assign reset_key = resetkey;

// keyboard output
assign KD = ((KA[ 0] == 0) ? KM[ 0] : 7'b1111111) & 
            ((KA[ 1] == 0) ? KM[ 1] : 7'b1111111) &
				((KA[ 2] == 0) ? KM[ 2] : 7'b1111111) &
				((KA[ 3] == 0) ? KM[ 3] : 7'b1111111) &
				((KA[ 4] == 0) ? KM[ 4] : 7'b1111111) &
				((KA[ 5] == 0) ? KM[ 5] : 7'b1111111) &
				((KA[ 6] == 0) ? KM[ 6] : 7'b1111111) &
				((KA[ 7] == 0) ? KM[ 7] : 7'b1111111) ;			
								
// keyboard matrix 8x8
reg [7:0] KM [7:0]; 

// PS/2 keyboard codes
parameter [15:0] KEY_PAUSE         = 'h77; 
parameter [15:0] KEY_ALT_LEFT      = 'h11; 
parameter [15:0] KEY_F1            = 'h05;
parameter [15:0] KEY_F2            = 'h06;
parameter [15:0] KEY_F3            = 'h04;
parameter [15:0] KEY_F4            = 'h0c;
parameter [15:0] KEY_F5            = 'h03;
parameter [15:0] KEY_F6            = 'h0b;
parameter [15:0] KEY_F7            = 'h83;
parameter [15:0] KEY_F8            = 'h0a;
parameter [15:0] KEY_F9            = 'h01;
parameter [15:0] KEY_F10           = 'h09;  
parameter [15:0] KEY_F11           = 'h78;  
parameter [15:0] KEY_F12           = 'h07;  
parameter [15:0] KEY_INS           = 'he070;
parameter [15:0] KEY_DEL           = 'he071;
parameter [15:0] KEY_ESC           = 'h76;
parameter [15:0] KEY_1             = 'h16;
parameter [15:0] KEY_2             = 'h1e;
parameter [15:0] KEY_3             = 'h26;
parameter [15:0] KEY_4             = 'h25;
parameter [15:0] KEY_5             = 'h2e;
parameter [15:0] KEY_6             = 'h36;
parameter [15:0] KEY_7             = 'h3d;
parameter [15:0] KEY_8             = 'h3e;
parameter [15:0] KEY_9             = 'h46;
parameter [15:0] KEY_0             = 'h45;
parameter [15:0] KEY_1_NUMPAD      = 'h69;
parameter [15:0] KEY_2_NUMPAD      = 'h72;
parameter [15:0] KEY_3_NUMPAD      = 'h7a;
parameter [15:0] KEY_4_NUMPAD      = 'h6b;
parameter [15:0] KEY_5_NUMPAD      = 'h73;
parameter [15:0] KEY_6_NUMPAD      = 'h74;
parameter [15:0] KEY_7_NUMPAD      = 'h6c;
parameter [15:0] KEY_8_NUMPAD      = 'h75;
parameter [15:0] KEY_9_NUMPAD      = 'h7d;
parameter [15:0] KEY_0_NUMPAD      = 'h70;
parameter [15:0] KEY_MINUS         = 'h4e;
parameter [15:0] KEY_EQUAL         = 'h55;
parameter [15:0] KEY_BACKSLASH     = 'h0e;
parameter [15:0] KEY_BS            = 'h66;
parameter [15:0] KEY_DEL_LINE      = 'he069;
parameter [15:0] KEY_CLS_HOME      = 'he06c;
parameter [15:0] KEY_TAB           = 'h0d;
parameter [15:0] KEY_Q             = 'h15;
parameter [15:0] KEY_W             = 'h1d;
parameter [15:0] KEY_E             = 'h24;
parameter [15:0] KEY_R             = 'h2d;
parameter [15:0] KEY_T             = 'h2c;
parameter [15:0] KEY_Y             = 'h35;
parameter [15:0] KEY_U             = 'h3c;
parameter [15:0] KEY_I             = 'h43;
parameter [15:0] KEY_O             = 'h44;
parameter [15:0] KEY_P             = 'h4d;
parameter [15:0] KEY_OPEN_BRACKET  = 'h54;
parameter [15:0] KEY_CLOSE_BRACKET = 'h5b;
parameter [15:0] KEY_RETURN        = 'h5a;
parameter [15:0] KEY_CONTROL       = 'h14;  
parameter [15:0] KEY_CONTROL_RIGHT = 'he014; 
parameter [15:0] KEY_A             = 'h1c;
parameter [15:0] KEY_S             = 'h1b;
parameter [15:0] KEY_D             = 'h23;
parameter [15:0] KEY_F             = 'h2b;
parameter [15:0] KEY_G             = 'h34;
parameter [15:0] KEY_H             = 'h33;
parameter [15:0] KEY_J             = 'h3b;
parameter [15:0] KEY_K             = 'h42;
parameter [15:0] KEY_L             = 'h4b;
parameter [15:0] KEY_SEMICOLON     = 'h4c;
parameter [15:0] KEY_QUOTE         = 'h52;
parameter [15:0] KEY_BACK_QUOTE    = 'h5d;
parameter [15:0] KEY_GRAPH         = 'he07a;
parameter [15:0] KEY_UP            = 'he075;
parameter [15:0] KEY_SHIFT         = 'h12;  
parameter [15:0] KEY_SHIFT_RIGHT   = 'h59;  
parameter [15:0] KEY_Z             = 'h1a;
parameter [15:0] KEY_X             = 'h22;
parameter [15:0] KEY_C             = 'h21;
parameter [15:0] KEY_V             = 'h2a;
parameter [15:0] KEY_B             = 'h32;
parameter [15:0] KEY_N             = 'h31;
parameter [15:0] KEY_M             = 'h3a;
parameter [15:0] KEY_COMMA         = 'h41;
parameter [15:0] KEY_DOT           = 'h49;
parameter [15:0] KEY_SLASH         = 'h4a;
parameter [15:0] KEY_MU            = 'he07d;   
parameter [15:0] KEY_LEFT          = 'he06b;
parameter [15:0] KEY_RIGHT         = 'he074;
parameter [15:0] KEY_CAP_LOCK      = 'h58;
parameter [15:0] KEY_SPACE         = 'h29;
parameter [15:0] KEY_DOWN          = 'he072;

parameter [15:0] KEY_RETURN_NUMPAD = 'he05a;
parameter [15:0] KEY_MINUS_NUMPAD  = 'h7b;
parameter [15:0] KEY_PLUS_NUMPAD   = 'h79;
parameter [15:0] KEY_MULT_NUMPAD   = 'h7c;
parameter [15:0] KEY_SLASH_NUMPAD  = 'he04a;
parameter [15:0] KEY_DOT_NUMPAD    = 'h71;

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
		KM[ 0] <= 7'b1111111;
		KM[ 1] <= 7'b1111111;
		KM[ 2] <= 7'b1111111;
		KM[ 3] <= 7'b1111111;
		KM[ 4] <= 7'b1111111;
		KM[ 5] <= 7'b1111111;
		KM[ 6] <= 7'b1111111;
		KM[ 7] <= 7'b1111111;			
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
					KEY_Z         : begin resetkey <= key_status; end 
					KEY_C         : begin KM[2][4] <= key_status; end    // KEY_C         
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

				/*
					KEY_F7        : begin KM[7][7] <= key_status; end    // KEY_HELP      
					KEY_F3        : begin KM[7][6] <= key_status; end    // KEY_F3        
					KEY_F2        : begin KM[7][5] <= key_status; end    // KEY_F2        
					KEY_F1        : begin KM[7][4] <= key_status; end    // KEY_F1        
					KEY_AT        : begin KM[7][3] <= key_status; end    // KEY_AT        
					KEY_POUND     : begin KM[7][2] <= key_status; end    // KEY_POUND     
					KEY_RETURN    : begin KM[7][1] <= key_status; end    // KEY_RETURN    
					KEY_INST_DEL  : begin KM[7][0] <= key_status; end    // KEY_INST_DEL  
					KEY_RIGHT     : begin KM[6][7] <= key_status; end    // KEY_RIGHT     
					KEY_PLUS      : begin KM[6][6] <= key_status; end    // KEY_PLUS      
					KEY_EQUAL     : begin KM[6][5] <= key_status; end    // KEY_EQUAL     
					KEY_ESC       : begin KM[6][4] <= key_status; end    // KEY_ESC       
					KEY_SLASH     : begin KM[6][3] <= key_status; end    // KEY_SLASH     
					KEY_SEMICOLON : begin KM[6][2] <= key_status; end    // KEY_SEMICOLON 
					KEY_ASTERISK  : begin KM[6][1] <= key_status; end    // KEY_ASTERISK  
					KEY_LEFT      : begin KM[6][0] <= key_status; end    // KEY_LEFT      
					KEY_UP        : begin KM[5][7] <= key_status; end    // KEY_UP        
					KEY_MINUS     : begin KM[5][6] <= key_status; end    // KEY_MINUS     
					KEY_COLON     : begin KM[5][5] <= key_status; end    // KEY_COLON     
					KEY_DOT       : begin KM[5][4] <= key_status; end    // KEY_DOT       
					KEY_COMMA     : begin KM[5][3] <= key_status; end    // KEY_COMMA     
					KEY_L         : begin KM[5][2] <= key_status; end    // KEY_L         
					KEY_P         : begin KM[5][1] <= key_status; end    // KEY_P         
					KEY_DOWN      : begin KM[5][0] <= key_status; end    // KEY_DOWN      
					KEY_0         : begin KM[4][7] <= key_status; end    // KEY_0         
					KEY_O         : begin KM[4][6] <= key_status; end    // KEY_O         
					KEY_K         : begin KM[4][5] <= key_status; end    // KEY_K         
					KEY_M         : begin KM[4][4] <= key_status; end    // KEY_M         
					KEY_N         : begin KM[4][3] <= key_status; end    // KEY_N         
					KEY_J         : begin KM[4][2] <= key_status; end    // KEY_J         
					KEY_I         : begin KM[4][1] <= key_status; end    // KEY_I         
					KEY_9         : begin KM[4][0] <= key_status; end    // KEY_9         
					KEY_8         : begin KM[3][7] <= key_status; end    // KEY_8         
					KEY_U         : begin KM[3][6] <= key_status; end    // KEY_U         
					KEY_H         : begin KM[3][5] <= key_status; end    // KEY_H         
					KEY_B         : begin KM[3][4] <= key_status; end    // KEY_B         
					KEY_V         : begin KM[3][3] <= key_status; end    // KEY_V         
					KEY_G         : begin KM[3][2] <= key_status; end    // KEY_G         
					KEY_Y         : begin KM[3][1] <= key_status; end    // KEY_Y         
					KEY_7         : begin KM[3][0] <= key_status; end    // KEY_7         
					KEY_6         : begin KM[2][7] <= key_status; end    // KEY_6         
					KEY_T         : begin KM[2][6] <= key_status; end    // KEY_T         
					KEY_F         : begin KM[2][5] <= key_status; end    // KEY_F         
				*/
				/*	
					KEY_X         : begin KM[2][3] <= key_status; end    // KEY_X         
					KEY_D         : begin KM[2][2] <= key_status; end    // KEY_D         
					KEY_R         : begin KM[2][1] <= key_status; end    // KEY_R         
					KEY_5         : begin KM[2][0] <= key_status; end    // KEY_5         
					KEY_4         : begin KM[1][7] <= key_status; end    // KEY_4         
					KEY_E         : begin KM[1][6] <= key_status; end    // KEY_E         
					KEY_S         : begin KM[1][5] <= key_status; end    // KEY_S         
					KEY_Z         : begin KM[1][4] <= key_status; end    // KEY_Z         
					KEY_SHIFT     : begin KM[1][3] <= key_status; end    // KEY_SHIFT     
					KEY_A         : begin KM[1][2] <= key_status; end    // KEY_A         
					KEY_W         : begin KM[1][1] <= key_status; end    // KEY_W         
					KEY_3         : begin KM[1][0] <= key_status; end    // KEY_3         
					KEY_2         : begin KM[0][7] <= key_status; end    // KEY_2         
					KEY_Q         : begin KM[0][6] <= key_status; end    // KEY_Q         
					KEY_CBM       : begin KM[0][5] <= key_status; end    // KEY_CBM       
					KEY_SPACE     : begin KM[0][4] <= key_status; end    // KEY_SPACE     
					KEY_RUN_STOP  : begin KM[0][3] <= key_status; end    // KEY_RUN_STOP  
					KEY_CTRL      : begin KM[0][2] <= key_status; end    // KEY_CTRL      
					KEY_CLR_HOME  : begin KM[0][1] <= key_status; end    // KEY_CLR_HOME  
					KEY_1         : begin KM[0][0] <= key_status; end    // KEY_1         
				*/
