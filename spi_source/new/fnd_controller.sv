`timescale 1ns / 1ps

module fnd_controller (
    input logic clk,
    input logic reset,
    input logic [13:0] data,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic clk_1khz;
    logic [1:0] sel;
    logic [3:0] bcd;
    logic [3:0] digit_ones;
    logic [3:0] digit_tens;
    logic [3:0] digit_hundreds;
    logic [3:0] digit_thousands;

    //--------------- FND_COM-----------------------
    decorder_2x4 U_DECORDER_2X4 (.*);

    counter_4 U_COUNTER_4 (.*);

    clk_div_1khz U_clk_1khz (.*);
    //--------------- FND_COM-----------------------

    //--------------- FND_DATA-----------------------
    bcd_decorder U_BCD_DECORDER (.*);
    mux_4x1 U_MUX_4X1 (
        .*,
        .digit_data(bcd)
    );
    digit_splitter U_DIGIT_SPLITTER (.*);

    //--------------- FND_DATA-----------------------

endmodule



module decorder_2x4 (
    input  logic [1:0] sel,
    output logic [3:0] fnd_com
);
    assign fnd_com = (sel == 2'b00) ? 4'b1110:
                     (sel == 2'b01) ? 4'b1101:
                     (sel == 2'b10) ? 4'b1011:
                     (sel == 2'b11) ? 4'b0111: 4'b1111;

endmodule


module counter_4 (
    input logic clk_1khz,
    input logic clk,
    input logic reset,
    output logic [1:0] sel
);

    logic [1:0] count_reg, count_next;
    assign sel = count_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_next;
        end
    end

    always_comb begin
        if (clk_1khz) begin
            count_next = count_reg + 1;
        end else begin
            count_next = count_reg;
        end
    end

endmodule



module clk_div_1khz (
    input  logic clk,
    input  logic reset,
    output logic clk_1khz
);

    logic [$clog2(100_000)-1:0] counter_reg, counter_next;
    logic tick_reg, tick_next;


    assign clk_1khz = tick_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            tick_reg    <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end

    always_comb begin
        counter_next = counter_reg;
        tick_next = 1'b0;
        if (counter_reg == 100_000) begin
            counter_next = 0;
            tick_next = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next = 1'b0;
        end

    end

endmodule

module bcd_decorder (
    input  logic [3:0] bcd,
    output logic [7:0] fnd_data
);
    always_comb begin
        fnd_data = 8'h0;
        case (bcd)
            4'h0: fnd_data = 8'hc0; 
            4'h1: fnd_data = 8'hf9; 
            4'h2: fnd_data = 8'ha4; 
            4'h3: fnd_data = 8'hb0; 
            4'h4: fnd_data = 8'h99; 
            4'h5: fnd_data = 8'h92; 
            4'h6: fnd_data = 8'h82; 
            4'h7: fnd_data = 8'hf8; 
            4'h8: fnd_data = 8'h80; 
            4'h9: fnd_data = 8'h90; 
        endcase
    end
endmodule

module mux_4x1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_ones,
    input  logic [3:0] digit_tens,
    input  logic [3:0] digit_hundreds,
    input  logic [3:0] digit_thousands,
    output logic [3:0] digit_data
);

    logic [3:0] data;
    assign digit_data = data;

    always_comb begin
        data = 4'b0000;
        case (sel)
            2'b00: data = digit_ones;
            2'b01: data = digit_tens;
            2'b10: data = digit_hundreds;
            2'b11: data = digit_thousands;
        endcase

    end

endmodule

module digit_splitter (
    input  logic [13:0] data,
    output logic [ 3:0] digit_ones,
    output logic [ 3:0] digit_tens,
    output logic [ 3:0] digit_hundreds,
    output logic [ 3:0] digit_thousands

);

    assign digit_ones      = data % 10;
    assign digit_tens      = (data / 10) % 10;
    assign digit_hundreds  = (data / 100) % 10;
    assign digit_thousands = (data / 1000);


endmodule


