`timescale 1ns / 1ps


module upcounter_datapath (
    input logic clk,
    input logic reset,
    input logic tick,
    input logic i_runstop,
    input logic i_clear,
    input logic start_LSB,
    input logic start_MSB,
    output logic [7:0] tx_data
    // 문제 상황은 시간 값은 9999까지 표현해야하기 때문에
    // 14비트를 8비트 두 번으로 나누어서 보내줘야하는데
    // 이걸 어떻게 구현하는냐
);

    logic [$clog2(10000)-1:0] counter_reg, counter_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [$clog2(10000)-1:0] temp_counter, temp_counter_next;
    logic [$clog2(10000)-1:0] time_counter, time_counter_next;



    assign tx_data   = tx_data_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset | i_clear) begin
            counter_reg  <= 0;
            time_counter <= 0;
            tx_data_reg  <= 0;
        end else begin
            counter_reg  <= counter_next;
            time_counter <= time_counter_next;
            tx_data_reg  <= tx_data_next;
        end
    end

    // always_comb begin
    //     if (i_runstop) begin
    //         if (counter_reg == 1_000_000) begin
    //             counter_next = 0;
    //         end else begin
    //             counter_next = counter_reg + 1;
    //         end
    //     end else begin
    //         counter_next = counter_reg;
    //     end
    // end

    always_comb begin
        time_counter_next = time_counter;
        if (i_runstop) begin
            if (tick) begin
                if (time_counter == 10000) begin
                    time_counter_next = 0;
                end else begin
                    time_counter_next = time_counter + 1;
                end
            end
        end else begin
            time_counter_next = time_counter; 
        end
    end




    always_comb begin
        tx_data_next = tx_data_reg;
        if (start_LSB) begin
            tx_data_next = time_counter[7:0];
        end else if (start_MSB) begin
            tx_data_next = {2'b00, time_counter[13:8]};
        end
    end




endmodule




