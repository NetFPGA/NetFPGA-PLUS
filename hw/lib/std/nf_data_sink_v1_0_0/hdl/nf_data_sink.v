//-
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
//                          Junior University
// Copyright (C) 2010, 2011 Adam Covington
// Copyright (C) 2015 Noa Zilberman
// Copyright (C) 2021 Yuta Tokusashi
// Copyright (C) 2024 Gregory Watson
//
// All rights reserved.
//
// This software was developed by
// Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme,
// and by the University of Cambridge Computer Laboratory under EPSRC EARL Project
// EP/P025374/1 alongside support from Xilinx Inc.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
/*******************************************************************************
 *  File:
 *        nf_data_sink.v
 *
 *  Library:
 *        hw/std/cores/nf_data_sink
 *
 *  Module:
 *        nf_data_sink
 *
 *  Author:
 *        Greg Watson
 * 		
 *  Description:
 *        Accepts incoming data and discards it. 
 *        Provides statistics on input data rate.
 *
 */

`timescale 1ns/1ns
`include "nf_data_sink_cpu_regs_defines.v"

module nf_data_sink
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=1024,
    parameter C_S_AXIS_DATA_WIDTH=1024,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter NUM_QUEUES=1,
    
    // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,          
    parameter C_S_AXI_ADDR_WIDTH    = 12,          
    parameter C_BASEADDR            = 32'h00000000
 
)
(
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // --- Master Stream Ports (interface to data path)
    // --- n.c. until we code DMA tx logic
    // output [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    // output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    // output [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    // output m_axis_tvalid,
    // input  m_axis_tready,
    // output m_axis_tlast,


    // DMA data from Host
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_2_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_2_tuser,
    input  s_axis_2_tvalid,
    output s_axis_2_tready,
    input  s_axis_2_tlast,

    // Slave AXI Ports
    input                                     S_AXI_ACLK,
    input                                     S_AXI_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input                                     S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
    input                                     S_AXI_WVALID,
    input                                     S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input                                     S_AXI_ARVALID,
    input                                     S_AXI_RREADY,
    output                                    S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output     [1 : 0]                        S_AXI_RRESP,
    output                                    S_AXI_RVALID,
    output                                    S_AXI_WREADY,
    output     [1 :0]                         S_AXI_BRESP,
    output                                    S_AXI_BVALID,
    output                                    S_AXI_AWREADY

);


  function integer log2;
     input integer number;
     begin
        log2=0;
        while(2**log2<number) begin
           log2=log2+1;
        end
     end
  endfunction // log2

  // TKEEP_WIDTH is number of bytes in the data path.
  localparam TKEEP_WIDTH = C_S_AXIS_DATA_WIDTH / 8;
  localparam VALID_COUNT_WIDTH = log2(TKEEP_WIDTH) + 1;
  localparam BITS_TO_COUNT = TKEEP_WIDTH/4;

  // To compute packet length we need to sum the number of 1's in tkeep
  // at the last transfer (tlast == 1). tkeep may be wide (128 bits) and
  // Vivado struggles to meet timing so I broke this into two clock phases
  // and compute 4 partial sums in the first phase and then sum the four
  // partials in the second phase.

  // count number of 1's in a vector
  function [VALID_COUNT_WIDTH-1:0] count_ones;
    input [BITS_TO_COUNT-1:0] bit_vec;
    integer i;
    begin
      count_ones = 0;
      for (i = 0 ; i < BITS_TO_COUNT; i = i + 1)
      begin
        count_ones = count_ones + bit_vec[i];
      end
    end
  endfunction // count_ones

  // XOR all the data into a 32 bit value
  function [7:0] tdata_xor;
    input [C_S_AXIS_DATA_WIDTH - 1:0] tdata;
    input [TKEEP_WIDTH-1:0] tkeep;
    integer i;
    begin
      tdata_xor = 0;
      for (i = 0 ; i < TKEEP_WIDTH; i = i + 1)
      begin
        tdata_xor = tdata_xor ^ (tkeep[i] ? tdata[i*8 +: 8] : 0);
      end
    end
  endfunction // tdata_xor

// ------------ Internal Params --------

//   localparam  NUM_QUEUES_WIDTH = log2(NUM_QUEUES);


