`timescale 1ns / 1ps


module spi_slave_top (
    // global signals
    input logic clk,
    input logic reset,
    // Master to Slave Signals
    input logic start,
    input logic sclk,
    input logic mosi,
    output logic miso,
    // output to FND
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic [ 7:0] rx_data;
    logic        done;
    logic [13:0] data;
    spi_slave U_SPI_SLAVE (.*);

    spi_slave_control U_SPI_SLAVE_CONTROL (.*);

    fnd_controller U_FND_CONTROLLER (.*);

endmodule
