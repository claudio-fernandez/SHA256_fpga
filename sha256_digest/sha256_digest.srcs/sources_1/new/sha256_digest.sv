//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2025 02:50:45 PM
// Design Name: 
// Module Name: sha256_digest
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

package sha256_pkg;
    //FUNCIONES DE EXPANSIÓN
    // Función de rotación derecha (rotr)
    function automatic logic [31:0] rotr(input logic [31:0] x, input int n);
        return (x >> n) | (x << (32 - n));
    endfunction
    // Función sigma_0 de SHA-256
    function automatic logic [31:0] sigma0(input logic [31:0] x);
        return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
    endfunction
    // Función sigma_1 de SHA-256
    function automatic logic [31:0] sigma1(input logic [31:0] x);
        return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
    endfunction
    //FUNCIONES DE COMPRESIÓN
     // Función Sigma_0 (mayúscula) para SHA-256
    function automatic logic [31:0] Sigma0(input logic [31:0] x);
        return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
    endfunction
    // Función Sigma_1 (mayúscula) para SHA-256
    function automatic logic [31:0] Sigma1(input logic [31:0] x);
        return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
    endfunction
        // Función Ch (Choose) - Operación bit a bit en 32 bits
    function automatic logic [31:0] Ch(input logic [31:0] x, input logic [31:0] y, input logic [31:0] z);
        return (x & y) ^ (~x & z);
    endfunction
    // Función Maj (Majority) - Operación bit a bit en 32 bits
    function automatic logic [31:0] Maj(input logic [31:0] x, input logic [31:0] y, input logic [31:0] z);
        return (x & y) ^ (x & z) ^ (y & z);
    endfunction
    // Declaración de las constantes K
    logic [31:0] K [0:63] = '{
        32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
        32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
        32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
        32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
        32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
        32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
        32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
        32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
        32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
        32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
        32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
        32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
        32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
        32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
        32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
        32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
    };
    //Declaración de las constantes H
    logic [31:0] H[0:7] = '{
    32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372,
    32'ha54ff53a, 32'h510e527f, 32'h9b05688c,
    32'h1f83d9ab, 32'h5be0cd19
    };
endpackage
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

module sha256_digest(
    input logic             clk,
    input logic             reset,
    input logic             start,
    input logic [7:0]       message_in, // up to 256 bytes
    input logic [7:0]       message_len, // 1 byte
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
    logic [511:0]   padded_message;
    logic [63:0]    W [0:63];
    logic [511:0]   block_padding;
    logic [2:0]     block_count; //Me permitirá contar la cantidad de bloques de 512 bits hay despues del padding
    logic [255:0]   out; // sha256 is always 32 bytes
    logic [511:0]   buffer;
    logic [10:0]    bit_count; // Contador de bits en el buffer
    logic [6:0]     count;
    integer         i;
    integer         t;
    // Inicialización de register
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] c;
    logic [31:0] d;
    logic [31:0] e;
    logic [31:0] f;
    logic [31:0] g;
    logic [31:0] h;
    import sha256_pkg::*;
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
 //We define the 5 states to be able to perform the calculationof Sha256
 typedef enum logic [2:0] {
    Idle        = 3'b000,
    Padding     = 3'b010,
    Expand      = 3'b001,
    Process     = 3'b011,
    Update_hash = 3'b110
} state_t;
state_t current_state, next_state;
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
always_comb begin
    next_state = current_state;
    case(current_state)
        Idle:       begin
                        if (start) begin
                            next_state <= Padding;
                        end
                        else begin
                            next_state <= Idle;
                        end
                    out = 0;
                    done = 0;
                    padding_done = 0;
                    next_step = 0;
                    valid_in = 1;
                    valid_out = 0;
                    Expand_ready = 0;
                    msg_complete = 0;
                    padded_message = 0;
                    block_padding = 0;
                    block_count = 0;
                    buffer = 0;
                    bit_count = 0;
                    padding_start = 0;
                    Process_done = 0;
                    i = 0;
                    t = 0;
                    a = 0;
                    b = 0;
                    c = 0;
                    d = 0;
                    e = 0;
                    f = 0;
                    g = 0;
                    h = 0;
                    end
        Padding:    begin
                        if (valid_in) begin
                            next_state <= Expand;
                        end
                        else begin
                            next_state <= Padding;
                        end
                    end
        Expand:     begin
                        if (valid_out) begin
                            next_state <= Process;
                        end
                        else begin
                            next_state <= Expand;
                        end
                    msg_complete = 0;
                    valid_in = 0;
                    padding_start <= 0;
                    end
        Process:    begin
                            if (Process_done) begin
                                next_state <= Update_hash;
                            end
                        else begin
                            next_state <= Process;
                        end
                            padding_done = 0;
                            count = 0;
                            bit_count = 0;
                    end
       Update_hash: begin
                        if (done) begin
                            next_state <= Idle;
                        end
                        else begin
                            next_state <= Update_hash;
                        end
                    end
    endcase
