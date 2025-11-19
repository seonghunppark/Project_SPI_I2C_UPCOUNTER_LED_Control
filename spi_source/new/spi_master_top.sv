`timescale 1ns / 1ps


module spi_master_top (
    //global signals
    input logic clk,
    input logic reset,
    // Upcounter input
    input logic i_runstop,
    input logic i_clear,

    //external signals
    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic start
);

    logic       start_sig;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       tx_ready;
    logic       done;

    assign start = start_sig;

    spi_master U_SPI_MASTER (
        .*,
        .start(start_sig)
    );


    upcounter_top U_UPCOUNTER (
        .*,
        .ready(tx_ready),
        .start(start_sig)


    );

endmodule
