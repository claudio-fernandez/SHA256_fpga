//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2025 02:58:23 PM
// Design Name: 
// Module Name: sha256_digest_tb
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
`timescale 1ns / 1ps

module sha256_testbench;
    // Importamos el paquete sha256_pkg
    import sha256_pkg::*;
    // Señales de prueba
    logic clk;
    logic reset;
    logic start;
    logic [7:0] message_in;
    logic [7:0] message_len;
    logic [255:0] sha256_digest;
    // Instanciamos el módulo bajo prueba (DUT)
    sha256_digest uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .message_in(message_in),
        .message_len(message_len),
        .sha256_digest(sha256_digest)
    );
    // Generación de clock
    always #5 clk = ~clk;
    // Tarea para aplicar el mensaje "abc"
    task apply_message();
        begin
            start = 1;
            message_len = 8'd24; // Longitud del mensaje "abc" (3 bytes)
            // Aplicamos los caracteres en ASCII uno por uno
            #10 message_in = 8'h61; // 'a'
            #10 message_in = 8'h62; // 'b'
            #10 message_in = 8'h63; // 'c'
            #5 start = 0;
        end
    endtask
    initial begin
        // Inicialización de señales
        clk = 0;
        reset = 1;
        start = 0;
        message_in = 0;
        message_len = 0;
        // Esperar algunos ciclos y soltar reset
        #20 reset = 0;
        // Aplicamos el mensaje
        apply_message();
        // Esperar procesamiento
        #500;
        // Imprimir el resultado
        $display("SHA-256 Digest: %h", sha256_digest);
    end
endmodule
