`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2025 04:32:12 PM
// Design Name: 
// Module Name: test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test(
    input logic             clk,
    input logic             reset,
    input logic             start,
    input logic [7:0]       message_in, // up to 256 bytes
    input logic [15:0]       message_len, // 1 byte
    output logic [255:0]    sha256_digest //256 bits Hash at the end of the process
    );  
    //Inicialización de variables internas
    logic           done;
    logic           padding_done;
    logic           next_step;
    logic           valid_in;
    logic           valid_out;
    logic           msg_complete;
    logic           Expand_ready;
    logic           padding_start;
    logic           Process_done;
    logic           block_ready;
    logic [3:0]     last_block_size; // Tamaño del último message_in
    logic [511:0]   padded_message;
    logic [63:0]    W [0:63] = '{default: 64'd0};
    logic [511:0]   block_padding;
    logic [2:0]     block_count; //Me permitirá contar la cantidad de bloques de 512 bits hay despues del padding
    logic [255:0]   out; // sha256 is always 32 bytes
    logic [511:0]   buffer;
    logic [511:0]   block_1;
    logic [511:0]   block_2;
    logic [511:0]   block_3;
    logic [10:0]    bit_count; // Contador de bits en el buffer
    logic [6:0]     count;
    integer         i;
    integer         t;
    logic [3:0]     num_blocks;
    logic           before_start;
    logic           block_ready_next; // Señal intermedia para retrasar la asignación
    logic [7:0]     last_byte;
    logic           sum;
//    logic           store_last;
//    logic message_valid;  // Señal para detectar cuando un nuevo dato llega
//    logic [7:0] message_reg; // Registro de sincronización para almacenar el dato
    
    
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        buffer       <= 512'b0;
        block_1      <= 512'b0;
        block_2      <= 512'b0;
        block_3      <= 512'b0;
        bit_count    <= 0;
        block_ready  <= 0;
        num_blocks   <= 1;
        before_start <= 1;
        valid_in     <= 0;
        msg_complete <= 0;
        block_ready_next <= 0;
        sum <= 1;
    end
    // Cálculo de la cantidad de bloques que se utilizarán
    else if (before_start) begin
        if (message_len <= 447) begin
            num_blocks <= 1;
        end
        else if (message_len >= 448 && message_len < 959) begin
            num_blocks <= 2;
        end
        else if (message_len >= 959 && message_len < 1471) begin
            num_blocks <= 3;
        end
        valid_in <= 1;
        before_start <= 0;
    end
    // Recepción del mensaje
    else if (valid_in) begin
        buffer <= {buffer[503:0], message_in}; // Shift de 8 bits y agregar nuevo dato
        bit_count <= bit_count + 8;
        // Verificar si se completa un bloque
        if (bit_count + 8 == 512 || bit_count + 8 == 1024 || bit_count + 8 == 1536 || bit_count + 8 == message_len) begin
            block_ready_next <= 1;
            valid_in <= 0;  // Detener la recepción momentáneamente
            sum <= 0;
        end
    end
    // Transferir el buffer a un bloque y resetear buffer
    else if (block_ready_next) begin
        if (bit_count <= 512 && !sum) begin
            block_1 <= buffer;
            last_byte <= message_in;
            bit_count <= bit_count - 8;
            sum <= 1;
        end
        else if (bit_count > 512 && bit_count <= 1024 && !sum) begin
            block_2 <= buffer;
            last_byte <= message_in;
            bit_count <= bit_count - 8;
            sum <= 1;
        end
        else if (bit_count > 1024 && bit_count <= 1536) begin
            block_3 <= buffer;
        end
        block_ready <= 1;  // Indicar que hay un bloque listo
        buffer <= 512'b0;  // Limpiar buffer
        block_ready_next <= 0; // Resetear señal de bloque listo
        valid_in <= (bit_count < message_len); // Reanudar recepción si quedan datos
    end
end
 
 ne
endmodule
