// simple MiST PS2 keyboard interface

module mist_keyboard ( 
	input clk,
	input reset,

	// ps2 interface	
	input ps2_clk,
	input ps2_data,	
	
	output        valid,
	output [15:0] key,
	output        status
);

wire [7:0] kdata;  // keyboard data byte, 0xE0 = extended key, 0xF0 release key
wire error;        // not used here

reg key_extended;
reg key_status;

assign key = { (key_extended ? 8'he0 : 8'h00) , kdata };
assign status = key_status;

always @(posedge clk or posedge reset) begin
	if(reset) begin		
      key_status <= 1'b0;
      key_extended <= 1'b0;
	end 
	else begin					
		// ps2 decoder has received a valid byte
		if(valid) begin
			if(kdata == 8'he0) 
				// extended key code
            key_extended <= 1'b1;
         else if(kdata == 8'hf0)
				// release code
            key_status <= 1'b0;
         else begin
			   // key press
				key_extended <= 1'b0;
				key_status   <= 1'b1;				
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
