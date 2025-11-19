`timescale 1ns / 1ps


module spi_slave (
    //global signals
    input  logic       clk,
    input  logic       reset,
    // Master to Slave signals
    input  logic       start,    // ss(chip select)
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    // slave to control
    output logic [7:0] rx_data,
    output logic       done
);

    typedef enum {
        IDLE,
        CP0,
        CP1
    } state_t;

    state_t state, state_next;
    logic [7:0] rx_data_next, rx_data_reg;
    logic [2:0] bit_counter_next, bit_counter_reg;

    assign rx_data = rx_data_reg;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            rx_data_reg     <= 0;
            bit_counter_reg <= 0;
        end else begin
            state           <= state_next;
            rx_data_reg     <= rx_data_next;
            bit_counter_reg <= bit_counter_next;
        end
    end

    always_comb begin
        state_next       = state;
        rx_data_next     = rx_data_reg;
        bit_counter_next = bit_counter_reg;
        done             = 1'b0;
        miso             = 1'b0;

        case (state)
            IDLE: begin
                done = 1'b0;
                if (start) begin
                    state_next = CP0;
                end
            end
            CP0: begin
                if (sclk) begin
                    rx_data_next = {rx_data_reg[6:0], mosi};
                    miso = rx_data_reg[7];
                    state_next = CP1;
                end
            end
            CP1: begin
                if (sclk == 0) begin
                    if (bit_counter_reg == 7) begin
                        done       = 1'b1;
                        state_next = IDLE;
                        bit_counter_next = 3'b0;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        state_next       = CP0;
                    end
                end
            end

        endcase

    end

endmodule