end 

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
//Agregar un always_ff que explecite los cambios de estados
always_ff@(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= Idle;
    end
    else if (start) begin
        current_state <= Padding;
    end
    else if (padding_done) begin
        current_state <= Expand;
    end
    else if (Expand_ready) begin
        current_state <= Process;
    end
    else if (Process_done) begin
        current_state <= Update_hash;
    end
    else if (done) begin
        current_state <= Idle;
    end
end
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
//Lógica para selección de buffer




/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
//STATE PADDING
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        buffer       <= 512'b0;
        bit_count    <= 9'd0;  // Aseguramos que inicia bien
        bit_count    <= 0;
        msg_complete <= 0;
        padding_done <= 0;
        valid_out    <= 0;
        valid_in     <= 1;
        padding_start <= 0;
    end
    else if (valid_in && !msg_complete) begin
        // Almacenar los datos del mensaje en el buffer
        if (bit_count < message_len) begin
            buffer <= (buffer << 8) | message_in; // Desplazar e insertar byte
            bit_count <= bit_count + 9'd8;
        end
        else if (bit_count == message_len) begin
            buffer <= (buffer << 8) | message_in; // Desplazar e insertar byte
            padding_start <= 1;
            msg_complete  <= 1; // Marcar mensaje completo
        end
    end
    else if (padding_start && !padding_done) begin
    // Agregar el bit '1' una vez
        if (bit_count == message_len) begin
            buffer <= (buffer << 1) | 1'b1; // Añadir el bit 1
            bit_count <= bit_count + 9'd1;
        end
    // Desplazar hasta 448 bits en un solo ciclo
        else if (bit_count > message_len && bit_count < 448) begin
            buffer <= buffer << (bit_count + 9'd8 > 448 ? 448 - bit_count : 9'd8);
            bit_count <= (bit_count +  9'd8 > 448) ? 9'd448 : bit_count + 9'd8; // Si pasa de 448, ajusta
        end
    // Agregar la longitud del mensaje en bits
        else if (bit_count == 448) begin
            buffer <= buffer << 64;
            buffer[63:0] <= message_len; // Longitud en bits
            bit_count <= bit_count + 9'd64;
            padding_done <= 1; // Padding completo
        end
    end
end
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

//EXPAND
always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            i <= 0;
            count <= 0;
        end
        else if (padding_done) begin
            padded_message = buffer;
            // Inicializar W[0] a W[15] con los datos del bloque de entrada
            if (count<16) begin
                W[count] <= {padded_message[511 - (count * 32) -: 8],
                             padded_message[503 - (count * 32) -: 8],
                             padded_message[495 - (count * 32) -: 8],
                             padded_message[487 - (count * 32) -: 8]};
                count <= count +1;
            end
            // Expandir W[16] a W[63]
            else if (count >15 && count<=63) begin
                W[count] <= sha256_pkg::sigma1(W[count-2]) + W[count-7] + sha256_pkg::sigma0(W[count-15]) + W[count-16];
                count <= count +1;
            end
            else if (count > 63) begin
            Expand_ready <= 1;  // Indicar que la expansión ha terminado
            valid_out <= 1;
            padding_done <= 0;
            end
        end
    end
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
//PROCESS
always_ff@(posedge clk or posedge reset) begin
        if (Expand_ready) begin
            next_step <= 1;
            if (next_step) begin
                a <= sha256_pkg::H[0];
                b <= sha256_pkg::H[1];
                c <= sha256_pkg::H[2];
                d <= sha256_pkg::H[3];
                e <= sha256_pkg::H[4];
                f <= sha256_pkg::H[5];
                g <= sha256_pkg::H[6];
                h <= sha256_pkg::H[7];
                next_step <= 0;
            end
        else if (valid_out) begin
            // Ejecutar las 64 rondas del algoritmo SHA-256
            if (t>=0 && t<64) begin
                logic [31:0] T1, T2;
                T1 = h + sha256_pkg::Sigma1(e) + sha256_pkg::Ch(e, f, g) + sha256_pkg::K[t] + W[t];
                T2 = sha256_pkg::Sigma0(a) + sha256_pkg::Maj(a, b, c);
                h <= g;
                g <= f;
                f <= e;
                e <= d + T1;
                d <= c;
                c <= b;
                b <= a;
                a <= T1 + T2;
                t <= t+1;
            end
            else if (t == 64) begin
                Process_done = 1;
            end
        end
    end
end
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
//Update_hash
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        sha256_digest <= 256'b0;
    end
    else if (valid_out) begin
        sha256_digest <= {sha256_pkg::H[0], sha256_pkg::H[1], sha256_pkg::H[2], sha256_pkg::H[3],
                sha256_pkg::H[4], sha256_pkg::H[5], sha256_pkg::H[6], sha256_pkg::H[7]};
        done <= 1;
    end
end
endmodule


//Arreglar el código para que se implemente para N bloques de 512 bits
//Revisar las condiciones para pasar de un estado a otro. Ver si necesiran ser cambiadas o no
//Generar un buffer dinámico que dependa del largo del mensaje con un valor hasta 1536 bits parece ser suficiente.
//Terminar de arreglar el estado de process que calcula los valores, pero se reinician a los valores originales al terminar de calcularlos
