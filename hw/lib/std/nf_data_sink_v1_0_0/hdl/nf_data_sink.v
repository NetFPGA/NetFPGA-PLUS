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
    parameter C_M_AXIS_DATA_WIDTH=512,
    parameter C_S_AXIS_DATA_WIDTH=512,
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

  localparam TKEEP_WIDTH = C_S_AXIS_DATA_WIDTH / 8;
  localparam VALID_COUNT_WIDTH = log2(TKEEP_WIDTH) + 1;

  function [VALID_COUNT_WIDTH-1:0] count_bytes_valid;
    input [TKEEP_WIDTH-1:0] valid_vector;
    integer i;
    begin
      count_bytes_valid = 0;
      for (i = 0 ; i < TKEEP_WIDTH; i = i + 1)
      begin
        count_bytes_valid = count_bytes_valid + valid_vector[i];
      end
    end
  endfunction // count_bytes_valid

// ------------ Internal Params --------

//   localparam  NUM_QUEUES_WIDTH = log2(NUM_QUEUES);


//   localparam NUM_STATES = 1;
//   localparam IDLE = 0;
//   localparam WR_PKT = 1;

//   localparam MAX_PKT_SIZE = 2000; // In bytes
//   localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

  // ------------- Regs/ wires -----------

  reg [C_M_AXIS_DATA_WIDTH-1:0]        in_tdata;
  reg [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_tkeep;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]       in_tuser;
  reg  	                              in_tvalid;
  reg                                  in_tlast;

//   wire [C_M_AXIS_TUSER_WIDTH-1:0]            fifo_out_tuser[NUM_QUEUES-1:0];
//   wire [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata[NUM_QUEUES-1:0];
//   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  fifo_out_tkeep[NUM_QUEUES-1:0];
//   wire [NUM_QUEUES-1:0] 	       fifo_out_tlast;
//   reg [NUM_QUEUES-1:0]                rd_en;

//   wire [NUM_QUEUES_WIDTH-1:0]         next_queue; //next non-empty queue
//   wire [NUM_QUEUES_WIDTH:0]       extended_next_queue; //extended non-empty queue, looking beyond the current array length
//   reg [NUM_QUEUES_WIDTH-1:0]          cur_queue;
//   reg [NUM_QUEUES_WIDTH-1:0]          cur_queue_next;

