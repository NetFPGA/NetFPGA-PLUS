set axi_clock_converter qdma_subsystem_axi_cdc
create_ip -name axi_clock_converter -vendor xilinx.com -library ip -module_name $axi_clock_converter -dir ${ip_build_dir}
set_property -dict {
    CONFIG.PROTOCOL {AXI4LITE}
    CONFIG.DATA_WIDTH {32}
    CONFIG.ID_WIDTH {0}
    CONFIG.AWUSER_WIDTH {0}
    CONFIG.ARUSER_WIDTH {0}
    CONFIG.RUSER_WIDTH {0}
    CONFIG.WUSER_WIDTH {0}
    CONFIG.BUSER_WIDTH {0}
    CONFIG.SI_CLK.FREQ_HZ {250000000}
    CONFIG.MI_CLK.FREQ_HZ {250000000}
    CONFIG.ACLK_ASYNC {1}
    CONFIG.SYNCHRONIZATION_STAGES {2}
} [get_ips $axi_clock_converter]
