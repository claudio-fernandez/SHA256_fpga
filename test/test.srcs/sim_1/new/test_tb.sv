`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2025 04:35:21 PM
// Design Name: 
// Module Name: test_tb
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


module test_tb;

    // Señales del DUT (Device Under Test)
    logic clk;
    logic reset;
    logic start;
    logic [7:0] message_in;
    logic [15:0] message_len;
    logic [255:0] sha256_digest;
    
    //Testvector de 448 bits
//    logic [7:0] message_array [0:55] = '{
//    8'h61, 8'h62, 8'h63, 8'h64, 8'h62, 8'h63, 8'h64, 8'h65,
//    8'h63, 8'h64, 8'h65, 8'h66, 8'h64, 8'h65, 8'h66, 8'h67,
//    8'h65, 8'h66, 8'h67, 8'h68, 8'h66, 8'h67, 8'h68, 8'h69,
//    8'h67, 8'h68, 8'h69, 8'h6A, 8'h68, 8'h69, 8'h6A, 8'h6B,
//    8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6A, 8'h6B, 8'h6C, 8'h6D,
//    8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6C, 8'h6D, 8'h6E, 8'h6F,
//    8'h6D, 8'h6E, 8'h6F, 8'h70, 8'h6E, 8'h6F, 8'h70, 8'h71
//};

    //Testvector de 896 bits
    logic [7:0] message_array [0:111] = '{
    8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67, 8'h68, // "abcdefgh"
    8'h62, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67, 8'h69, 8'h63, // "bcdefghi"
    8'h64, 8'h65, 8'h66, 8'h67, 8'h69, 8'h68, 8'h6A, 8'h64, // "cdefghij"
    8'h65, 8'h66, 8'h67, 8'h68, 8'h69, 8'h6A, 8'h6B, 8'h65, // "defghijk"
    8'h66, 8'h67, 8'h68, 8'h6B, 8'h66, 8'h67, 8'h68, 8'h6C, // "efghijkl"
    8'h66, 8'h67, 8'h68, 8'h6C, 8'h6D, 8'h67, 8'h68, 8'h6C, // "fghijklm"
    8'h6D, 8'h6E, 8'h67, 8'h68, 8'h6C, 8'h6D, 8'h6F, 8'h69, // "ghijklmn"
    8'h6A, 8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6F, 8'h70, 8'h6A, // "hijklmno"
    8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6F, 8'h71, 8'h6B, 8'h6C, // "ijklmnop"
    8'h6D, 8'h6E, 8'h6F, 8'h72, 8'h73, 8'h6D, 8'h6E, 8'h6F, // "jklmnopq"
    8'h74, 8'h73, 8'h74, 8'h6E, 8'h6F, 8'h74, 8'h73, 8'h74, // "klmnopqr"
    8'h6E, 8'h6F, 8'h70, 8'h73, 8'h74, 8'h6E, 8'h6F, 8'h72, // "lmnopqrs"
    8'h74, 8'h73, 8'h74, 8'h6E, 8'h6F, 8'h72, 8'h73, 8'h74, // "nopqrstu"
    8'h68, 8'h6F, 8'h6C, 8'h61, 8'h61, 8'h62, 8'h63, 8'h64  // "holaabcd"
};
    integer i;

    // Instancia del módulo bajo prueba (DUT)
    test dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .message_in(message_in),
        .message_len(message_len),
        .sha256_digest(sha256_digest)
    );

    // Generador de reloj (50 MHz = 20 ns de periodo)
    always #10 clk = ~clk;

    // Procedimiento de prueba
    initial begin
        // Inicialización
        clk = 0;
        reset = 1;
        start = 0;
        message_in = 8'h0;
        message_len = 896;
        
        
        
        // Esperar unos ciclos y quitar el reset
        #50;
        reset = 0;
        #20;

        // Configurar el mensaje "abc" (24 bits, 3 bytes)
        message_len = 896; // Solo 3 bytes

        for (i = 0; i < 112; i = i + 1) begin
            message_in = message_array[i]; // Enviar el siguiente byte
//            #($urandom_range(1, 20)); // Esperar un tiempo aleatorio entre 1 y 20 ns
            #20;
        end

    end
endmodule