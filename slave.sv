
`timescale 1ns/1ps

module slave (
    apb_interface apb_if
);

localparam MEM_ADDR_END   = 32'h1F;
localparam WORD_LEN = 32;

//------------------------Память DUT---------------------------
// [8'h00] — I операнд (reg_addr).
// [8'h01] — II операнд (reg_cmd).
// [8'h02] — Результат (reg_wdata).
// [8'h03] — Контрольный регистр (reg_rdata).
// [8'h04] — Код операции (0 - сумма 1 - вычитание).
localparam ADDR_OP1   = 8'h00;
localparam ADDR_OP2 = 8'h01;
localparam ADDR_RES = 8'h02;
localparam ADDR_CY = 8'h03;
localparam ADDR_OPER = 8'h04;

logic signed [WORD_LEN-1:0] register_file [0:MEM_ADDR_END];	// ОЗУ
logic signed [31:0] op1;
logic signed [31:0] op2;
logic signed [31:0] res;
logic allow_operation = 0;
logic [31:0] max_unsigned = 32'hFFFFFFFF; // Максимальное число для проверки ввода

function logic check_overflow_unsigned_add(input logic [31:0] a, b); // Переполнение при сложении беззнаковых
    return (a + b) < a;
endfunction

function automatic logic check_overflow_signed_add(input logic signed [31:0] a, b);// Переполнение при сложении знаковых
    logic signed [31:0] sum = a + b;
    return (a[31] == b[31]) && (sum[31] != a[31]);
endfunction

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

    // function check_registers
        
    if(register_file[ADDR_OP1] > max_unsigned) begin //  Проверить что числа вмещаются в регистр
        $display("OP1 is too big!");
        allow_operation <= 0; 
    end
    else if (register_file[ADDR_OP2] > max_unsigned) begin
        $display("OP2 is too big!");
        allow_operation <= 0; 
    end
    else if (register_file[ADDR_OPER] != 1'b0 && register_file[ADDR_OPER] != 1'b1) begin
        $display("INCORRECT OPER CODE - {0, 1} MUST BE!");
        allow_operation <= 0; 
    end
    else begin
        allow_operation <= 1;
        op1 <= register_file[ADDR_OP1];
        op2 <= register_file[ADDR_OP2];
    end

    // function do_operation
    if (allow_operation == 1'b1) begin
        if (check_overflow_unsigned_add(op1, op2) == 1 ||
          check_overflow_signed_add(op1, op2) == 1) begin    // Проверка переноса
            register_file[ADDR_CY] <= 1'b1; 
        end
        $display("[SLAVE]: ADDING IS RUNNING");
        register_file[ADDR_RES] <= op1 + op2;
        allow_operation <= 1'b0;
        
    end
    $display("[SLAVE]: RESULT = %d", register_file[ADDR_RES]);
end

endmodule