//   localparam NUM_STATES = 1;
//   localparam IDLE = 0;
//   localparam WR_PKT = 1;

//   localparam MAX_PKT_SIZE = 2000; // In bytes
//   localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

  // ------------- Regs/ wires -----------
  // Start axi clk domain (registers)

    reg   [`REG_ID_BITS]        id_reg;
    reg   [`REG_VERSION_BITS]   version_reg;
    wire  [`REG_RESET_BITS]     reset_reg;
    reg   [`REG_FLIP_BITS]      ip2cpu_flip_reg;
    wire  [`REG_FLIP_BITS]      cpu2ip_flip_reg;
    reg   [`REG_DEBUG_BITS]     ip2cpu_debug_reg;
    wire  [`REG_DEBUG_BITS]     cpu2ip_debug_reg;
    reg   [`REG_ENABLE_BITS]    ip2cpu_enable_reg;
    wire  [`REG_ENABLE_BITS]    cpu2ip_enable_reg;
    reg   [`REG_AXI_CLK_BITS]   axi_clk_reg;

    reg                         active_reg_axi;
    reg                         enabled;
    reg                         sample_reg;
    reg                         clear_counters;
    reg                         reset_registers;


  // End axi clk domain (registers)
  //--------------------------------------
  // Start AXIS clk domain

  reg [C_M_AXIS_DATA_WIDTH-1:0]        in_tdata;
  reg [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_tkeep;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]       in_tuser;
  reg  	                               in_tvalid;
  reg                                  in_tlast;
  reg  	                               in_tvalid2;
  reg                                  in_tlast2;

  // Do something with data to prevent logic erasure.
  reg [7:0]                            in_tdata_xor1;
  reg [7:0]                            in_tdata_xor2;

  reg   [`REG_AXIS_CLK_BITS]  axis_clk_reg;
  reg                         sample_reg_axis;
  reg                         sample_reg_axis_d1;
  reg                         sample_axis;
  reg  [2:0]                  enabled_axis_v;

  reg [63:0] bytesin_count;
  reg [31:0] pktin_count;
  reg [31:0] time_count;
  reg        in_packet;
  reg        active_reg;
  reg [31:0] time_at_last_eop;
  reg [31:0] total_pkt_count;
  reg [15:0] current_pkt_byte_count;

  reg [VALID_COUNT_WIDTH-1:0] bytes_valid_quarter[0:3];

  reg   [`REG_PKTIN_BITS]     axis_pkt_in_reg;
  reg   [`REG_BYTESINLO_BITS] axis_bytesinlo_reg;
  reg   [`REG_BYTESINHI_BITS] axis_bytesinhi_reg;
  reg   [`REG_TIME_BITS]      axis_time_reg;

  integer i;   // loop counter

  // tick counter to extend the duration of the timer without requiring
  // a new 32b reg, at the cost of some precision.
  `define TICK_BITS 3
  reg [`TICK_BITS-1:0] tick_ctr;
  wire tick_now;
  assign tick_now = tick_ctr == 3'd1;

  // End AXIS clk domain
  //--------------------------------------

  wire enabled_axis;
  assign enabled_axis = enabled_axis_v[2];

  wire enabled_axis_sop; 
  wire enabled_axis_mop;
  wire enabled_axis_eop;
  wire is_active_axis; 


  assign enabled_axis_sop = enabled_axis & in_tvalid2 & ~in_packet  & s_axis_2_tready;
  assign enabled_axis_eop = enabled_axis & in_tvalid2 &  in_tlast2  & s_axis_2_tready;
  assign enabled_axis_mop = enabled_axis & in_tvalid2 & ~in_tlast2  & s_axis_2_tready;
  assign is_active_axis   = enabled_axis_sop | active_reg;

  wire [VALID_COUNT_WIDTH-1:0] number_of_last_bytes; // num bytes valid in tlast transaction.
  assign number_of_last_bytes = (bytes_valid_quarter[0] + bytes_valid_quarter[1]) +
                                (bytes_valid_quarter[2] + bytes_valid_quarter[3]);

  // ------------ Modules -------------

  // ------------- Logic ------------

   always @(posedge axis_aclk) begin
      in_tdata       <= s_axis_2_tdata;
      in_tkeep       <= s_axis_2_tkeep;
      in_tuser       <= s_axis_2_tuser;
      in_tvalid      <= s_axis_2_tvalid;
      in_tlast       <= s_axis_2_tlast;

      in_tvalid2     <= in_tvalid;
      in_tlast2      <= in_tlast;

      in_tdata_xor1 <= tdata_xor(in_tdata, in_tkeep);
      in_tdata_xor2 <= in_tdata_xor1;
   end

  assign s_axis_2_tready = 1'b1; // always accept data

  //Registers section
  nf_data_sink_cpu_regs 
  #(
    .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
    .C_BASE_ADDRESS    (C_BASEADDR)
  ) nf_data_sink_cpu_regs_inst
  (   
    // General ports
     .clk                    (axis_aclk),
     .resetn                 (axis_resetn),
    // AXI Lite ports
     .S_AXI_ACLK             (S_AXI_ACLK),
     .S_AXI_ARESETN          (S_AXI_ARESETN),
     .S_AXI_AWADDR           (S_AXI_AWADDR),
     .S_AXI_AWVALID          (S_AXI_AWVALID),
     .S_AXI_WDATA            (S_AXI_WDATA),
     .S_AXI_WSTRB            (S_AXI_WSTRB),
     .S_AXI_WVALID           (S_AXI_WVALID),
     .S_AXI_BREADY           (S_AXI_BREADY),
     .S_AXI_ARADDR           (S_AXI_ARADDR),
     .S_AXI_ARVALID          (S_AXI_ARVALID),
     .S_AXI_RREADY           (S_AXI_RREADY),
     .S_AXI_ARREADY          (S_AXI_ARREADY),
     .S_AXI_RDATA            (S_AXI_RDATA),
     .S_AXI_RRESP            (S_AXI_RRESP),
     .S_AXI_RVALID           (S_AXI_RVALID),
     .S_AXI_WREADY           (S_AXI_WREADY),
     .S_AXI_BRESP            (S_AXI_BRESP),
     .S_AXI_BVALID           (S_AXI_BVALID),
     .S_AXI_AWREADY          (S_AXI_AWREADY),

    // Register ports
    .id_reg           (id_reg),
    .version_reg      (version_reg),
    .reset_reg        (reset_reg),
    .ip2cpu_flip_reg  (ip2cpu_flip_reg),
    .cpu2ip_flip_reg  (cpu2ip_flip_reg),
    .ip2cpu_debug_reg (ip2cpu_debug_reg),
    .cpu2ip_debug_reg (cpu2ip_debug_reg),

    .ip2cpu_enable_reg (ip2cpu_enable_reg),
    .cpu2ip_enable_reg (cpu2ip_enable_reg),
    .pktin_reg         (axis_pkt_in_reg),
    .bytesinlo_reg     (axis_bytesinlo_reg),
    .bytesinhi_reg     (axis_bytesinhi_reg),
    .time_reg          (axis_time_reg),
    .axi_clk_reg       (axi_clk_reg),
    .axis_clk_reg      (axis_clk_reg),

    // Global Registers - user can select if to use
    .cpu_resetn_soft(),//software reset, after cpu module
    .resetn_soft    (),//software reset to cpu module (from central reset management)
    .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
  );
    //-------------------------------------------------------------------------------
    // Start S_AXI CLock domain
    always @( posedge S_AXI_ACLK) 
      if (~S_AXI_ARESETN | reset_registers) begin
        id_reg            <= #1  `REG_ID_DEFAULT;
        version_reg       <= #1  `REG_VERSION_DEFAULT;

        ip2cpu_flip_reg   <= #1  `REG_FLIP_DEFAULT;
        ip2cpu_debug_reg  <= #1  `REG_DEBUG_DEFAULT;
        ip2cpu_enable_reg <= 32'd0;
        axi_clk_reg       <= 32'd0;
        active_reg_axi    <= 1'b0;
        enabled           <= 1'b0;
        sample_reg        <= 1'b0;
        clear_counters    <= 1'b1;
        reset_registers   <= 1'b0;

      end
      else begin
        ip2cpu_flip_reg   <= #1 ~cpu2ip_flip_reg;
        ip2cpu_debug_reg  <= #1 `REG_DEBUG_DEFAULT+cpu2ip_debug_reg;
        ip2cpu_enable_reg <= {in_tdata_xor2, 22'd0, active_reg_axi, enabled};
        axi_clk_reg       <= axi_clk_reg + 1;
        active_reg_axi    <= 1'b0;

        enabled           <= cpu2ip_enable_reg[0];
        sample_reg        <= cpu2ip_enable_reg[1];
        clear_counters    <= reset_reg[0];
        reset_registers   <= reset_reg[4];
      end
    // end S_AXI clock domain
    //-------------------------------------------------------------------------------

    //-------------------------------------------------------------------------------
    // Start axis_aclk CLock domain
    always @(posedge axis_aclk)

      if (~resetn_sync | reset_registers) begin

        axis_clk_reg           <= 32'd0;
        sample_reg_axis        <= 1'b0;
        sample_reg_axis_d1     <= 1'b0;
        sample_axis            <= 1'b0;
        enabled_axis_v         <= 3'd0;
        bytesin_count          <= 64'd0;
        pktin_count            <= 0;
        time_count             <= 0;
        in_packet              <= 1'b0;
        active_reg             <= 1'b0;
        time_at_last_eop       <= 0;
        total_pkt_count        <= 0;
        current_pkt_byte_count <= 0;
        axis_pkt_in_reg        <= 32'd0;
        axis_bytesinlo_reg     <= 32'd0;
        axis_bytesinhi_reg     <= 32'd0;
        axis_time_reg          <= 32'd0;
        tick_ctr               <= `TICK_BITS'd0;

        for (i=0; i<4; i=i+1) bytes_valid_quarter[i] <= 0;
      end
      else begin

        axis_clk_reg           <= axis_clk_reg + 1;
        sample_reg_axis        <= sample_reg;  // clock cross
        sample_reg_axis_d1     <= sample_reg_axis;
        sample_axis            <= sample_reg_axis & ~sample_reg_axis_d1;

        enabled_axis_v         <= {enabled_axis_v[1:0], enabled}; // clock cross

        bytesin_count <= enabled_axis_eop & is_active_axis  ? bytesin_count + current_pkt_byte_count + number_of_last_bytes : 
                                            is_active_axis  ? bytesin_count 
                                                            : 64'd0;

        pktin_count   <= enabled_axis ? pktin_count + {31'd0, is_active_axis  & enabled_axis_eop} : 0;

        for (i=0; i<4; i=i+1)
          bytes_valid_quarter[i] <= in_tlast ? count_ones(in_tkeep[i*BITS_TO_COUNT +: BITS_TO_COUNT])
                                             : 0;

        time_count    <= (is_active_axis | enabled_axis_sop) ? time_count + tick_now : enabled_axis ? time_count : 0;

        // do not go active in the middle of a packet - wait until end of current packet.
        in_packet  <= (enabled_axis_sop & ~enabled_axis_eop)  | (in_packet & ~enabled_axis_eop);
        active_reg <= enabled_axis & (active_reg | is_active_axis);

        time_at_last_eop <= (enabled_axis_eop & is_active_axis) ? time_count :
                            enabled_axis ? time_at_last_eop : 0;
        total_pkt_count <= total_pkt_count + {31'd0, in_tvalid2 &  in_tlast & s_axis_2_tready};

        current_pkt_byte_count <= enabled_axis_eop ? 0 :
                                    enabled_axis_mop ? (current_pkt_byte_count + TKEEP_WIDTH) :
                                    enabled_axis     ? current_pkt_byte_count : 0;

        axis_pkt_in_reg    <= sample_axis & is_active_axis  ? pktin_count          : is_active_axis  ? axis_pkt_in_reg : 0;
        axis_bytesinlo_reg <= sample_axis & is_active_axis  ? bytesin_count[31:0]  : is_active_axis  ? axis_bytesinlo_reg : 0;
        axis_bytesinhi_reg <= sample_axis & is_active_axis  ? bytesin_count[63:32] : is_active_axis  ? axis_bytesinhi_reg : 0;
        axis_time_reg      <= sample_axis & is_active_axis  ? time_at_last_eop     : is_active_axis  ? axis_time_reg : 0;

        tick_ctr           <= tick_ctr + `TICK_BITS'd1;

      end

    // end axis_aclk clock domain
    //-------------------------------------------------------------------------------


endmodule
