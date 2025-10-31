
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

// Регистры
logic signed [31:0] op1;
logic signed [31:0] op2;
logic signed [31:0] res;
logic allow_operation = 0;
// Флаги свежей записи операндов и кода операции
logic op1_valid = 1'b0;
logic op2_valid = 1'b0;
logic oper_valid = 1'b0;
logic signed [31:0] max_signed = 32'sh7FFFFFFF; // Максимальное число для проверки ввода

// -------------- ФУНКЦИИ -------------- 
// Проверки переполнения для 32-битных знаковых операций
function automatic logic ovf_add_s32(input logic signed [31:0] a, b);
    logic signed [31:0] s = a + b;
    return (a[31] == b[31]) && (s[31] != a[31]);
endfunction

function automatic logic ovf_sub_s32(input logic signed [31:0] a, b);
    logic signed [31:0] d = a - b;
    return (a[31] != b[31]) && (d[31] != a[31]);
endfunction

function logic check_operands_and_operation();

    if(register_file[ADDR_OP1] > max_signed) begin //  Проверить что числа вмещаются в регистр
        $display("OP1 is too big!");
        return 0; 
    end
    else if (register_file[ADDR_OP2] > max_signed) begin
        $display("OP2 is too big!");
        return 0; 
    end
    else if (register_file[ADDR_OPER] != 1'b0 && register_file[ADDR_OPER] != 1'b1) begin
        $display("INCORRECT OPER CODE - {0, 1} MUST BE!");
        return 0; 
    end
    else begin
        return 1;
    end
    return 0;
endfunction

function automatic logic signed [31:0] do_add(input logic signed [31:0] a, b);
    if (ovf_add_s32(a, b)) begin    // Проверка переполнения
        register_file[ADDR_CY] <= 1'b1; 
    end
    $display("[SLAVE]: ADDING IS RUNNING");
    return a + b;
endfunction

function automatic logic signed [31:0] do_sub(input logic signed [31:0] a, b);
    if (ovf_sub_s32(a, b)) begin    // Проверка переполнения
        register_file[ADDR_CY] <= 1'b1; 
    end
    $display("[SLAVE]: SUBSTRACTION IS RUNNING");
    return a - b;
endfunction

    //----------------интерфейс с APB (master)-----------------------------
always @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
    if (!apb_if.PRESETn) begin
        apb_if.PREADY <= 1'b0;
        apb_if.PSLVERR <= 1'b0;
        allow_operation <= 1'b0;
        op1_valid <= 1'b0;
        op2_valid <= 1'b0;
        oper_valid <= 1'b0;
            
        for (int i = 0; i <= MEM_ADDR_END; i++) begin
            register_file[i] <= '0;
        end

    end
        
    apb_if.PSLVERR <= 1'b0; 

    if (apb_if.PSEL && apb_if.PENABLE && apb_if.PWRITE) begin
        apb_if.PREADY <= 1'b1;
        register_file[apb_if.PADDR] <= apb_if.PWDATA;
        $display("[SLAVE] WRITE ; ADDR:%0h DATA:%0d", apb_if.PADDR, apb_if.PWDATA);

        // Отслеживаем свежие записи входов
        unique case (apb_if.PADDR[7:0])
            ADDR_OP1: op1_valid <= 1'b1;
            ADDR_OP2: op2_valid <= 1'b1;
            ADDR_OPER: oper_valid <= 1'b1;
            default: ;
        endcase
    end
        
    else if (apb_if.PSEL && apb_if.PENABLE && !apb_if.PWRITE) begin
        apb_if.PREADY <= 1'b1;
        apb_if.PRDATA <= register_file[apb_if.PADDR];
        $display("[SLAVE] READ ; DATA: %32d", register_file[apb_if.PADDR]);
    end

    if (!apb_if.PSEL) apb_if.PREADY <= 1'b0;

    // Запуск операции, только когда все входы были записаны с момента последнего выполнения
    if (op1_valid && op2_valid && oper_valid && (check_operands_and_operation() == 1)) begin
        allow_operation <= 1'b1;
        op1 <= register_file[ADDR_OP1];
        op2 <= register_file[ADDR_OP2];
    end else begin
        // не вооружаем операцию, если входы не готовы
        if (!(op1_valid && op2_valid && oper_valid)) begin
            allow_operation <= 1'b0;
        end
    end 

    if (allow_operation == 1'b1 && register_file[ADDR_OPER] == 0) begin
        register_file[ADDR_CY] <= 1'b0;
        register_file[ADDR_RES] <= do_add(op1, op2);
        //register_file[ADDR_RES] <= op1 + op2;
        allow_operation <= 1'b0;
        // ожидать новые операнды и код операции
        op1_valid <= 1'b0;
        op2_valid <= 1'b0;
        oper_valid <= 1'b0;
    end
    else if (allow_operation == 1'b1 && register_file[ADDR_OPER] == 1) begin 
        register_file[ADDR_CY] <= 1'b0;
        register_file[ADDR_RES] <= do_sub(op1, op2);
        //register_file[ADDR_RES] <= op1 - op2;
        allow_operation <= 1'b0;
        // ожидать новые операнды и код операции
        op1_valid <= 1'b0;
        op2_valid <= 1'b0;
        oper_valid <= 1'b0;
    end
end

endmodule
