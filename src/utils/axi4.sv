`timescale 1ns / 1ps
`default_nettype none

package axi4;

typedef enum logic [1:0] {
    OKAY           = 2'b00,
    EXCLUSIVE_OKAY = 2'b01,
    DEVICE_ERROR   = 2'b10,
    DECODE_ERROR   = 2'b11
} axi_response_t;

typedef enum logic {
    DATA        = 1'b0,
    INSTRUCTION = 1'b1
} axi_access_type_t;

typedef struct packed {
    axi_access_type_t access_type;
    logic             non_secure;
    logic             privileged;
} axi_permissions_t;

interface axi4_lite_read_channel (logic aclk, logic aresetn);
    // read address channel
    logic             arvalid;
    logic             arready;
    word_t            araddr;
    axi_permissions_t arprot;

    // read data channel
    logic             rvalid;
    logic             rready;
    word_t            rdata;
    axi_response_t    rresp;

    modport host (
        input  aclk, aresetn,
        // read address channel
        input  arready,
        output arvalid, araddr, arprot,
        // read data channel
        input  rvalid, rdata, rresp,
        output rready
    );

    modport device (
        input  aclk, aresetn,
        // read address channel
        output arready,
        input  arvalid, araddr, arprot,
        // read data channel
        output rvalid, rdata, rresp,
        input  rready
    );
endinterface

interface axi4_lite_write_channel (logic aclk, logic aresetn);
    // write address channel
    logic             awvalid;
    logic             awready;
    word_t            awaddr;
    axi_permissions_t awprot;

    // write data channel
    logic             wvalid;
    logic             wready;
    word_t            wdata;
    logic [3:0]       wstrb;

    // write response channel
    logic             bvalid;
    logic             bready;
    axi_response_t    bresp;

    modport host (
        input  aclk, aresetn,
        // write address channel
        input  awready,
        output awvalid, awaddr, awprot,
        // write data channel
        input  wready,
        output wvalid, wdata, wstrb,
        // write data channel
        input  bready
        output bvalid, bresponse
    );

    modport device (
        input  aclk, aresetn,
        // write address channel
        output awready,
        input  awvalid, awaddr, awprot,
        // write data channel
        output wready,
        input  wvalid, wdata, wstrb,
        // write data channel
        output bready
        input  bvalid, bresponse
    );
endinterface

endmodule
