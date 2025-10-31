`timescale 1ns/1ps
`include "apb_interface.sv"
`include "apb_agent.sv"
`include "slave.sv"

module tb_apb;
// Clock и reset
logic clk;
logic resetn;
logic signed [31:0] read_data;
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
	agent_if.write(8'h00, 1);// Настраиваем адрес назначения
	#5;
	agent_if.write(8'h01, -2);//, Настраиваем команду записи
	#5;
	agent_if.write(8'h04, 0);//, Указываем число на запись
	#20;
	agent_if.read(8'h02, read_data);//, Отправляем начало транзакции
	#20;		
	$display("Result == %d", read_data);

    $finish;
  end

endmodule
