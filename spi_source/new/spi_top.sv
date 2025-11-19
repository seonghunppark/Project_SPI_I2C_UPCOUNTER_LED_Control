`timescale 1ns / 1ps


module spi_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       i_runstop,
    input  logic       i_clear,
    input  logic       sclk,
    input  logic       mosi,
    input  logic       start,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,
    output logic       o_sclk,
    output logic       o_mosi,
    output logic       o_start
);



    spi_master_top U_SPI_MASTER_TOP (
        .*,
        .sclk (o_sclk),
        .mosi (o_mosi),
        .start(o_start),
        .miso ()
    );

    spi_slave_top U_SPI_SLAVE_TOP (
        .*,
        .miso()
    );



endmodule
