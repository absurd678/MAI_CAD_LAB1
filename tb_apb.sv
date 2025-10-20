`timescale 1ns/1ps
`include "apb_interface.sv"
`include "apb_agent.sv"
`include "slave.sv"

module tb_apb;
// Clock и reset
logic clk;
logic resetn;

// Объявляем интерфейсы
apb_interface apb_if();

slave dut (
    .apb_if   (apb_if)
);

// агенты-слейвы
apb_agent agent_if;
  

// Тактовый сигнал APB
initial begin
clk = 0;
forever #5 clk = ~clk;
end
  
assign apb_if.PCLK = clk;
assign apb_if.PRESETn = resetn;

  initial begin
	logic [31:0] read_data;		// для проверки прочитанных данных


	resetn = 0;
	#50;
	resetn = 1;

    // Создаем агент и запускаем его трансакционный FSM
    agent_if = new(apb_if.master_mp);
      
  

    // ===== Тест 1: запись и чтение EXT через APB =====
    $display("\n==== APB write/read test ====");
	// Сначала запись
	agent_if.write(32'h00, 32'd6);// Настраиваем адрес назначения
	#5;
	agent_if.write(32'h04, 32'd20102025);//, Настраиваем команду записи
	#5;
	agent_if.write(32'h08, 32'd75799072);//, Указываем число на запись
	#5;
	agent_if.write(32'h0C, 32'd65828469);//, Отправляем начало транзакции
	#100;		

    $finish;
  end

endmodule
