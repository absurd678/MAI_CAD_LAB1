
`timescale 1ns/1ps

module slave (
    apb_interface apb_if
);

  localparam MEM_ADDR_END   = 32'h1F;
  localparam WORD_LEN = 32;

  //------------------------Память DUT---------------------------
  logic [WORD_LEN:0] register_file [0:MEM_ADDR_END];	// ОЗУ
  

     //----------------интерфейс с APB (master)-----------------------------
    always @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
        if (!apb_if.PRESETn) begin
            apb_if.PREADY <= 1'b0;
            apb_if.PSLVERR <= 1'b0;
				
			for (int i = 0; i <= MEM_ADDR_END; i++) begin
			  register_file[i] <= '0;
			end
    
        end
		  
	    apb_if.PSLVERR <= 1'b0; 
 
            if (apb_if.PSEL && apb_if.PENABLE && apb_if.PWRITE) begin
		apb_if.PREADY <= 1'b1;
                register_file[apb_if.PADDR] <= apb_if.PWDATA;
		$display("[SLAVE] WRITE ; DATA: %32d", apb_if.PWDATA);
            end
            
            else if (apb_if.PSEL && apb_if.PENABLE && !apb_if.PWRITE) begin
		apb_if.PREADY <= 1'b1;
                apb_if.PRDATA <= register_file[apb_if.PADDR];
		$display("[SLAVE] READ ; DATA: %32d", register_file[apb_if.PADDR]);
            end
	if (!apb_if.PSEL) apb_if.PREADY <= 1'b0;
 
    end

endmodule
