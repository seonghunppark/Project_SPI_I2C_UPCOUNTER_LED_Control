`timescale 1ns / 1ps

module upcounter_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       i_runstop,
    input  logic       i_clear,
    input  logic       ready,
    input  logic       done,
    output logic       start,
    output logic [7:0] tx_data

);
    logic tick;
    logic o_runstop;
    logic o_clear;
    logic runstop;
    logic clear;
    logic start_LSB;
    logic start_MSB;

    upcounter_datapath U_UPCOUNTER_DATAPATH (
        .*,

        .i_runstop(runstop),
        .i_clear  (clear)
    );
    tick_generator U_TICK_GEN (.*);

    upcounter_cu U_UPCOUNTER_CU (
        .*,
        .i_runstop(o_runstop),
        .i_clear  (o_clear),
        .o_runstop(runstop),
        .o_clear  (clear)
    );

    button_debounce U_runstop_btn_debounce (
        .*,
        .i_btn(i_runstop),
        .o_btn(o_runstop)
    );
    button_debounce U_clear_btn_debounce (
        .*,
        .i_btn(i_clear),
        .o_btn(o_clear)
    );
endmodule
