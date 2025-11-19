`timescale 1ns / 1ps

module upcounter_cu (
    // global signal
    input  logic clk,
    input  logic reset,
    // btn signal
    input  logic i_runstop,
    input  logic i_clear,
    // control unit to data path
    output logic o_runstop,
    output logic o_clear,
    // SPI master to Counter Control Unit 
    input  logic ready,
    input  logic done,
    output logic start,
    output logic start_LSB,
    output logic start_MSB
);

    typedef enum {
        STOP,
        RUN,
        CLEAR
    } state_t;

    typedef enum {
        IDLE,
        SEND_LSB,
        WAIT_DONE,
        SEND_MSB
    } state_data;


    state_t state, state_next;
    state_data data_state, data_state_next;


    logic runstop_reg, runstop_next;
    logic clear_reg, clear_next;
    logic start_signal;
    logic start_LSB_signal, start_MSB_signal;

    assign o_runstop = runstop_reg;
    assign o_clear = clear_reg;

    assign start = start_signal;
    assign start_LSB = start_LSB_signal;
    assign start_MSB = start_MSB_signal;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state       <= STOP;
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;
            data_state  <= IDLE;
        end else begin
            state       <= state_next;
            runstop_reg <= runstop_next;
            clear_reg   <= clear_next;
            data_state  <= data_state_next;
        end
    end

    always_comb begin
        state_next       = state;
        runstop_next     = runstop_reg;  // 1: run, 0:stop
        clear_next       = 1'b0;
        start_signal     = 1'b0;
        start_LSB_signal = 1'b0;
        start_MSB_signal = 1'b0;
        data_state_next  = data_state;
        case (state)
            STOP: begin
                runstop_next = 1'b0;
                case (data_state)
                    IDLE: begin
                        start_signal = 1'b0;
                        start_MSB_signal = 1'b0;
                        if (ready) begin
                            data_state_next = SEND_LSB;
                        end
                    end
                    SEND_LSB: begin
                        start_signal = 1'b1;
                        start_LSB_signal = 1'b1;
                        data_state_next = WAIT_DONE;
                    end
                    WAIT_DONE: begin
                        start_signal = 1'b1;
                        start_LSB_signal = 1'b0;
                        if (done) begin
                            data_state_next = SEND_MSB;
                        end
                    end
                    SEND_MSB: begin
                        start_signal = 1'b1;
                        start_MSB_signal = 1'b1;
                        if (done) begin
                            data_state_next = IDLE;
                        end
                    end
                endcase
                if (i_runstop) begin
                    state_next   = RUN;
                    runstop_next = 1'b1;
                end else if (i_clear) begin
                    state_next = CLEAR;
                    clear_next = 1'b1;
                end
            end
            RUN: begin
                runstop_next = 1'b1;
                case (data_state)
                    IDLE: begin
                        start_signal = 1'b0;
                        start_MSB_signal = 1'b0;
                        if (ready) begin
                            data_state_next = SEND_LSB;
                        end
                    end
                    SEND_LSB: begin
                        start_signal = 1'b1;
                        start_LSB_signal = 1'b1;
                        data_state_next = WAIT_DONE;
                    end
                    WAIT_DONE: begin
                        start_signal = 1'b1;
                        start_LSB_signal = 1'b0;
                        if (done) begin
                            data_state_next = SEND_MSB;
                        end
                    end
                    SEND_MSB: begin
                        start_signal = 1'b1;
                        start_MSB_signal = 1'b1;
                        if (done) begin
                            data_state_next = IDLE;
                        end
                    end
                endcase

                if (i_runstop) begin
                    state_next   = STOP;
                    runstop_next = 1'b0;
                end else if (i_clear) begin
                    state_next = CLEAR;
                    clear_next = 1'b1;
                end
            end
            CLEAR: begin
                state_next = STOP;
                clear_next = 1'b0;
            end

        endcase

    end



endmodule
