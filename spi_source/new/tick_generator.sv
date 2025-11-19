`timescale 1ns / 1ps


module tick_generator (
    input  logic clk,
    input  logic reset,
    output logic tick
);

    logic [$clog2(1_000_000)-1:0] counter_reg, counter_next;
    logic tick_reg;
    assign tick = tick_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;

        end else begin
            counter_reg <= counter_next;
        end
    end

    always_comb begin
        counter_next = counter_reg;
        tick_reg = 1'b0;
        if (counter_reg == 1_000_000) begin
            counter_next = 0;
            tick_reg = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_reg = 1'b0;
        end

    end


endmodule
