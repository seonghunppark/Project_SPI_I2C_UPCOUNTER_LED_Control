`timescale 1ns / 1ps

module spi_slave_control (
    //global signals
    input logic clk,
    input logic reset,
    // slave to control
    input logic [7:0] rx_data,
    input logic done,
    // control to FND
    output logic [13:0] data
);

    typedef enum {
        SEND_LSB,
        SEND_MSB,
        SEND_FULL
    } state_t;

    state_t state, state_next;

    logic [15:0] data_reg, data_next;
    logic [7:0] slv_reg1, slv_reg1_next;
    logic [7:0] slv_reg2, slv_reg2_next;
    assign data = data_reg[13:0];

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= SEND_LSB;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            data_reg <= 0;
        end else begin
            state <= state_next;
            slv_reg1 <= slv_reg1_next;
            slv_reg2 <= slv_reg2_next;
            data_reg <= data_next;
        end
    end


    always_comb begin
        
        data_next = data_reg;
        state_next = state;
        case (state)
            SEND_LSB: begin
                if (done) begin
                    slv_reg1_next = rx_data;
                    state_next = SEND_MSB;
                end
            end
            SEND_MSB: begin
                if (done) begin
                    slv_reg2_next = rx_data;
                    state_next = SEND_FULL;
                end
            end
            SEND_FULL: begin
                state_next = SEND_LSB;
                data_next  = {slv_reg1, slv_reg2};
                
            end
        endcase
    end



endmodule
