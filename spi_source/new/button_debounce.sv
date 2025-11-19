`timescale 1ns / 1ps

module button_debounce (
    input  logic clk,
    input  logic reset,
    input  logic i_btn,
    output logic o_btn
);
    //100M -> 1M tick generate period
    logic [$clog2(100)-1:0] counter_reg, counter_next; 
    logic tick_next, tick_reg;
    logic [7:0] q_reg, q_next; // Flip-Flop of 8
    logic edge_reg;
    logic debounce;


    // counter 값 업데이트
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            tick_reg    <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end

    // tick_generator
    always_comb begin
        counter_next = counter_reg;
        tick_next    = tick_reg;
        if (counter_reg == 98) begin
            counter_next = 0;
            tick_next = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next    = 1'b0;
        end

    end

    // debounce, shift register
    always_ff @( posedge tick_reg, posedge reset ) begin 
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    // serial input, parallel shift register
    always_ff @(posedge clk) begin
        q_next = {i_btn, q_reg[7:1]};    
    end

    // 8 input AND
    assign debounce = &q_next;

    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    //edge output
    assign o_btn = ~edge_reg & debounce;

endmodule

