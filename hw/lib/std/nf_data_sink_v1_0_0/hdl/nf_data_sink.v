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

  reg      [`REG_ID_BITS]       id_reg;
  reg      [`REG_VERSION_BITS]  version_reg;
  wire     [`REG_RESET_BITS]    reset_reg;
  reg      [`REG_FLIP_BITS]     p2cpu_flip_reg;
  wire     [`REG_FLIP_BITS]     cpu2ip_flip_reg;
  reg      [`REG_PKTIN_BITS]    pktin_reg;
  wire                          pktin_reg_clear;
  reg      [`REG_PKTSUM_BITS]   pktsum_reg;
  wire                          pktsum_reg_clear;
  reg      [`REG_DEBUG_BITS]    ip2cpu_debug_reg;
  wire     [`REG_DEBUG_BITS]    cpu2ip_debug_reg;

  wire clear_counters;
  wire reset_registers;
  wire unused;

  // ------------ Modules -------------

  // ------------- Logic ------------

   always @(posedge axi_aclk) begin
      in_tdata       <= s_axis_2_tdata;
      in_tkeep       <= s_axis_2_tkeep;
      in_tuser       <= s_axis_2_tuser;
      in_tvalid      <= s_axis_2_tvalid;
      in_tlast       <= s_axis_2_tlast;

      s_axis_2_tready <= 1'b1; // always accept data


   end



  //Find the next non-empty queue
  assign extended_empty = {empty,empty};
  assign extended_next_queue = !extended_empty[cur_queue+1] ? cur_queue+1 : 
                               !extended_empty[cur_queue+2] ? cur_queue+2 :
                               !extended_empty[cur_queue+3] ? cur_queue+3 :
                               cur_queue+1;
  assign {unused,next_queue} = (extended_next_queue > NUM_QUEUES-1) ? extended_next_queue - NUM_QUEUES : extended_next_queue; 

  assign m_axis_tuser = fifo_out_tuser[cur_queue];
  assign m_axis_tdata = fifo_out_tdata[cur_queue];
  assign m_axis_tlast = fifo_out_tlast[cur_queue];
  assign m_axis_tkeep = fifo_out_tkeep[cur_queue];
  assign m_axis_tvalid = ~empty[cur_queue];


  //Registers section
  nf_data_sink_cpu_regs 
  #(
    .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
    .C_BASE_ADDRESS    (C_BASEADDR)
  ) arbiter_cpu_regs_inst
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
    .pktin_reg        (pktin_reg),
    .pktin_reg_clear  (pktin_reg_clear),
    .pktsum_reg       (pktsum_reg),
    .pktsum_reg_clear (pktsum_reg_clear),
    .ip2cpu_debug_reg (ip2cpu_debug_reg),
    .cpu2ip_debug_reg (cpu2ip_debug_reg),
    
    // Global Registers - user can select if to use
    .cpu_resetn_soft(),//software reset, after cpu module
    .resetn_soft    (),//software reset to cpu module (from central reset management)
    .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
  );

  assign clear_counters = reset_reg[0];
  assign reset_registers = reset_reg[4];

  always @(posedge axis_aclk)
    if (~resetn_sync | reset_registers) begin
      id_reg           <= #1    `REG_ID_DEFAULT;
      version_reg      <= #1    `REG_VERSION_DEFAULT;
      ip2cpu_flip_reg  <= #1    `REG_FLIP_DEFAULT;
      pktin_reg        <= #1    `REG_PKTIN_DEFAULT;
      pktsum_reg       <= #1    `REG_PKTOUT_DEFAULT;
      ip2cpu_debug_reg <= #1    `REG_DEBUG_DEFAULT;
    end
    else begin
      id_reg          <= #1 `REG_ID_DEFAULT;
      version_reg     <= #1 `REG_VERSION_DEFAULT;
      ip2cpu_flip_reg <= #1 ~cpu2ip_flip_reg;
      pktin_reg       <= #1  clear_counters | pktin_reg_clear ? 'h0  : pktin_reg +  (in_tvalid & in_tlast & s_axis_2_tready);

      // Pktsum is just here to make sure data logic is not deleted in synthesis
      pktsum_reg      <= #1  clear_counters | pktsum_reg_clear ? 'h0  : pktsum_reg + (m_axis_tvalid && m_axis_tlast && m_axis_tready ) ? in_tdata[`REG_PKTSUM_BITS] : '0 ;

      ip2cpu_debug_reg <= #1 `REG_DEBUG_DEFAULT+cpu2ip_debug_reg;
    end



endmodule
