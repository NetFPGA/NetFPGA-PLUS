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
module top_wrapper #(
	parameter C_NF_TDATA_WIDTH = 512,
	parameter C_NF_TUSER_WIDTH = 128,
	parameter C_TDATA_WIDTH    = 512,
	parameter C_TUSER_WIDTH    = 128
)(
	// QSFP port0
	input  [3:0]                  qsfp0_rxp,
	input  [3:0]                  qsfp0_rxn,
	output [3:0]                  qsfp0_txp,
	output [3:0]                  qsfp0_txn,
	// QSFP port1
	input  [3:0]                  qsfp1_rxp,
	input  [3:0]                  qsfp1_rxn,
	output [3:0]                  qsfp1_txp,
	output [3:0]                  qsfp1_txn,
	// QSFP CLK0
	input                         qsfp0_clk_p,
	input                         qsfp0_clk_n,
	// QSFP CLK1
	input                         qsfp1_clk_p,
	input                         qsfp1_clk_n,

	output [15:0]                 pcie_txp,
	output [15:0]                 pcie_txn,
	input  [15:0]                 pcie_rxp,
	input  [15:0]                 pcie_rxn,
	// PCIe CLK
	input                         pcie_clk_p,
	input                         pcie_clk_n,
	input                         pcie_rst_n,

	output                        m_axil_awvalid,
	output                 [31:0] m_axil_awaddr,
	input                         m_axil_awready,
	output                        m_axil_wvalid,
	output                 [31:0] m_axil_wdata,
	input                         m_axil_wready,
	input                         m_axil_bvalid,
	input                   [1:0] m_axil_bresp,
	output                        m_axil_bready,
	output                        m_axil_arvalid,
	output                 [31:0] m_axil_araddr,
	input                         m_axil_arready,
	input                         m_axil_rvalid,
	input                  [31:0] m_axil_rdata,
	input                   [1:0] m_axil_rresp,
	output                        m_axil_rready,
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

	input                         core_clk,
	output                        axis_aclk,
	output                        axil_aclk,
	output                        axis_rst,
	output                        axil_rst
);

  wire [1:0] cmac_clk;

  wire                            axis_cmac_0_rx_tvalid, axis_cmac_1_rx_tvalid;
  wire [C_TDATA_WIDTH-1:0]        axis_cmac_0_rx_tdata , axis_cmac_1_rx_tdata ;
  wire [(C_TDATA_WIDTH/8)-1:0]    axis_cmac_0_rx_tkeep , axis_cmac_1_rx_tkeep ;
  wire                            axis_cmac_0_rx_tuser_err , axis_cmac_1_rx_tuser_err ;
  wire                            axis_cmac_0_rx_tlast , axis_cmac_1_rx_tlast ;

  wire                            axis_cmac_0_tx_tvalid, axis_cmac_1_tx_tvalid;
  wire [C_TDATA_WIDTH-1:0]        axis_cmac_0_tx_tdata , axis_cmac_1_tx_tdata ;
  wire [(C_TDATA_WIDTH/8)-1:0]    axis_cmac_0_tx_tkeep , axis_cmac_1_tx_tkeep ;
  wire                            axis_cmac_0_tx_tuser_err , axis_cmac_1_tx_tuser_err ;
  wire                            axis_cmac_0_tx_tlast , axis_cmac_1_tx_tlast ;
  wire                            axis_cmac_0_tx_tready , axis_cmac_1_tx_tready ;

  wire                            s_axis_qdma_c2h_0_tvalid, s_axis_qdma_c2h_1_tvalid;
  wire [511:0]                    s_axis_qdma_c2h_0_tdata , s_axis_qdma_c2h_1_tdata ;
  wire [63:0]                     s_axis_qdma_c2h_0_tkeep , s_axis_qdma_c2h_1_tkeep ;
  wire                            s_axis_qdma_c2h_0_tlast , s_axis_qdma_c2h_1_tlast ;
  wire [15:0]                     s_axis_qdma_c2h_0_tuser_size, s_axis_qdma_c2h_1_tuser_size;
  wire [15:0]                     s_axis_qdma_c2h_0_tuser_src, s_axis_qdma_c2h_1_tuser_src;
  wire [15:0]                     s_axis_qdma_c2h_0_tuser_dst, s_axis_qdma_c2h_1_tuser_dst;
  wire                            s_axis_qdma_c2h_0_tready, s_axis_qdma_c2h_1_tready;

  wire                            m_axis_qdma_h2c_0_tvalid, m_axis_qdma_h2c_1_tvalid;
  wire [511:0]                    m_axis_qdma_h2c_0_tdata , m_axis_qdma_h2c_1_tdata ;
  wire [63:0]                     m_axis_qdma_h2c_0_tkeep , m_axis_qdma_h2c_1_tkeep ;
  wire                            m_axis_qdma_h2c_0_tlast , m_axis_qdma_h2c_1_tlast ;
  wire [15:0]                     m_axis_qdma_h2c_0_tuser_size, m_axis_qdma_h2c_1_tuser_size;
  wire [15:0]                     m_axis_qdma_h2c_0_tuser_src, m_axis_qdma_h2c_1_tuser_src;
  wire [15:0]                     m_axis_qdma_h2c_0_tuser_dst, m_axis_qdma_h2c_1_tuser_dst;
  wire                            m_axis_qdma_h2c_0_tready, m_axis_qdma_h2c_1_tready;

  wire                     m0_axil_awvalid;
  wire              [31:0] m0_axil_awaddr;
  wire                     m0_axil_awready;
  wire                     m0_axil_wvalid;
  wire              [31:0] m0_axil_wdata;
  wire                     m0_axil_wready;
  wire                     m0_axil_bvalid;
  wire               [1:0] m0_axil_bresp;
  wire                     m0_axil_bready;
  wire                     m0_axil_arvalid;
  wire              [31:0] m0_axil_araddr;
  wire                     m0_axil_arready;
  wire                     m0_axil_rvalid;
  wire              [31:0] m0_axil_rdata;
  wire               [1:0] m0_axil_rresp;
  wire                     m0_axil_rready;

  wire [31:0] user_rst_done = 32'hffff_fffe;

  nf_attachment #(
    .C_NF_TDATA_WIDTH (C_NF_TDATA_WIDTH),
    .C_NF_TUSER_WIDTH (C_NF_TUSER_WIDTH),
    .C_TDATA_WIDTH    (C_TDATA_WIDTH   ),
    .C_TUSER_WIDTH    (C_TUSER_WIDTH   )
  ) u_nf_attachment (
    // Slave Stream Ports
    .axis_dma_o_tdata     (axis_dma_o_tdata ),
    .axis_dma_o_tkeep     (axis_dma_o_tkeep ),
    .axis_dma_o_tuser     (axis_dma_o_tuser ),
    .axis_dma_o_tvalid    (axis_dma_o_tvalid),
    .axis_dma_o_tready    (axis_dma_o_tready),
    .axis_dma_o_tlast     (axis_dma_o_tlast ),
    // Master Stream Ports
    .axis_dma_i_tdata     (axis_dma_i_tdata ),
    .axis_dma_i_tkeep     (axis_dma_i_tkeep ),
    .axis_dma_i_tuser     (axis_dma_i_tuser ),
    .axis_dma_i_tvalid    (axis_dma_i_tvalid),
    .axis_dma_i_tready    (axis_dma_i_tready),
    .axis_dma_i_tlast     (axis_dma_i_tlast ),
    // Slave Stream Ports
    .axis_o_0_tdata       (axis_o_0_tdata ),
    .axis_o_0_tkeep       (axis_o_0_tkeep ),
    .axis_o_0_tuser       (axis_o_0_tuser ),
    .axis_o_0_tvalid      (axis_o_0_tvalid),
    .axis_o_0_tready      (axis_o_0_tready),
    .axis_o_0_tlast       (axis_o_0_tlast ),
    // Slave Stream Ports
    .axis_o_1_tdata       (axis_o_1_tdata ),
    .axis_o_1_tkeep       (axis_o_1_tkeep ),
    .axis_o_1_tuser       (axis_o_1_tuser ),
    .axis_o_1_tvalid      (axis_o_1_tvalid),
    .axis_o_1_tready      (axis_o_1_tready),
    .axis_o_1_tlast       (axis_o_1_tlast ),
    // Master Stream Ports
    .axis_i_0_tdata       (axis_i_0_tdata ),
    .axis_i_0_tkeep       (axis_i_0_tkeep ),
    .axis_i_0_tuser       (axis_i_0_tuser ),
    .axis_i_0_tvalid      (axis_i_0_tvalid),
    .axis_i_0_tready      (axis_i_0_tready),
    .axis_i_0_tlast       (axis_i_0_tlast ),
    // Master Stream Ports
    .axis_i_1_tdata       (axis_i_1_tdata ),
    .axis_i_1_tkeep       (axis_i_1_tkeep ),
    .axis_i_1_tuser       (axis_i_1_tuser ),
    .axis_i_1_tvalid      (axis_i_1_tvalid),
    .axis_i_1_tready      (axis_i_1_tready),
    .axis_i_1_tlast       (axis_i_1_tlast ),
  
    .axis_cmac_0_rx_tvalid(axis_cmac_0_rx_tvalid),
    .axis_cmac_0_rx_tdata (axis_cmac_0_rx_tdata ),
    .axis_cmac_0_rx_tkeep (axis_cmac_0_rx_tkeep ),
    .axis_cmac_0_rx_tuser_err (axis_cmac_0_rx_tuser_err),
    .axis_cmac_0_rx_tlast (axis_cmac_0_rx_tlast ),
  
    .axis_cmac_1_rx_tvalid(axis_cmac_1_rx_tvalid),
    .axis_cmac_1_rx_tdata (axis_cmac_1_rx_tdata ),
    .axis_cmac_1_rx_tkeep (axis_cmac_1_rx_tkeep ),
    .axis_cmac_1_rx_tuser_err (axis_cmac_1_rx_tuser_err ),
    .axis_cmac_1_rx_tlast (axis_cmac_1_rx_tlast ),
  
    .axis_cmac_0_tx_tvalid(axis_cmac_0_tx_tvalid),
    .axis_cmac_0_tx_tdata (axis_cmac_0_tx_tdata ),
    .axis_cmac_0_tx_tkeep (axis_cmac_0_tx_tkeep ),
    .axis_cmac_0_tx_tuser_err (axis_cmac_0_tx_tuser_err ),
    .axis_cmac_0_tx_tlast (axis_cmac_0_tx_tlast ),
    .axis_cmac_0_tx_tready(axis_cmac_0_tx_tready),
  
    .axis_cmac_1_tx_tvalid(axis_cmac_1_tx_tvalid),
    .axis_cmac_1_tx_tdata (axis_cmac_1_tx_tdata ),
    .axis_cmac_1_tx_tkeep (axis_cmac_1_tx_tkeep ),
    .axis_cmac_1_tx_tuser_err (axis_cmac_1_tx_tuser_err ),
    .axis_cmac_1_tx_tlast (axis_cmac_1_tx_tlast ),
    .axis_cmac_1_tx_tready(axis_cmac_1_tx_tready),
  
    .s_axis_qdma_c2h_0_tvalid (s_axis_qdma_c2h_0_tvalid),
    .s_axis_qdma_c2h_0_tdata  (s_axis_qdma_c2h_0_tdata ),
    .s_axis_qdma_c2h_0_tkeep  (s_axis_qdma_c2h_0_tkeep ),
    .s_axis_qdma_c2h_0_tlast  (s_axis_qdma_c2h_0_tlast ),
    .s_axis_qdma_c2h_0_tuser_size(s_axis_qdma_c2h_0_tuser_size),
    .s_axis_qdma_c2h_0_tuser_src (s_axis_qdma_c2h_0_tuser_src),
    .s_axis_qdma_c2h_0_tuser_dst (s_axis_qdma_c2h_0_tuser_dst),
    //.s_axis_qdma_c2h_0_tid    (s_axis_qdma_c2h_0_tid   ),
    //.s_axis_qdma_c2h_0_tdest  (s_axis_qdma_c2h_0_tdest ),
    .s_axis_qdma_c2h_0_tready (s_axis_qdma_c2h_0_tready),
  
    .s_axis_qdma_c2h_1_tvalid (s_axis_qdma_c2h_1_tvalid),
    .s_axis_qdma_c2h_1_tdata  (s_axis_qdma_c2h_1_tdata ),
    .s_axis_qdma_c2h_1_tkeep  (s_axis_qdma_c2h_1_tkeep ),
    .s_axis_qdma_c2h_1_tlast  (s_axis_qdma_c2h_1_tlast ),
    .s_axis_qdma_c2h_1_tuser_size(s_axis_qdma_c2h_1_tuser_size),
    .s_axis_qdma_c2h_1_tuser_src (s_axis_qdma_c2h_1_tuser_src),
    .s_axis_qdma_c2h_1_tuser_dst (s_axis_qdma_c2h_1_tuser_dst),
    //.s_axis_qdma_c2h_1_tid    (s_axis_qdma_c2h_1_tid   ),
    //.s_axis_qdma_c2h_1_tdest  (s_axis_qdma_c2h_1_tdest ),
    .s_axis_qdma_c2h_1_tready (s_axis_qdma_c2h_1_tready),
  
    .m_axis_qdma_h2c_0_tvalid (m_axis_qdma_h2c_0_tvalid),
    .m_axis_qdma_h2c_0_tdata  (m_axis_qdma_h2c_0_tdata ),
    .m_axis_qdma_h2c_0_tkeep  (m_axis_qdma_h2c_0_tkeep ),
    .m_axis_qdma_h2c_0_tlast  (m_axis_qdma_h2c_0_tlast ),
    .m_axis_qdma_h2c_0_tuser_size(m_axis_qdma_h2c_0_tuser_size),
    .m_axis_qdma_h2c_0_tuser_src (m_axis_qdma_h2c_0_tuser_src),
    .m_axis_qdma_h2c_0_tuser_dst (m_axis_qdma_h2c_0_tuser_dst),
    //.m_axis_qdma_h2c_0_tid    (m_axis_qdma_h2c_0_tid   ),
    //.m_axis_qdma_h2c_0_tdest  (m_axis_qdma_h2c_0_tdest ),
    .m_axis_qdma_h2c_0_tready (m_axis_qdma_h2c_0_tready),
  
    .m_axis_qdma_h2c_1_tvalid (m_axis_qdma_h2c_1_tvalid),
    .m_axis_qdma_h2c_1_tdata  (m_axis_qdma_h2c_1_tdata ),
    .m_axis_qdma_h2c_1_tkeep  (m_axis_qdma_h2c_1_tkeep ),
    .m_axis_qdma_h2c_1_tlast  (m_axis_qdma_h2c_1_tlast ),
    .m_axis_qdma_h2c_1_tuser_size(m_axis_qdma_h2c_1_tuser_size),
    .m_axis_qdma_h2c_1_tuser_src (m_axis_qdma_h2c_1_tuser_src),
    .m_axis_qdma_h2c_1_tuser_dst (m_axis_qdma_h2c_1_tuser_dst),
    //.m_axis_qdma_h2c_1_tid    (m_axis_qdma_h2c_1_tid   ),
    //.m_axis_qdma_h2c_1_tdest  (m_axis_qdma_h2c_1_tdest ),
    .m_axis_qdma_h2c_1_tready (m_axis_qdma_h2c_1_tready),
  
    .m0_axil_awvalid          (m0_axil_awvalid),
    .m0_axil_awaddr           (m0_axil_awaddr ),
    .m0_axil_awready          (m0_axil_awready),
    .m0_axil_wvalid           (m0_axil_wvalid ),
    .m0_axil_wdata            (m0_axil_wdata  ),
    .m0_axil_wready           (m0_axil_wready ),
    .m0_axil_bvalid           (m0_axil_bvalid ),
    .m0_axil_bresp            (m0_axil_bresp  ),
    .m0_axil_bready           (m0_axil_bready ),
    .m0_axil_arvalid          (m0_axil_arvalid),
    .m0_axil_araddr           (m0_axil_araddr ),
    .m0_axil_arready          (m0_axil_arready),
    .m0_axil_rvalid           (m0_axil_rvalid ),
    .m0_axil_rdata            (m0_axil_rdata  ),
    .m0_axil_rresp            (m0_axil_rresp  ),
    .m0_axil_rready           (m0_axil_rready ),
  
    .cmac_clk              (cmac_clk),
    .core_clk              (core_clk ),
    .axis_aclk             (axis_aclk),
    .axil_aclk             (axil_aclk),
    .axis_rst              (axis_rst ),
    .axil_rst              (axil_rst )
  );

  xilinx_shell_ip xilinx_nic_shell (
`ifndef sim
    .pcie_txp      (pcie_txp),
    .pcie_txn      (pcie_txn),
    .pcie_rxp      (pcie_rxp),
    .pcie_rxn      (pcie_rxn),
    .pcie_refclk_p (pcie_clk_p),
    .pcie_refclk_n (pcie_clk_n),
    .pcie_rstn     (pcie_rst_n),

    .qsfp_rxp      ({qsfp1_rxp, qsfp0_rxp}),
    .qsfp_rxn      ({qsfp1_rxn, qsfp0_rxn}),
    .qsfp_txp      ({qsfp1_txp, qsfp0_txp}),
    .qsfp_txn      ({qsfp1_txn, qsfp0_txn}),
    .qsfp_refclk_p ({qsfp1_clk_p, qsfp0_clk_p}),
    .qsfp_refclk_n ({qsfp1_clk_n, qsfp0_clk_n}),
`else // !`ifdef __synthesis__
    .s_axil_awvalid (),
    .s_axil_awaddr  (),
    .s_axil_awready (),
    .s_axil_wvalid  (),
    .s_axil_wdata   (),
    .s_axil_wready  (),
    .s_axil_bvalid  (),
    .s_axil_bresp   (),
    .s_axil_bready  (),
    .s_axil_arvalid (),
    .s_axil_araddr  (),
    .s_axil_arready (),
    .s_axil_rvalid  (),
    .s_axil_rdata   (),
    .s_axil_rresp   (),
    .s_axil_rready  (),

    .s_axis_qdma_h2c_tvalid       (),
    .s_axis_qdma_h2c_tlast        (),
    .s_axis_qdma_h2c_tdata        (),
    .s_axis_qdma_h2c_dpar         (),
    .s_axis_qdma_h2c_tuser_qid    (),
    .s_axis_qdma_h2c_tuser_port_id(),
    .s_axis_qdma_h2c_tuser_err    (),
    .s_axis_qdma_h2c_tuser_mdata  (),
    .s_axis_qdma_h2c_tuser_mty    (),
    .s_axis_qdma_h2c_tuser_zero_byte(),
    .s_axis_qdma_h2c_tready       (),

    .m_axis_qdma_c2h_tvalid       (),
    .m_axis_qdma_c2h_tlast        (),
    .m_axis_qdma_c2h_tdata        (),
    .m_axis_qdma_c2h_dpar         (),
    .m_axis_qdma_c2h_ctrl_marker  (),
    .m_axis_qdma_c2h_ctrl_port_id (),
    .m_axis_qdma_c2h_ctrl_len     (),
    .m_axis_qdma_c2h_ctrl_qid     (),
    .m_axis_qdma_c2h_ctrl_has_cmpt(),
    .m_axis_qdma_c2h_mty          (),
    .m_axis_qdma_c2h_tready       (),

    .m_axis_qdma_cpl_tvalid              (),
    .m_axis_qdma_cpl_tdata               (),
    .m_axis_qdma_cpl_size                (),
    .m_axis_qdma_cpl_dpar                (),
    .m_axis_qdma_cpl_ctrl_qid            (),
    .m_axis_qdma_cpl_ctrl_cmpt_type      (),
    .m_axis_qdma_cpl_ctrl_wait_pld_pkt_id(),
    .m_axis_qdma_cpl_ctrl_port_id        (),
    .m_axis_qdma_cpl_ctrl_marker         (),
    .m_axis_qdma_cpl_ctrl_user_trig      (),
    .m_axis_qdma_cpl_ctrl_col_idx        (),
    .m_axis_qdma_cpl_ctrl_err_idx        (),
    .m_axis_qdma_cpl_tready              (),

    .m_axis_cmac_tx_tvalid                    (),
    .m_axis_cmac_tx_tdata                     (),
    .m_axis_cmac_tx_tkeep                     (),
    .m_axis_cmac_tx_tlast                     (),
    .m_axis_cmac_tx_tuser                     (),
    .m_axis_cmac_tx_tready                    (),

    .s_axis_cmac_rx_tvalid                    (),
    .s_axis_cmac_rx_tdata                     (),
    .s_axis_cmac_rx_tkeep                     (),
    .s_axis_cmac_rx_tlast                     (),
    .s_axis_cmac_rx_tuser                     (),

    .powerup_rstn                             (),
`endif

    .m_axil_box0_awvalid               (m0_axil_awvalid),
    .m_axil_box0_awaddr                (m0_axil_awaddr ),
    .m_axil_box0_awready               (m0_axil_awready),
    .m_axil_box0_wvalid                (m0_axil_wvalid ),
    .m_axil_box0_wdata                 (m0_axil_wdata  ),
    .m_axil_box0_wready                (m0_axil_wready ),
    .m_axil_box0_bvalid                (m0_axil_bvalid ),
    .m_axil_box0_bresp                 (m0_axil_bresp  ),
    .m_axil_box0_bready                (m0_axil_bready ),
    .m_axil_box0_arvalid               (m0_axil_arvalid),
    .m_axil_box0_araddr                (m0_axil_araddr ),
    .m_axil_box0_arready               (m0_axil_arready),
    .m_axil_box0_rvalid                (m0_axil_rvalid ),
    .m_axil_box0_rdata                 (m0_axil_rdata  ),
    .m_axil_box0_rresp                 (m0_axil_rresp  ),
    .m_axil_box0_rready                (m0_axil_rready ),

    .m_axil_box1_awvalid               (m_axil_awvalid),
    .m_axil_box1_awaddr                (m_axil_awaddr ),
    .m_axil_box1_awready               (m_axil_awready),
    .m_axil_box1_wvalid                (m_axil_wvalid ),
    .m_axil_box1_wdata                 (m_axil_wdata  ),
    .m_axil_box1_wready                (m_axil_wready ),
    .m_axil_box1_bvalid                (m_axil_bvalid ),
    .m_axil_box1_bresp                 (m_axil_bresp  ),
    .m_axil_box1_bready                (m_axil_bready ),
    .m_axil_box1_arvalid               (m_axil_arvalid),
    .m_axil_box1_araddr                (m_axil_araddr ),
    .m_axil_box1_arready               (m_axil_arready),
    .m_axil_box1_rvalid                (m_axil_rvalid ),
    .m_axil_box1_rdata                 (m_axil_rdata  ),
    .m_axil_box1_rresp                 (m_axil_rresp  ),
    .m_axil_box1_rready                (m_axil_rready ),

     // QDMA subsystem interfaces to the box running at 250MHz
    .m_axis_qdma_h2c_tvalid    ({m_axis_qdma_h2c_1_tvalid, m_axis_qdma_h2c_0_tvalid }),
    .m_axis_qdma_h2c_tdata     ({m_axis_qdma_h2c_1_tdata , m_axis_qdma_h2c_0_tdata  }),
    .m_axis_qdma_h2c_tkeep     ({m_axis_qdma_h2c_1_tkeep , m_axis_qdma_h2c_0_tkeep  }),
    .m_axis_qdma_h2c_tlast     ({m_axis_qdma_h2c_1_tlast , m_axis_qdma_h2c_0_tlast  }),
    .m_axis_qdma_h2c_tuser_size({m_axis_qdma_h2c_1_tuser_size, m_axis_qdma_h2c_0_tuser_size}),
    .m_axis_qdma_h2c_tuser_src ({m_axis_qdma_h2c_1_tuser_src, m_axis_qdma_h2c_0_tuser_src}),
    .m_axis_qdma_h2c_tuser_dst ({m_axis_qdma_h2c_1_tuser_dst, m_axis_qdma_h2c_0_tuser_dst}),
    .m_axis_qdma_h2c_tready    ({m_axis_qdma_h2c_1_tready, m_axis_qdma_h2c_0_tready}),

    .s_axis_qdma_c2h_tvalid    ({s_axis_qdma_c2h_1_tvalid, s_axis_qdma_c2h_0_tvalid }),
    .s_axis_qdma_c2h_tdata     ({s_axis_qdma_c2h_1_tdata , s_axis_qdma_c2h_0_tdata  }),
    .s_axis_qdma_c2h_tkeep     ({s_axis_qdma_c2h_1_tkeep , s_axis_qdma_c2h_0_tkeep  }),
    .s_axis_qdma_c2h_tlast     ({s_axis_qdma_c2h_1_tlast , s_axis_qdma_c2h_0_tlast  }),
    .s_axis_qdma_c2h_tuser_size({s_axis_qdma_c2h_1_tuser_size, s_axis_qdma_c2h_0_tuser_size}),
    .s_axis_qdma_c2h_tuser_src ({s_axis_qdma_c2h_1_tuser_src, s_axis_qdma_c2h_0_tuser_src}),
    .s_axis_qdma_c2h_tuser_dst ({s_axis_qdma_c2h_1_tuser_dst, s_axis_qdma_c2h_0_tuser_dst}),
    .s_axis_qdma_c2h_tready    ({s_axis_qdma_c2h_1_tready, s_axis_qdma_c2h_0_tready}),

    // CMAC subsystem CMAC-side interfaces to the box running at 322MHz
    .s_axis_cmac_tx_tvalid   ({axis_cmac_1_tx_tvalid, axis_cmac_0_tx_tvalid}),
    .s_axis_cmac_tx_tdata    ({axis_cmac_1_tx_tdata , axis_cmac_0_tx_tdata }),
    .s_axis_cmac_tx_tkeep    ({axis_cmac_1_tx_tkeep , axis_cmac_0_tx_tkeep }),
    .s_axis_cmac_tx_tlast    ({axis_cmac_1_tx_tlast , axis_cmac_0_tx_tlast }),
    .s_axis_cmac_tx_tuser_err({axis_cmac_1_tx_tuser_err, axis_cmac_0_tx_tuser_err}),
    .s_axis_cmac_tx_tready   ({axis_cmac_1_tx_tready, axis_cmac_0_tx_tready}),

    .m_axis_cmac_rx_tvalid   ({axis_cmac_1_rx_tvalid, axis_cmac_0_rx_tvalid}),
    .m_axis_cmac_rx_tdata    ({axis_cmac_1_rx_tdata , axis_cmac_0_rx_tdata }),
    .m_axis_cmac_rx_tkeep    ({axis_cmac_1_rx_tkeep , axis_cmac_0_rx_tkeep }),
    .m_axis_cmac_rx_tlast    ({axis_cmac_1_rx_tlast , axis_cmac_0_rx_tlast }),
    .m_axis_cmac_rx_tuser_err({axis_cmac_1_rx_tuser_err, axis_cmac_0_rx_tuser_err}),

    .user_rstn              (),
    .user_rst_done          (user_rst_done),

    .axil_aclk              (axil_aclk),
    .axis_aclk              (axis_aclk),

    .cmac_clk               (cmac_clk)
  );

endmodule
