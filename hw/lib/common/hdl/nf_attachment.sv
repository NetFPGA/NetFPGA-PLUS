/*
 * Copyright (c) 2021 Yuta Tokusashi
 * All rights reserved.
 *
 * This software was developed by the University of Cambridge Computer
 * Laboratory under EPSRC EARL Project EP/P025374/1 alongside support 
 * from Xilinx Inc.
 *
 * @NETFPGA_LICENSE_HEADER_START@
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @NETFPGA_LICENSE_HEADER_END@
 *
 */
`timescale 1ps/1ps
module nf_attachment #(
	parameter C_NF_TDATA_WIDTH = 512,
	parameter C_NF_TUSER_WIDTH = 128,
	parameter C_TDATA_WIDTH    = 512,
	parameter C_TUSER_WIDTH    = 128
)(
	// Slave Stream Ports
	input [C_NF_TDATA_WIDTH-1:0]     axis_dma_o_tdata,
	input [(C_NF_TDATA_WIDTH/8)-1:0] axis_dma_o_tkeep,
	input [C_NF_TUSER_WIDTH-1:0]     axis_dma_o_tuser,
	input                            axis_dma_o_tvalid,
	output                           axis_dma_o_tready,
	input                            axis_dma_o_tlast, 
	
	// Master Stream Ports
	output [C_NF_TDATA_WIDTH-1:0]    axis_dma_i_tdata,
	output [(C_NF_TDATA_WIDTH/8)-1:0]axis_dma_i_tkeep,
	output [C_NF_TUSER_WIDTH-1:0]    axis_dma_i_tuser,
	output                           axis_dma_i_tvalid,
	input                            axis_dma_i_tready,
	output                           axis_dma_i_tlast, 

	// Slave Stream Ports
	input [C_NF_TDATA_WIDTH-1:0]     axis_o_0_tdata,
	input [(C_NF_TDATA_WIDTH/8)-1:0] axis_o_0_tkeep,
	input [C_NF_TUSER_WIDTH-1:0]     axis_o_0_tuser,
	input                            axis_o_0_tvalid,
	output                           axis_o_0_tready,
	input                            axis_o_0_tlast, 
	// Slave Stream Ports
	input [C_NF_TDATA_WIDTH-1:0]     axis_o_1_tdata,
	input [(C_NF_TDATA_WIDTH/8)-1:0] axis_o_1_tkeep,
	input [C_NF_TUSER_WIDTH-1:0]     axis_o_1_tuser,
	input                            axis_o_1_tvalid,
	output                           axis_o_1_tready,
	input                            axis_o_1_tlast, 
	// Master Stream Ports
	output [C_NF_TDATA_WIDTH-1:0]    axis_i_0_tdata,
	output [(C_NF_TDATA_WIDTH/8)-1:0]axis_i_0_tkeep,
	output [C_NF_TUSER_WIDTH-1:0]    axis_i_0_tuser,
	output                           axis_i_0_tvalid,
	input                            axis_i_0_tready,
	output                           axis_i_0_tlast, 
	// Master Stream Ports
	output [C_NF_TDATA_WIDTH-1:0]    axis_i_1_tdata,
	output [(C_NF_TDATA_WIDTH/8)-1:0]axis_i_1_tkeep,
	output [C_NF_TUSER_WIDTH-1:0]    axis_i_1_tuser,
	output                           axis_i_1_tvalid,
	input                            axis_i_1_tready,
	output                           axis_i_1_tlast, 

	input                            axis_cmac_0_rx_tvalid,
	input [C_TDATA_WIDTH-1:0]        axis_cmac_0_rx_tdata ,
	input [(C_TDATA_WIDTH/8)-1:0]    axis_cmac_0_rx_tkeep ,
	input                            axis_cmac_0_rx_tuser_err,
	input                            axis_cmac_0_rx_tlast ,

	input                            axis_cmac_1_rx_tvalid,
	input  [C_TDATA_WIDTH-1:0]       axis_cmac_1_rx_tdata ,
	input  [(C_TDATA_WIDTH/8)-1:0]   axis_cmac_1_rx_tkeep ,
	input                            axis_cmac_1_rx_tuser_err ,
	input                            axis_cmac_1_rx_tlast ,

	output                           axis_cmac_0_tx_tvalid,
	output [C_TDATA_WIDTH-1:0]       axis_cmac_0_tx_tdata ,
	output [(C_TDATA_WIDTH/8)-1:0]   axis_cmac_0_tx_tkeep ,
	output                           axis_cmac_0_tx_tuser_err ,
	output                           axis_cmac_0_tx_tlast ,
	input                            axis_cmac_0_tx_tready,

	output                           axis_cmac_1_tx_tvalid,
	output [C_TDATA_WIDTH-1:0]       axis_cmac_1_tx_tdata ,
	output [(C_TDATA_WIDTH/8)-1:0]   axis_cmac_1_tx_tkeep ,
	output                           axis_cmac_1_tx_tuser_err ,
	output                           axis_cmac_1_tx_tlast ,
	input                            axis_cmac_1_tx_tready,


	output                           s_axis_qdma_c2h_0_tvalid,
	output [511:0]                   s_axis_qdma_c2h_0_tdata ,
	output [63:0]                    s_axis_qdma_c2h_0_tkeep ,
	output                           s_axis_qdma_c2h_0_tlast ,
	output [15:0]                    s_axis_qdma_c2h_0_tuser_size,
	output [15:0]                    s_axis_qdma_c2h_0_tuser_src,
	output [15:0]                    s_axis_qdma_c2h_0_tuser_dst,
	input                            s_axis_qdma_c2h_0_tready,

	output                           s_axis_qdma_c2h_1_tvalid,
	output [511:0]                   s_axis_qdma_c2h_1_tdata ,
	output [63:0]                    s_axis_qdma_c2h_1_tkeep ,
	output                           s_axis_qdma_c2h_1_tlast ,
	output [15:0]                    s_axis_qdma_c2h_1_tuser_size,
	output [15:0]                    s_axis_qdma_c2h_1_tuser_src,
	output [15:0]                    s_axis_qdma_c2h_1_tuser_dst,
	input                            s_axis_qdma_c2h_1_tready,

	input                            m_axis_qdma_h2c_0_tvalid,
	input [511:0]                    m_axis_qdma_h2c_0_tdata ,
	input [63:0]                     m_axis_qdma_h2c_0_tkeep ,
	input                            m_axis_qdma_h2c_0_tlast ,
	input [15:0]                     m_axis_qdma_h2c_0_tuser_size,
	input [15:0]                     m_axis_qdma_h2c_0_tuser_src,
	input [15:0]                     m_axis_qdma_h2c_0_tuser_dst,
	output                           m_axis_qdma_h2c_0_tready,

	input                            m_axis_qdma_h2c_1_tvalid,
	input [511:0]                    m_axis_qdma_h2c_1_tdata ,
	input [63:0]                     m_axis_qdma_h2c_1_tkeep ,
	input                            m_axis_qdma_h2c_1_tlast ,
	input [15:0]                     m_axis_qdma_h2c_1_tuser_size,
	input [15:0]                     m_axis_qdma_h2c_1_tuser_src,
	input [15:0]                     m_axis_qdma_h2c_1_tuser_dst,
	output                           m_axis_qdma_h2c_1_tready,

	input                          m0_axil_awvalid,
	input                 [31:0]   m0_axil_awaddr,
	output                         m0_axil_awready,
	input                          m0_axil_wvalid,
	input                 [31:0]   m0_axil_wdata,
	output                         m0_axil_wready,
	output                         m0_axil_bvalid,
	output                   [1:0] m0_axil_bresp,
	input                          m0_axil_bready,
	input                          m0_axil_arvalid,
	input                 [31:0]   m0_axil_araddr,
	output                         m0_axil_arready,
	output                         m0_axil_rvalid,
	output                  [31:0] m0_axil_rdata,
	output                   [1:0] m0_axil_rresp,
	input                          m0_axil_rready,

	input [1:0]                      cmac_clk,
	input                            core_clk,
	input                            axis_aclk,
	input                            axil_aclk,
	output                           axis_rst,
	output                           axil_rst
);

  // Parameters
  localparam CMAC0_IFNUM = 8'b0000_0001;
  localparam CMAC1_IFNUM = 8'b0000_0100;
  localparam QDMA0_IFNUM = 8'b0000_0010;
  localparam QDMA1_IFNUM = 8'b0000_1000;

  localparam QDMA0_TDEST = 16'h0;
  localparam QDMA1_TDEST = 16'h1;

  localparam NF_TUSER_SRCPORT_START = 16;
  localparam NF_TUSER_SRCPORT_WIDTH = 8;
  localparam NF_TUSER_DSTPORT_START = 24;
  localparam NF_TUSER_DSTPORT_WIDTH = 8;

  localparam NF_TUSER_SRCPORT_CMAC0 = NF_TUSER_SRCPORT_START;
  localparam NF_TUSER_SRCPORT_CMAC1 = NF_TUSER_SRCPORT_START + 2;
  localparam NF_TUSER_SRCPORT_QDMA0 = NF_TUSER_SRCPORT_START + 1;
  localparam NF_TUSER_SRCPORT_QDMA1 = NF_TUSER_SRCPORT_START + 3;

  localparam NF_TUSER_DSTPORT_CMAC0 = NF_TUSER_DSTPORT_START;
  localparam NF_TUSER_DSTPORT_CMAC1 = NF_TUSER_DSTPORT_START + 2;
  localparam NF_TUSER_DSTPORT_QDMA0 = NF_TUSER_DSTPORT_START + 1;
  localparam NF_TUSER_DSTPORT_QDMA1 = NF_TUSER_DSTPORT_START + 3;

  // Reset
  reg [9:0] axis_rst_cnt = 10'd0;
  reg [9:0] axil_rst_cnt = 10'd0;
  reg [9:0] cmac0_rst_cnt = 10'd0;
  reg [9:0] cmac1_rst_cnt = 10'd0;
  reg [9:0] core_rst_cnt = 10'd0;
  reg       axis_rst_reg, axil_rst_reg, cmac0_rst_reg, cmac1_rst_reg;
  reg       core_rst_reg;
  assign axis_rst = axis_rst_reg;
  assign axil_rst = axil_rst_reg;
  wire   cmac0_rst = cmac0_rst_reg;
  wire   cmac1_rst = cmac1_rst_reg;
  wire   core_rst  = core_rst_reg;

  always @ (posedge cmac_clk[0]) begin
    if (cmac0_rst_cnt != 10'h3ff) begin
      cmac0_rst_cnt <= cmac0_rst_cnt + 10'd1;
      cmac0_rst_reg <= 1'b1;
    end
    else begin
      cmac0_rst_reg <= 1'b0;
    end
  end

  always @ (posedge cmac_clk[1]) begin
    if (cmac1_rst_cnt != 10'h3ff) begin
      cmac1_rst_cnt <= cmac1_rst_cnt + 10'd1;
      cmac1_rst_reg <= 1'b1;
    end
    else begin
      cmac1_rst_reg <= 1'b0;
    end
  end

  always @ (posedge axis_aclk) begin
    if (axis_rst_cnt != 10'h3ff) begin
      axis_rst_cnt <= axis_rst_cnt + 10'd1;
      axis_rst_reg <= 1'b1;
    end
    else begin
      axis_rst_reg <= 1'b0;
    end
  end

  always @ (posedge axil_aclk) begin
    if (axil_rst_cnt != 10'h3ff) begin
      axil_rst_cnt <= axil_rst_cnt + 10'd1;
      axil_rst_reg <= 1'b1;
    end
    else begin
      axil_rst_reg <= 1'b0;
    end
  end

  always @ (posedge core_clk) begin
    if (core_rst_cnt != 10'h3ff) begin
      core_rst_cnt <= core_rst_cnt + 10'd1;
      core_rst_reg <= 1'b1;
    end
    else begin
      core_rst_reg <= 1'b0;
    end
  end

  wire             S2_AXI_ACLK,     S1_AXI_ACLK,     S0_AXI_ACLK;
  wire             S2_AXI_ARESETN,  S1_AXI_ARESETN,  S0_AXI_ARESETN;
  wire[31 : 0]     S2_AXI_AWADDR,   S1_AXI_AWADDR,   S0_AXI_AWADDR;
  wire             S2_AXI_AWVALID,  S1_AXI_AWVALID,  S0_AXI_AWVALID;
  wire[31 : 0]     S2_AXI_WDATA,    S1_AXI_WDATA,    S0_AXI_WDATA;
  wire[3  : 0]     S2_AXI_WSTRB,    S1_AXI_WSTRB,    S0_AXI_WSTRB;
  wire             S2_AXI_WVALID,   S1_AXI_WVALID,   S0_AXI_WVALID;
  wire             S2_AXI_BREADY,   S1_AXI_BREADY,   S0_AXI_BREADY;
  wire[31 : 0]     S2_AXI_ARADDR,   S1_AXI_ARADDR,   S0_AXI_ARADDR;
  wire             S2_AXI_ARVALID,  S1_AXI_ARVALID,  S0_AXI_ARVALID;
  wire             S2_AXI_RREADY,   S1_AXI_RREADY,   S0_AXI_RREADY;
  wire             S2_AXI_ARREADY,  S1_AXI_ARREADY,  S0_AXI_ARREADY;
  wire[31 : 0]     S2_AXI_RDATA,    S1_AXI_RDATA,    S0_AXI_RDATA;
  wire[1 : 0]      S2_AXI_RRESP,    S1_AXI_RRESP,    S0_AXI_RRESP;
  wire             S2_AXI_RVALID,   S1_AXI_RVALID,   S0_AXI_RVALID;
  wire             S2_AXI_WREADY,   S1_AXI_WREADY,   S0_AXI_WREADY;
  wire[1 :0]       S2_AXI_BRESP,    S1_AXI_BRESP,    S0_AXI_BRESP;
  wire             S2_AXI_BVALID,   S1_AXI_BVALID,   S0_AXI_BVALID;
  wire             S2_AXI_AWREADY,  S1_AXI_AWREADY,  S0_AXI_AWREADY;

  axi_crossbar_0 u_crossbar_m0 (
    .aclk          (axil_aclk),
    .aresetn       (!axil_rst),
    .s_axi_awaddr  (m0_axil_awaddr ),
    .s_axi_awprot  (),
    .s_axi_awvalid (m0_axil_awvalid),
    .s_axi_awready (m0_axil_awready),
    .s_axi_wdata   (m0_axil_wdata  ),
    .s_axi_wstrb   (4'b1111),
    .s_axi_wvalid  (m0_axil_wvalid ),
    .s_axi_wready  (m0_axil_wready ),
    .s_axi_bresp   (m0_axil_bresp  ),
    .s_axi_bvalid  (m0_axil_bvalid ),
    .s_axi_bready  (m0_axil_bready ),
    .s_axi_araddr  (m0_axil_araddr),
    .s_axi_arprot  (),
    .s_axi_arvalid (m0_axil_arvalid ),
    .s_axi_arready (m0_axil_arready ),
    .s_axi_rdata   (m0_axil_rdata   ),
    .s_axi_rresp   (m0_axil_rresp   ),
    .s_axi_rvalid  (m0_axil_rvalid  ),
    .s_axi_rready  (m0_axil_rready  ),
    .m_axi_awaddr  ({S2_AXI_AWADDR ,S1_AXI_AWADDR ,S0_AXI_AWADDR }),
    .m_axi_awprot  (),
    .m_axi_awvalid ({S2_AXI_AWVALID,S1_AXI_AWVALID,S0_AXI_AWVALID}),
    .m_axi_awready ({S2_AXI_AWREADY,S1_AXI_AWREADY,S0_AXI_AWREADY}),
    .m_axi_wdata   ({S2_AXI_WDATA  ,S1_AXI_WDATA  ,S0_AXI_WDATA  }),
    .m_axi_wstrb   ({S2_AXI_WSTRB  ,S1_AXI_WSTRB  ,S0_AXI_WSTRB  }),
    .m_axi_wvalid  ({S2_AXI_WVALID ,S1_AXI_WVALID ,S0_AXI_WVALID }),
    .m_axi_wready  ({S2_AXI_WREADY ,S1_AXI_WREADY ,S0_AXI_WREADY }),
    .m_axi_bresp   ({S2_AXI_BRESP  ,S1_AXI_BRESP  ,S0_AXI_BRESP  }),
    .m_axi_bvalid  ({S2_AXI_BVALID ,S1_AXI_BVALID ,S0_AXI_BVALID }),
    .m_axi_bready  ({S2_AXI_BREADY ,S1_AXI_BREADY ,S0_AXI_BREADY }),
    .m_axi_araddr  ({S2_AXI_ARADDR ,S1_AXI_ARADDR ,S0_AXI_ARADDR }),
    .m_axi_arprot  (),
    .m_axi_arvalid ({S2_AXI_ARVALID,S1_AXI_ARVALID,S0_AXI_ARVALID}),
    .m_axi_arready ({S2_AXI_ARREADY,S1_AXI_ARREADY,S0_AXI_ARREADY}),
    .m_axi_rdata   ({S2_AXI_RDATA  ,S1_AXI_RDATA  ,S0_AXI_RDATA  }),
    .m_axi_rresp   ({S2_AXI_RRESP  ,S1_AXI_RRESP  ,S0_AXI_RRESP  }),
    .m_axi_rvalid  ({S2_AXI_RVALID ,S1_AXI_RVALID ,S0_AXI_RVALID }),
    .m_axi_rready  ({S2_AXI_RREADY ,S1_AXI_RREADY ,S0_AXI_RREADY }) 
  );
  wire  [C_TDATA_WIDTH-1:0]      axis_dma_conv_o_tdata , axis_dma_conv_i_tdata ;
  wire  [C_TDATA_WIDTH/8-1:0]    axis_dma_conv_o_tkeep , axis_dma_conv_i_tkeep ;
  wire                           axis_dma_conv_o_tlast , axis_dma_conv_i_tlast ;
  wire                           axis_dma_conv_o_tready, axis_dma_conv_i_tready;
  wire  [C_TUSER_WIDTH-1:0]      axis_dma_conv_o_tuser , axis_dma_conv_i_tuser ;
  wire                           axis_dma_conv_o_tvalid, axis_dma_conv_i_tvalid;
  wire [15:0]                    axis_dma_conv_o_tuser_size, axis_dma_conv_i_tuser_size;
  wire [15:0]                    axis_dma_conv_o_tuser_src , axis_dma_conv_i_tuser_src ;
  wire [15:0]                    axis_dma_conv_o_tuser_dst , axis_dma_conv_i_tuser_dst ;
  
  nf_mac_attachment_dma_ip u_nf_attachment_dma (
    .S_AXI_ACLK            (axil_aclk),
    .S_AXI_ARESETN         (!axil_rst),
    .S_AXI_AWADDR          (S2_AXI_AWADDR),
    .S_AXI_AWVALID         (S2_AXI_AWVALID),
    .S_AXI_WDATA           (S2_AXI_WDATA),
    .S_AXI_WSTRB           (S2_AXI_WSTRB),
    .S_AXI_WVALID          (S2_AXI_WVALID),
    .S_AXI_BREADY          (S2_AXI_BREADY),
    .S_AXI_ARADDR          (S2_AXI_ARADDR),
    .S_AXI_ARVALID         (S2_AXI_ARVALID),
    .S_AXI_RREADY          (S2_AXI_RREADY),
    .S_AXI_ARREADY         (S2_AXI_ARREADY),
    .S_AXI_RDATA           (S2_AXI_RDATA),
    .S_AXI_RRESP           (S2_AXI_RRESP),
    .S_AXI_RVALID          (S2_AXI_RVALID),
    .S_AXI_WREADY          (S2_AXI_WREADY),
    .S_AXI_BRESP           (S2_AXI_BRESP),
    .S_AXI_BVALID          (S2_AXI_BVALID),
    .S_AXI_AWREADY         (S2_AXI_AWREADY),
    // 10GE block clk & rst
    .clk156                (axis_aclk),
    .areset_clk156         (axis_rst),
    // RX MAC 64b@clk156 (no backpressure) -> rx_queue 64b@axis_clk
    .m_axis_mac_tdata      (axis_dma_conv_i_tdata),
    .m_axis_mac_tkeep      (axis_dma_conv_i_tkeep),
    .m_axis_mac_tvalid     (axis_dma_conv_i_tvalid),
    .m_axis_mac_tuser_err  (1'b1),   // valid frame
    .m_axis_mac_tuser      (axis_dma_conv_i_tuser),
    .m_axis_mac_tlast      (axis_dma_conv_i_tlast),
    // tx_queue 64b@axis_clk -> mac 64b@clk156
    .s_axis_mac_tdata      (axis_dma_conv_o_tdata),
    .s_axis_mac_tkeep      (axis_dma_conv_o_tkeep),
    .s_axis_mac_tvalid     (axis_dma_conv_o_tvalid),
    .s_axis_mac_tuser_err  (),       //underrun
    .s_axis_mac_tuser      (axis_dma_conv_o_tuser),
    .s_axis_mac_tlast      (axis_dma_conv_o_tlast),
    .s_axis_mac_tready     (axis_dma_conv_o_tready),

    // TX/RX DATA channels
    .interface_number      (8'd0),

    // NFPLUS pipeline clk & rst
    .axis_aclk             (core_clk),
    .axis_aresetn          (!core_rst),
    // input from ref pipeline 256b -> MAC
    .s_axis_pipe_tdata     (axis_dma_o_tdata),
    .s_axis_pipe_tkeep     (axis_dma_o_tkeep),
    .s_axis_pipe_tlast     (axis_dma_o_tlast),
    .s_axis_pipe_tuser     (axis_dma_o_tuser),
    .s_axis_pipe_tvalid    (axis_dma_o_tvalid),
    .s_axis_pipe_tready    (axis_dma_o_tready),
    // output to ref pipeline 256b -> DMA
    .m_axis_pipe_tdata     (axis_dma_i_tdata),
    .m_axis_pipe_tkeep     (axis_dma_i_tkeep),
    .m_axis_pipe_tlast     (axis_dma_i_tlast),
    .m_axis_pipe_tuser     (axis_dma_i_tuser),
    .m_axis_pipe_tvalid    (axis_dma_i_tvalid),
    .m_axis_pipe_tready    (axis_dma_i_tready)
  );

  nf_mac_attachment_ip u_nf_attachment_0 (
    .S_AXI_ACLK             (axil_aclk),
    .S_AXI_ARESETN          (!axil_rst),
    .S_AXI_AWADDR           (S0_AXI_AWADDR),
    .S_AXI_AWVALID          (S0_AXI_AWVALID),
    .S_AXI_WDATA            (S0_AXI_WDATA),
    .S_AXI_WSTRB            (S0_AXI_WSTRB),
    .S_AXI_WVALID           (S0_AXI_WVALID),
    .S_AXI_BREADY           (S0_AXI_BREADY),
    .S_AXI_ARADDR           (S0_AXI_ARADDR),
    .S_AXI_ARVALID          (S0_AXI_ARVALID),
    .S_AXI_RREADY           (S0_AXI_RREADY),
    .S_AXI_ARREADY          (S0_AXI_ARREADY),
    .S_AXI_RDATA            (S0_AXI_RDATA),
    .S_AXI_RRESP            (S0_AXI_RRESP),
    .S_AXI_RVALID           (S0_AXI_RVALID),
    .S_AXI_WREADY           (S0_AXI_WREADY),
    .S_AXI_BRESP            (S0_AXI_BRESP),
    .S_AXI_BVALID           (S0_AXI_BVALID),
    .S_AXI_AWREADY          (S0_AXI_AWREADY),
    // 10GE block clk & rst 
    .clk156                (cmac_clk[0]),  
    .areset_clk156         (cmac0_rst), 
    // RX MAC 64b@clk156 (no backpressure) -> rx_queue 64b@axis_clk
    .m_axis_mac_tdata      (axis_cmac_0_rx_tdata),
    .m_axis_mac_tkeep      (axis_cmac_0_rx_tkeep),
    .m_axis_mac_tvalid     (axis_cmac_0_rx_tvalid),
    .m_axis_mac_tuser_err  (!axis_cmac_0_rx_tuser_err),       // valid frame
    .m_axis_mac_tuser      (),
    .m_axis_mac_tlast      (axis_cmac_0_rx_tlast),
    // tx_queue 64b@axis_clk -> mac 64b@clk156
    .s_axis_mac_tdata      (axis_cmac_0_tx_tdata),
    .s_axis_mac_tkeep      (axis_cmac_0_tx_tkeep),
    .s_axis_mac_tvalid     (axis_cmac_0_tx_tvalid),
    .s_axis_mac_tuser_err  (axis_cmac_0_tx_tuser_err),      //underrun
    .s_axis_mac_tuser      (),      //underrun
    .s_axis_mac_tlast      (axis_cmac_0_tx_tlast),
    .s_axis_mac_tready     (axis_cmac_0_tx_tready),

    // TX/RX DATA channels  
    .interface_number      (CMAC0_IFNUM),

    // NFPLUS pipeline clk & rst 
    .axis_aclk             (core_clk),
    .axis_aresetn          (!core_rst),
    // input from ref pipeline 256b -> MAC
    .s_axis_pipe_tdata     (axis_o_0_tdata),
    .s_axis_pipe_tkeep     (axis_o_0_tkeep),
    .s_axis_pipe_tlast     (axis_o_0_tlast),
    .s_axis_pipe_tuser     (axis_o_0_tuser),
    .s_axis_pipe_tvalid    (axis_o_0_tvalid),
    .s_axis_pipe_tready    (axis_o_0_tready),
    // output to ref pipeline 256b -> DMA
    .m_axis_pipe_tdata     (axis_i_0_tdata),
    .m_axis_pipe_tkeep     (axis_i_0_tkeep),
    .m_axis_pipe_tlast     (axis_i_0_tlast),
    .m_axis_pipe_tuser     (axis_i_0_tuser),
    .m_axis_pipe_tvalid    (axis_i_0_tvalid),
    .m_axis_pipe_tready    (axis_i_0_tready)
  );

  nf_mac_attachment_ip u_nf_attachment_1 (
    .S_AXI_ACLK            (axil_aclk),
    .S_AXI_ARESETN         (!axil_rst),
    .S_AXI_AWADDR          (S1_AXI_AWADDR),
    .S_AXI_AWVALID         (S1_AXI_AWVALID),
    .S_AXI_WDATA           (S1_AXI_WDATA),
    .S_AXI_WSTRB           (S1_AXI_WSTRB),
    .S_AXI_WVALID          (S1_AXI_WVALID),
    .S_AXI_BREADY          (S1_AXI_BREADY),
    .S_AXI_ARADDR          (S1_AXI_ARADDR),
    .S_AXI_ARVALID         (S1_AXI_ARVALID),
    .S_AXI_RREADY          (S1_AXI_RREADY),
    .S_AXI_ARREADY         (S1_AXI_ARREADY),
    .S_AXI_RDATA           (S1_AXI_RDATA),
    .S_AXI_RRESP           (S1_AXI_RRESP),
    .S_AXI_RVALID          (S1_AXI_RVALID),
    .S_AXI_WREADY          (S1_AXI_WREADY),
    .S_AXI_BRESP           (S1_AXI_BRESP),
    .S_AXI_BVALID          (S1_AXI_BVALID),
    .S_AXI_AWREADY         (S1_AXI_AWREADY),
    // 10GE block clk & rst
    .clk156                (cmac_clk[1]),  
    .areset_clk156         (cmac1_rst), 
    // RX MAC 64b@clk156 (no backpressure) -> rx_queue 64b@axis_clk
    .m_axis_mac_tdata      (axis_cmac_1_rx_tdata),
    .m_axis_mac_tkeep      (axis_cmac_1_rx_tkeep),
    .m_axis_mac_tvalid     (axis_cmac_1_rx_tvalid),
    .m_axis_mac_tuser_err  (!axis_cmac_1_rx_tuser_err),       // valid frame
    .m_axis_mac_tuser      (),
    .m_axis_mac_tlast      (axis_cmac_1_rx_tlast),
    // tx_queue 64b@axis_clk -> mac 64b@clk156
    .s_axis_mac_tdata      (axis_cmac_1_tx_tdata),
    .s_axis_mac_tkeep      (axis_cmac_1_tx_tkeep),
    .s_axis_mac_tvalid     (axis_cmac_1_tx_tvalid),
    .s_axis_mac_tuser_err  (axis_cmac_1_tx_tuser_err),      //underrun
    .s_axis_mac_tuser      (),      //underrun
    .s_axis_mac_tlast      (axis_cmac_1_tx_tlast),
    .s_axis_mac_tready     (axis_cmac_1_tx_tready),

    // TX/RX DATA channels  
    .interface_number      (CMAC1_IFNUM),

    // NFPLUS pipeline clk & rst 
    .axis_aclk             (core_clk),
    .axis_aresetn          (!core_rst),
    // input from ref pipeline 256b -> MAC
    .s_axis_pipe_tdata     (axis_o_1_tdata),
    .s_axis_pipe_tkeep     (axis_o_1_tkeep),
    .s_axis_pipe_tlast     (axis_o_1_tlast),
    .s_axis_pipe_tuser     (axis_o_1_tuser),
    .s_axis_pipe_tvalid    (axis_o_1_tvalid),
    .s_axis_pipe_tready    (axis_o_1_tready),
    // output to ref pipeline 256b -> DMA
    .m_axis_pipe_tdata     (axis_i_1_tdata),
    .m_axis_pipe_tkeep     (axis_i_1_tkeep),
    .m_axis_pipe_tlast     (axis_i_1_tlast),
    .m_axis_pipe_tuser     (axis_i_1_tuser),
    .m_axis_pipe_tvalid    (axis_i_1_tvalid),
    .m_axis_pipe_tready    (axis_i_1_tready)
  );

  reg arb_0, arb_1;
  reg arb_0_reg, arb_1_reg;

  assign       axis_dma_conv_i_tvalid  = (arb_0) ? m_axis_qdma_h2c_0_tvalid : m_axis_qdma_h2c_1_tvalid;
  assign       axis_dma_conv_i_tdata   = (arb_0) ? m_axis_qdma_h2c_0_tdata  : m_axis_qdma_h2c_1_tdata;
  assign       axis_dma_conv_i_tkeep   = (arb_0) ? m_axis_qdma_h2c_0_tkeep  : m_axis_qdma_h2c_1_tkeep;
  assign       axis_dma_conv_i_tlast   = (arb_0) ? m_axis_qdma_h2c_0_tlast  : m_axis_qdma_h2c_1_tlast;

  assign       axis_dma_conv_i_tuser[15:0]  = (arb_0) ? m_axis_qdma_h2c_0_tuser_size : m_axis_qdma_h2c_1_tuser_size;
  assign       axis_dma_conv_i_tuser[23:16] = (arb_0) ? QDMA0_IFNUM /*m_axis_qdma_h2c_0_tuser_src[7:0]*/ : QDMA1_IFNUM/*m_axis_qdma_h2c_1_tuser_src[7:0]*/;
  assign       axis_dma_conv_i_tuser[31:24] = 0;//(arb_0) ? m_axis_qdma_h2c_0_tuser_dst[7:0] : m_axis_qdma_h2c_1_tuser_dst[7:0];
  assign       axis_dma_conv_i_tuser[127:32] = 0;

  reg last_flip0, last_flip1;

  always @(*) begin
    arb_0 = arb_0_reg;
    arb_1 = arb_1_reg;

    if (last_flip0) begin
      arb_0 = 0;
    end
    if (m_axis_qdma_h2c_0_tvalid && arb_1 == 0) begin
      arb_0 = 1;
    end

    if (last_flip1) begin
      arb_1 = 0;
    end
    if (m_axis_qdma_h2c_1_tvalid && arb_0 == 0) begin
      arb_1 = 1;
    end
  end

  always @(posedge axis_aclk) begin
    if (axis_rst) begin
      arb_0_reg  <= 0;
      arb_1_reg  <= 0;
      last_flip0 <= 0;
      last_flip1 <= 0;
    end
    else begin
      arb_0_reg  <= arb_0;
      arb_1_reg  <= arb_1;
      last_flip0 <= m_axis_qdma_h2c_0_tvalid && m_axis_qdma_h2c_0_tlast;
      last_flip1 <= m_axis_qdma_h2c_1_tvalid && m_axis_qdma_h2c_1_tlast;
    end
  end

  reg [15:0] s_axis_qdma_c2h_0_tuser_size_r, s_axis_qdma_c2h_0_tuser_size_d;
  reg [15:0] s_axis_qdma_c2h_1_tuser_size_r, s_axis_qdma_c2h_1_tuser_size_d;
  reg [15:0] s_axis_qdma_c2h_0_tuser_dst_r , s_axis_qdma_c2h_0_tuser_dst_d;
  reg [15:0] s_axis_qdma_c2h_1_tuser_dst_r , s_axis_qdma_c2h_1_tuser_dst_d;
  localparam IDLE = 0;
  localparam PKT  = 1;
  reg state, state_next;

  always @(*) begin
    s_axis_qdma_c2h_0_tuser_size_r = s_axis_qdma_c2h_0_tuser_size_d;
    s_axis_qdma_c2h_1_tuser_size_r = s_axis_qdma_c2h_1_tuser_size_d;
    s_axis_qdma_c2h_0_tuser_dst_r = s_axis_qdma_c2h_0_tuser_dst_d;
    s_axis_qdma_c2h_1_tuser_dst_r = s_axis_qdma_c2h_1_tuser_dst_d;
    state_next = state;

    case(state)
    IDLE: begin
      if (axis_dma_conv_o_tvalid && axis_dma_conv_o_tready) begin
        if (axis_dma_conv_o_tuser_dst[1]) begin
          s_axis_qdma_c2h_0_tuser_size_r = axis_dma_conv_o_tuser_size;
          s_axis_qdma_c2h_0_tuser_dst_r = 16'b0000_0000_0000_0001;
        end
        if (axis_dma_conv_o_tuser_dst[3]) begin
          s_axis_qdma_c2h_1_tuser_size_r = axis_dma_conv_o_tuser_size;
          s_axis_qdma_c2h_1_tuser_dst_r = 16'b0000_0000_0000_0010;
        end
        if (axis_dma_conv_o_tlast)
          state_next = IDLE;
        else
          state_next = PKT;
      end
    end
    PKT: begin
      if (axis_dma_conv_o_tvalid && axis_dma_conv_o_tready) begin
        if (axis_dma_conv_o_tlast)
          state_next = IDLE;
        else
          state_next = PKT;
      end
    end
    default:;
    endcase
  end

  always @(posedge axis_aclk) begin
    if (axis_rst) begin
      state  <= 0;
      s_axis_qdma_c2h_0_tuser_size_d <= 0;
      s_axis_qdma_c2h_1_tuser_size_d <= 0;
      s_axis_qdma_c2h_0_tuser_dst_d <= 0;
      s_axis_qdma_c2h_1_tuser_dst_d <= 0;
    end
    else begin
      state  <= state_next;
      s_axis_qdma_c2h_0_tuser_size_d <= s_axis_qdma_c2h_0_tuser_size_r;
      s_axis_qdma_c2h_1_tuser_size_d <= s_axis_qdma_c2h_1_tuser_size_r;
      s_axis_qdma_c2h_0_tuser_dst_d <= s_axis_qdma_c2h_0_tuser_dst_r;
      s_axis_qdma_c2h_1_tuser_dst_d <= s_axis_qdma_c2h_1_tuser_dst_r;
    end
  end

  assign s_axis_qdma_c2h_0_tvalid     = (axis_dma_conv_o_tuser_dst[1]) ? axis_dma_conv_o_tvalid : 1'b0;
  assign s_axis_qdma_c2h_0_tlast      = axis_dma_conv_o_tlast;
  assign s_axis_qdma_c2h_0_tdata      = axis_dma_conv_o_tdata;
  assign s_axis_qdma_c2h_0_tkeep      = axis_dma_conv_o_tkeep;
  //assign s_axis_qdma_c2h_0_tuser_size = axis_dma_conv_o_tuser_size;
  assign s_axis_qdma_c2h_0_tuser_size = s_axis_qdma_c2h_0_tuser_size_r;
  assign s_axis_qdma_c2h_0_tuser_src  = axis_dma_conv_o_tuser_src;
  assign s_axis_qdma_c2h_0_tuser_dst = s_axis_qdma_c2h_0_tuser_dst_r;
  //assign s_axis_qdma_c2h_0_tuser_dst  = (axis_dma_conv_o_tuser_dst == {8'd0, QDMA0_IFNUM}) ? 16'b01 :
  //                                      (axis_dma_conv_o_tuser_dst == {8'd0, QDMA1_IFNUM}) ? 16'b10 : 16'd0;

  assign s_axis_qdma_c2h_1_tvalid     = (axis_dma_conv_o_tuser_dst[3]) ? axis_dma_conv_o_tvalid : 1'b0;
  assign s_axis_qdma_c2h_1_tlast      = axis_dma_conv_o_tlast;
  assign s_axis_qdma_c2h_1_tkeep      = axis_dma_conv_o_tkeep;
  assign s_axis_qdma_c2h_1_tdata      = axis_dma_conv_o_tdata;
  //assign s_axis_qdma_c2h_1_tuser_size = axis_dma_conv_o_tuser_size;
  assign s_axis_qdma_c2h_1_tuser_size = s_axis_qdma_c2h_1_tuser_size_r;
  assign s_axis_qdma_c2h_1_tuser_src  = axis_dma_conv_o_tuser_src;
  assign s_axis_qdma_c2h_1_tuser_dst = s_axis_qdma_c2h_1_tuser_dst_r;
  //assign s_axis_qdma_c2h_1_tuser_dst  = (axis_dma_conv_o_tuser_dst == {8'd0, QDMA0_IFNUM}) ? 16'b01 :
  //                                      (axis_dma_conv_o_tuser_dst == {8'd0, QDMA1_IFNUM}) ? 16'b10 : 16'd0;
  assign axis_dma_conv_o_tready = s_axis_qdma_c2h_0_tready && s_axis_qdma_c2h_1_tready;

  // todo
  assign       m_axis_qdma_h2c_0_tready = 1'b1;
  assign       m_axis_qdma_h2c_1_tready = 1'b1;

  // ToDo : broadcast to DMA ? or fixed direction?
  assign axis_dma_conv_o_tuser_size = axis_dma_conv_o_tuser[15:0];
  assign axis_dma_conv_o_tuser_src  = {8'h0, axis_dma_conv_o_tuser[23:16]};
  assign axis_dma_conv_o_tuser_dst  = {8'h0, axis_dma_conv_o_tuser[31:24]};

endmodule
