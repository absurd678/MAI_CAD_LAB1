`timescale 1ns/1ps
`include "apb_agent.sv"
`include "apb_interface.sv"
`include "slave.sv"

module tb_apb;

  // Clock/reset
  logic clk;
  logic resetn;

  // APB interface
  apb_interface apb_if();
  slave dut (
      .apb_if   (apb_if)
  );

  // Agent
  apb_agent agent;
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    resetn = 0;
    #20;
    resetn = 1;
  end

  // Connect interface clock/reset
  assign apb_if.PCLK   = clk;
  assign apb_if.PRESETn = resetn;

task automatic do_reset();
    resetn = 0;
    #20;
    resetn = 1;
endtask

task automatic do_add(input logic signed [31:0] a, b);
  logic [31:0] read_data;		// для проверки прочитанных данных
  agent.write(8'h00, a);// операнд 1
  agent.write(8'h01, b);//, операнд 2
  agent.write(8'h04, 0);//, операция
  #5;
  agent.read(8'h02, read_data);// результат
  #5;
  $display("Result == %d", read_data);		
  agent.read(8'h03, read_data); // переполнение?
  #5;
  $display("Is overflow == %d", read_data);
endtask

task automatic do_sub(input logic signed [31:0] a, b);
  logic [31:0] read_data;		// для проверки прочитанных данных
  agent.write(8'h00, a);// операнд 1
  agent.write(8'h01, b);//, операнд 2
  agent.write(8'h04, 1);//, операция
  #5;
  agent.read(8'h02, read_data);// результат
  #5;
  $display("Result == %d", read_data);		
  agent.read(8'h03, read_data); // переполнение?
  #5;
  $display("Is overflow == %d", read_data);
endtask

task automatic do_bad_addr();
  bit [7:0] bad_addr = 8'h22;
  logic [31:0] read_data;		// для проверки прочитанных данных
  agent.write(bad_addr, 32'hDEAD_BEEF);// операнд 1
  #5;
  agent.read(8'h02, read_data);// должна быть ошибка
  #5;
  $display("Result == %d", read_data);
endtask

task automatic do_bad_oper(input logic signed [31:0] a, b);
  logic [31:0] read_data;		// для проверки прочитанных данных
  agent.write(8'h00, a);// операнд 1
  agent.write(8'h01, b);//, операнд 2
  agent.write(8'h04, 32'hDEAD_BEEF);//, операция
  agent.read(8'h02, read_data);// результат
  #5;
  $display("Result == %d", read_data);		
  agent.read(8'h03, read_data); // переполнение?
  $display("Is overflow == %d", read_data);
endtask


  //////////////
  // Main stimulus
  //////////////
  initial begin
    // Объявления всех переменных в начале блока
    bit [31:0] rtmp;
    
    bit [31:0] a, b;
    bit [31:0] dummy;
    bit op_rand;
    logic [63:0] c;

    // Инициализация agent после создания интерфейса
    agent = new(apb_if.master_mp);

    // Wait for reset deassert
    wait (resetn);
    @(posedge apb_if.PCLK);

    // 1+2
    a = 32'd1;
    b = 32'd2;
    do_add(a, b);

    // 	overflow on add
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    a = 32'h7FFF_FFFF;
    b = 32'd1;
    do_add(a, b);

    // 5-3
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    a = 32'd5;
    b = 32'd3;
    do_sub(a, b);

    // 0 - 1 (borrow)
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    a = 0;
    b = 1;
    do_sub(a, b);

    // Illegal address access to trigger PSLVERR / invalid addr bin
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    do_bad_addr();
    // Illegal oper
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    do_bad_oper(a,b);
    
    // Randomized stress (toggle coverage across data bus bits)
    repeat (64) begin
      a = $urandom();
      b = $urandom();
      op_rand = ($urandom_range(0,1));
      case (op_rand)
        0: do_add(a, b);
        default: do_sub(a, b);
	  endcase
      
    end

    // Back-to-back transfers without idle to hit timing branches
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    agent.write(8'h00, 32'hAAAA_AAAA);
    agent.write(8'h01, 32'h5555_5555);
    agent.write(8'h04, 0); // +
    agent.read (8'h02, dummy);

    // no oper1
    // Back-to-back transfers without idle to hit timing branches
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    agent.write(8'h01, 32'h5555_5555);
    agent.write(8'h04, 0); // +
    agent.read (8'h02, dummy);

    #10;
    // no oper2
    // Back-to-back transfers without idle to hit timing branches
    do_reset();
    wait (resetn);
    @(posedge apb_if.PCLK);
    agent.write(8'h00, 32'hAAAA_AAAA);
    agent.write(8'h04, 0); // +
    agent.read (8'h02, dummy);

    $display("[TB] Finished.");
    #20;
    $finish;
  end

endmodule