//   reg [NUM_STATES-1:0]                state;
//   reg [NUM_STATES-1:0]                state_next;

  reg      [`REG_ID_BITS]        id_reg;
  reg      [`REG_VERSION_BITS]   version_reg;
  wire     [`REG_RESET_BITS]     reset_reg;
  reg      [`REG_FLIP_BITS]      ip2cpu_flip_reg;
  wire     [`REG_FLIP_BITS]      cpu2ip_flip_reg;
  reg      [`REG_DEBUG_BITS]     ip2cpu_debug_reg;
  wire     [`REG_DEBUG_BITS]     cpu2ip_debug_reg;
  reg      [`REG_ENABLE_BITS]    ip2cpu_enable_reg;
  wire     [`REG_ENABLE_BITS]    cpu2ip_enable_reg;
  reg      [`REG_PKTIN_BITS]     pktin_reg;
  reg      [`REG_BYTESINLO_BITS] bytesinlo_reg;
  reg      [`REG_BYTESINHI_BITS] bytesinhi_reg;
  reg      [`REG_TIME_BITS]      time_reg;

  reg clear_counters;
  reg reset_registers;
  wire unused;
  reg enabled;
  reg sample_reg;
  reg sample_reg_d1;
  wire sample;
  assign sample = sample_reg & ~sample_reg_d1;  // rising edge sample.
  reg [63:0] bytesin_count;
  reg [31:0] pktin_count;
  reg[31:0] time_count;  // counts clocks since first active SOP
  reg[31:0] time_at_last_eop; // Time spent active. Updated ONLY at EOP.
  reg [31:0] total_pkt_count; // EVERY EOP seen

  wire enabled_sop; 
  wire enabled_mop;
  wire enabled_eop;

  wire [VALID_COUNT_WIDTH-1:0] number_of_last_bytes; // num bytes valid in tlast transaction.
  assign number_of_last_bytes = in_tlast ? count_bytes_valid(in_tkeep) : 0;

  reg active_reg; // 0 after enable. Goes 1 at first SOP after enabled.
  reg in_packet;  // 1 after SOP and before EOP.

  // current_pkt_byte_count keeps track of number of bytes received for current packet.
  // EOP is assumed to be true when tlast is asserted.
  reg [15:0] current_pkt_byte_count;

  // ------------ Modules -------------

  // ------------- Logic ------------

   always @(posedge axis_aclk) begin
      in_tdata       <= s_axis_2_tdata;
      in_tkeep       <= s_axis_2_tkeep;
      in_tuser       <= s_axis_2_tuser;
      in_tvalid      <= s_axis_2_tvalid;
      in_tlast       <= s_axis_2_tlast;
   end

  assign s_axis_2_tready = 1'b1; // always accept data

  assign enabled_sop = enabled & s_axis_2_tvalid & ~in_packet      & s_axis_2_tready;
  assign enabled_eop = enabled & s_axis_2_tvalid &  s_axis_2_tlast & s_axis_2_tready;
  assign enabled_mop = enabled & s_axis_2_tvalid & ~s_axis_2_tlast & s_axis_2_tready;


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
    .pktin_reg         (pktin_reg),
    .bytesinlo_reg     (bytesinlo_reg),
    .bytesinhi_reg     (bytesinhi_reg),
    .time_reg          (time_reg),

    // Global Registers - user can select if to use
    .cpu_resetn_soft(),//software reset, after cpu module
    .resetn_soft    (),//software reset to cpu module (from central reset management)
    .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
  );


  always @(posedge axis_aclk)

    if (~resetn_sync | reset_registers) begin
      id_reg            <= #1  `REG_ID_DEFAULT;
      version_reg       <= #1  `REG_VERSION_DEFAULT;
      ip2cpu_flip_reg   <= #1  `REG_FLIP_DEFAULT;
      ip2cpu_debug_reg  <= #1  `REG_DEBUG_DEFAULT;
      pktin_reg         <= #1  `REG_PKTIN_DEFAULT;
      ip2cpu_enable_reg <= {total_pkt_count[23:0], 3'd0, clear_counters, reset_registers, in_packet, active_reg, enabled};
      pktin_reg         <= #1  `REG_PKTIN_DEFAULT;
      bytesinlo_reg     <= #1  `REG_BYTESINLO_DEFAULT;
      bytesinhi_reg     <= #1  `REG_BYTESINHI_DEFAULT;
      time_reg          <= #1  `REG_TIME_DEFAULT;

      clear_counters    <= 1'b1;
      reset_registers   <= 1'b0;

      enabled          <= 1'b0;
      sample_reg       <= 1'd0;
      sample_reg_d1    <= 1'd0;
      bytesin_count    <= 64'd0;
      pktin_count      <= 0;
      time_count       <= 0;
      in_packet        <= 1'b0;
      active_reg       <= 1'b0;
      time_at_last_eop <= 0;
      total_pkt_count  <= 0;
      current_pkt_byte_count <= 0;
    end
    else begin
      id_reg            <= #1 `REG_ID_DEFAULT;
      version_reg       <= #1 `REG_VERSION_DEFAULT;
      ip2cpu_flip_reg   <= #1 ~cpu2ip_flip_reg;
      ip2cpu_debug_reg  <= #1 `REG_DEBUG_DEFAULT+cpu2ip_debug_reg;
      ip2cpu_enable_reg <= {total_pkt_count[23:0], 3'd0, clear_counters, reset_registers, in_packet, active_reg, enabled};

      enabled   <= cpu2ip_enable_reg[0];
      clear_counters    <= reset_reg[0];
      reset_registers   <= reset_reg[4];

      // do not go active in the middle of a packet - wait until end of current packet.
      in_packet  <= enabled_sop | (in_packet & ~enabled_eop);
      active_reg <= enabled & (active_reg | (~active_reg & enabled_sop));

      total_pkt_count <= total_pkt_count + {31'd0, s_axis_2_tvalid &  s_axis_2_tlast & s_axis_2_tready};

      // counters count when enabled.

      current_pkt_byte_count <= enabled_eop ? 0 :
                                enabled_mop ? (current_pkt_byte_count + TKEEP_WIDTH) :
                                enabled     ? current_pkt_byte_count : 0;

      pktin_count   <= pktin_count + {31'd0, active_reg  & enabled_eop};
      bytesin_count <= enabled_eop & active_reg  ? current_pkt_byte_count + number_of_last_bytes : 
                      active_reg                 ? bytesin_count : 64'd0;
      time_count    <= active_reg | enabled_sop ? time_count + 1 : enabled ? time_count : 0;

      time_at_last_eop <= (enabled_sop & ~active_reg) | enabled_eop ? time_count + 1 :
                           enabled ? time_at_last_eop : 0;

      pktin_reg     <= sample & active_reg  ? pktin_count          : active_reg  ? pktin_reg : 0;
      bytesinlo_reg <= sample & active_reg  ? bytesin_count[31:0]  : active_reg  ? bytesinlo_reg : 0;
      // bytesinhi_reg <= sample & active_reg  ? bytesin_count[63:32] : active_reg  ? bytesinhi_reg : 0;
      bytesinhi_reg <= total_pkt_count;
      time_reg      <= sample & active_reg  ? time_at_last_eop     : active_reg  ? time_reg : 0;
    end


endmodule
