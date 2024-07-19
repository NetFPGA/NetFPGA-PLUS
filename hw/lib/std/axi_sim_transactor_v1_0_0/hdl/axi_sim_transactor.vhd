---
-- Copyright (c) 2015 David J. Miller, Georgina Kalogeridou
-- All rights reserved.
--
-- This software was developed by
-- Stanford University and the University of Cambridge Computer Laboratory
-- under National Science Foundation under Grant No. CNS-0855268,
-- the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
-- by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
-- as part of the DARPA MRC research programme.
--
-- @NETFPGA_LICENSE_HEADER_START@
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--  http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- @NETFPGA_LICENSE_HEADER_END@
--
------------------------------------------------------------------------------
--  File:
--        axi_sim_transactor.vhd
--
--  Library:
--        hw/std/cores/axi_sim_transactor_v1_0_0
--
--  Module:
--        axi_sim_transactor
--
--  Author:
--        David J. Miller, Georgina Kalogeridou
-- 		
--  Description:
--        Drives an AXI Stream slave using stimuli from an AXI grammar
--        formatted text file.
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

use std.textio.all;

library xil_defaultlib;
use xil_defaultlib.axis_sim_pkg.all;

entity axi_sim_transactor is
    generic (
        STIM_FILE       : string   := "../../reg_stim.axi";
        EXPECT_FILE     : string   := "../../reg_expect.axi";
        LOG_FILE        : string   := "../../reg_stim.log"
        );
    port (
    axi_aclk		  : in std_logic;
        axi_resetn		  : in std_logic;                                     
        -- AXI Lite interface
        --
        -- AXI Write address channel
        M_AXI_AWADDR             : out std_logic_vector(31 downto 0);
        M_AXI_AWVALID            : out std_logic;
        M_AXI_AWREADY            : in  std_logic;
        -- AXI Write data channel
        M_AXI_WDATA              : out std_logic_vector(31 downto 0);
        M_AXI_WSTRB              : out std_logic_vector( 3 downto 0);
        M_AXI_WVALID             : out std_logic;
        M_AXI_WREADY             : in  std_logic;
        -- AXI Write response channel
        M_AXI_BRESP              : in  std_logic_vector( 1 downto 0);
        M_AXI_BVALID             : in  std_logic;
        M_AXI_BREADY             : out std_logic;
        -- AXI Read address channel
        M_AXI_ARADDR             : out std_logic_vector(31 downto 0);
        M_AXI_ARVALID            : out std_logic;
        M_AXI_ARREADY            : in  std_logic;
        -- AXI Read data & response channel
        M_AXI_RDATA              : in  std_logic_vector(31 downto 0);
        M_AXI_RRESP              : in  std_logic_vector( 1 downto 0);
        M_AXI_RVALID             : in  std_logic;
        M_AXI_RREADY             : out std_logic;

    activity_trans_sim	 : out std_logic;
    activity_trans_log	 : out std_logic;
    barrier_req_trans   	 : out std_logic;
        barrier_proceed 	 : in std_logic
        );
end;


architecture rtl of axi_sim_transactor is

    signal reset, rst                    : std_logic;

    file stim: text open read_mode is STIM_FILE;
    file expect: text open read_mode is EXPECT_FILE;
    file log : text open write_mode is LOG_FILE;

    signal w_req_addr                    : std_logic_vector(31 downto 0);
    signal w_req_data                    : std_logic_vector(31 downto 0);
    signal w_req_strb                    : std_logic_vector( 3 downto 0);
    signal w_req_valid                   : std_logic;
    signal w_req_ready                   : std_logic;

    signal w_rsp_addr                    : std_logic_vector(31 downto 0);
    signal w_rsp_data                    : std_logic_vector(31 downto 0);
    signal w_rsp_rsp                     : std_logic_vector( 1 downto 0);
    signal w_rsp_valid                   : std_logic;

    signal r_req_addr                    : std_logic_vector(31 downto 0);
    signal r_req_valid                   : std_logic;
    signal r_req_ready                   : std_logic;

    signal r_rsp_addr                    : std_logic_vector(31 downto 0);
    signal r_rsp_data                    : std_logic_vector(31 downto 0);
    signal r_rsp_rsp                     : std_logic_vector( 1 downto 0);
    signal r_rsp_valid                   : std_logic;
    signal addr_r : std_logic_vector(31 downto 0);
    signal data_r : std_logic_vector(31 downto 0);
    shared variable f, o, v, j, k: integer range 0 to 31;
    

begin

    rst <= not axi_resetn;
    reset <= rst;

    stimulation: process

        -----------------------------------------------------------------------
        -- quiescent()
        --
        --      Quiesce outputs.
        procedure quiescent is
        begin
            w_req_addr <= (others => '0');
            w_req_data <= (others => '0');
            w_req_strb <= (others => '0');
            w_req_valid <= '0';

            r_req_addr <= (others => '0');
            r_req_valid <= '0';
        end procedure;

        -----------------------------------------------------------------------
        -- wait_cycle()
        --
        --      Wait for N cycles (1 by default).
        procedure wait_cycle( n: natural := 1 ) is
            variable lp: natural := n;
        begin
            while lp /= 0 loop
                wait until rising_edge(axi_aclk);
                lp := lp - 1;
            end loop;
        end procedure;

    -----------------------------------------------------------------------
        variable l: line;
        variable i: integer;
        variable c: character;
        variable ok, dontcare: boolean;
        variable w_pending, r_pending: std_logic;
    begin
        quiescent;                      -- sane initial outputs

        -- Wait for a couple cycles in case reset is not asserted straight
        -- away.
        --
        -- NB: Reset is ignored except at the beginning of simulation.
        wait_cycle( 10 );
        while reset = '1' loop          -- wait until reset goes away
            wait_cycle;
        end loop;

    activity_trans_sim <= '0';
        barrier_req_trans <= '0';

        -- begin reading stimuli
        while not endfile( stim ) loop
            -- Main dispatch: Get and parse input
            readline( stim, l );
            lookahead_char( l, c, ok );
            next when not ok;

            if c = 'B' then 	        
                read_char( l, c );
                parse_int( l, i );
                quiescent;
                wait for ( i * 1 ns);
                wait_cycle;
                write(l, integer'image(now / 1 ns) & string'(" ns.") & string'(" Info: barrier request transactor")); 
                writeline( output, l );
                wait for (1 ns); 
                barrier_req_trans <= '1';
                while (barrier_proceed = '0') loop
                    wait until (barrier_proceed = '1');
                end loop;
                wait for (1 ns);
                barrier_req_trans <= '0';
                wait until (barrier_proceed = '0');
                write(l, integer'image(now / 1 ns) & string'(" ns.") & string'("Info: barrier complete transactor")); 
                writeline( output, l );
            
            elsif c = 'N' then 	        
                read_char( l, c );
                parse_int( l, v );
                quiescent;
                wait for ( v * 1 ns);
                wait_cycle;

            elsif c = 'S' then          -- wait for relative time (ns)
                read_char( l, c );      -- discard operator
                parse_int( l, i );
                quiescent;
                wait for ( i * 1 ns);                
                wait_cycle;
            
            -- operator @(N): wait for time N ns
            elsif c = '@' then          -- wait until absolute time (ns)
                read_char( l, c );      -- discard operator
                parse_int( l, i );
                quiescent;
                wait for ( i * 1 ns);    
                wait_cycle;

            elsif c = 'R' then
                read_char( l, c );
                parse_int( l, i );
                report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
                write(l, string'("Read Register!"));
                writeline( output, l );
                quiescent;
                wait for ( i * 1 ns);
                wait_cycle;

            elsif c = 'W' then          
                read_char( l, c );      
                parse_int( l, i );
                report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
                write(l, string'("Write Register!"));
                writeline( output, l );
                quiescent;
                wait for ( i * 1 ns);
                wait_cycle;

            elsif c = 'D' then          
                read_char( l, c );      
                parse_int( l, i );
                report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
                write(l, string'("Info: delaying ") & integer'image(i) & string'(" ns"));
                writeline( output, l );
                quiescent;
                wait for ( i * 1 ns);
                wait_cycle;
            
            else
                activity_trans_sim <= '1';
                -- parse out each component of the stimulus
                parse_slv( l, w_req_addr, dontcare );
                w_pending := sl( not dontcare );
                w_req_valid <= w_pending;
                read_char( l, c );      -- discard ','
                parse_slv( l, w_req_data, dontcare );
                if w_pending = '1' then
                    assert not dontcare
                        report STIM_FILE & ": malformed write request: missing data"
                    severity warning;
                end if;
                read_char( l, c );      -- discard ','
                
                parse_slv( l, w_req_strb, dontcare );
                if w_pending = '1' then
                    assert not dontcare
                    report STIM_FILE & ": malformed write request: missing byte lane strobe"
                    severity warning;
                end if;
                read_char( l, c );      -- discard ','
                parse_slv( l, r_req_addr, dontcare );
                r_pending := sl( not dontcare );
                r_req_valid <= r_pending;
                wait_cycle;
                -- block until accepted
                while ((w_pending and not w_req_ready) or (r_pending and not r_req_ready)) = '1' loop
                    wait_cycle;
                end loop;
                w_req_valid <= '0';
                r_req_valid <= '0';
                -- wait for transactions to return, as required
                read_char( l, c );      -- read terminal wait flag

                if c = '.' then         -- '.' == wait for result
                    while (w_pending or r_pending) = '1' loop
                        wait_cycle;
                        if w_rsp_valid = '1' and w_rsp_addr = w_req_addr then
                            w_pending := '0';
                        end if;
                        if r_rsp_valid = '1' and r_rsp_addr = r_req_addr then
                            r_pending := '0';
                        end if;
                    end loop;
                elsif c = ',' then      -- continue immediately        
                else   
                    assert false
                    report STIM_FILE & ": bad input: expected terminal ',' or '.'"
                    severity failure;
                end if;

            activity_trans_sim <= '0';
            end if;
            deallocate(l);              -- finished with input line
        end loop;

        -- End of stimuli.
        quiescent;
        write( l, string'("") );
        writeline( output, l );
        write( l, STIM_FILE & string'(": end of stimuli @ ")  & integer'image(now / 1 ns) & string'(" ns.") );
        writeline( output, l );
        wait;
    end process; -- Stimulation

    expected: process 

        -----------------------------------------------------------------------
        -- wait_cycle()
        --
        --      Wait for N cycles (1 by default).
        procedure wait_cycle( n: natural := 1 ) is
            variable lp: natural := n;
        begin
            while lp /= 0 loop
                wait until rising_edge(axi_aclk);
                lp := lp - 1;
            end loop;
        end procedure;
    -----------------------------------------------------------------------

    variable l: line;
        variable i: integer;
    variable t, p: integer :=0;
        variable c: character;
        variable ok, dontcare: boolean;
    variable write_pending, read_pending: std_logic;
    
    begin
       
        -- NB: Reset is ignored except at the beginning of simulation.
        wait_cycle( 10 );
        while reset = '1' loop          -- wait until reset goes away
            wait_cycle;
        end loop;	

     -- begin reading stimuli
        while not endfile( expect ) loop
            -- Main dispatch: Get and parse input
            readline( expect, l );
            lookahead_char( l, c, ok );
            next when not ok;   

            if c = 'B' then 	        
                read_char( l, c );
                parse_int( l, i );
                wait for ( i * 1 ns);
                wait_cycle;

            elsif c = 'R' then
                read_char( l, c );
                parse_int( l, i );
                v := v + 1;
                wait for ( i * 1 ns);
                wait_cycle;

            elsif c = 'W' then          -- wait until absolute time (ns)
                read_char( l, c );      -- discard operator
                parse_int( l, i );
                wait for ( i * 1 ns);
                wait_cycle;

                -- operator @(N): wait until absolute time N ns
            elsif c = '@' then          -- wait until absolute time (ns)
                read_char( l, c );      -- discard operator
                parse_int( l, i );
                wait for ( i * 1  ns);    
                wait_cycle;

            elsif c = '+' then          -- wait for relative time (ns)
                read_char( l, c );      -- discard operator
                parse_int( l, i );
                wait for ( i * 1 ns);                
                    wait_cycle;

            else
                parse_slv( l, addr_r, dontcare );
                read_pending := sl( not dontcare );
                read_char( l, c );      -- discard ','
                parse_slv( l, data_r, dontcare );
                if read_pending = '1' then
                    assert not dontcare
                    report EXPECT_FILE & ": malformed read request: missing data"
                    severity warning;
                end if;
                wait_cycle;
                    -- block until accepted
                while (read_pending and not r_req_ready) = '1' loop
                    wait_cycle;
                end loop;
                -- wait for transactions to return, as required
                read_char( l, c );      -- read terminal wait flag
                if c = '.' then         -- '.' == wait for result
                    while (read_pending) = '1' loop
                        wait_cycle;
                        if r_rsp_valid = '1' and addr_r = r_rsp_addr then
                            read_pending := '0';
                        end if;
                    end loop;  
                elsif c = ',' then      -- continue immediately                   			
                else    
                    assert false
                    report STIM_FILE & ": bad input: expected terminal ',' or '.'"
                    severity failure;
                end if;		
            end if;
            deallocate(l);              -- finished with input line
        end loop; 

    -- End of stimuli.
        write( l, string'("") );
        writeline( output, l );
        write( l, EXPECT_FILE & string'(": end of stimuli @ ")  & integer'image(now / 1 ns) & string'(" ns.") );
        writeline( output, l );
        wait;
    end process;  -- Expected

--------------------------------------------------------------------------------------------------


    logging: process( axi_aclk )

        function result_str( res: std_logic_vector(1 downto 0) ) return string is
        begin
            case res is
                when "00"   => return "OKAY";
                when "01"   => return "EXOKAY";
                when "10"   => return "SLVERR";
                when "11"   => return "DECERR";
                when others => return "INVALID_RESP";
            end case;
        end function;

        variable l: line;
    variable g: integer;
    variable b: integer := 0;

    begin
    activity_trans_log <= '0';

            if rising_edge( axi_aclk ) then
                if w_rsp_valid = '1' then
                activity_trans_log <= '1';
                hwrite( l, w_rsp_addr, RIGHT, w_rsp_addr'length/4 );
                write( l, string'(" <- ") );
                hwrite( l, w_rsp_data, RIGHT, w_rsp_data'length/4 );
                write( l, string'(" (" & result_str( w_rsp_rsp ) & ")") &
                          ht & ht & string'("# ") & integer'image(now / 1 ns) & string'(" ns") );
                writeline( log, l );	
                end if;
                if r_rsp_valid = '1' then
                activity_trans_log <= '1';
                hwrite( l, r_rsp_addr, RIGHT, r_rsp_addr'length/4 );
                write( l, string'(" -> ") );
                if addr_r = r_rsp_addr then

                    for g in 0 to 31 loop
                    if (data_r(g) = '0') and (r_rsp_data(g) = 'X') then
                        b := 1;
                    end if;
                    end loop;

                    if data_r = r_rsp_data then
                        hwrite( l, r_rsp_data, RIGHT, r_rsp_data'length/4 );
                        write( l, string'(" (" & result_str( r_rsp_rsp ) & ")") & ht & ht & string'("# ") & integer'image(now / 1 ns) & string'(" ns") );
                    elsif b = 1 then 
                    hwrite( l, r_rsp_data, RIGHT, r_rsp_data'length/4 );
                        write( l, string'(" (" & result_str( r_rsp_rsp ) & ")") & ht & ht & string'("# ") & integer'image(now / 1 ns) & string'(" ns") & string'(" ## ") & string'("WARNING! Undefined bits -- check waveforms!!!!") );
                    elsif data_r /= r_rsp_data and b = 0 then
                    activity_trans_log <= '0';
                    write( l, string'("Data Error: register error!!!! "));
                    write( l, string'("Seen from user: "));
                    hwrite( l, data_r);
                    write( l, string'(" but expected from system: "));
                    hwrite( l, r_rsp_data, RIGHT, r_rsp_data'length/4 );
                    end if;
                else     
                    activity_trans_log <= '0';
                    write( l, string'("Address Error: register error!!!! "));
                    write( l, string'("Seen from user: "));
                    hwrite( l, addr_r);
                    write( l, string'(" but expected from system: "));
                    hwrite( l, r_rsp_addr, RIGHT, r_rsp_addr'length/4 );
                end if;
                writeline( log, l );
                end if;
            end if; 
    
    end process;

    fifos: entity xil_defaultlib.transactor_fifos
        port map (
            clk           => axi_aclk,
            reset         => reset,
            --
            w_req_addr    => w_req_addr,
            w_req_data    => w_req_data,
            w_req_strb    => w_req_strb,
            w_req_valid   => w_req_valid,
            w_req_ready   => w_req_ready,

            w_rsp_addr    => w_rsp_addr,
            w_rsp_data    => w_rsp_data,
            w_rsp_rsp     => w_rsp_rsp,
            w_rsp_valid   => w_rsp_valid,
            --
            r_req_addr    => r_req_addr,
            r_req_valid   => r_req_valid,
            r_req_ready   => r_req_ready,

            r_rsp_addr    => r_rsp_addr,
            r_rsp_data    => r_rsp_data,
            r_rsp_rsp     => r_rsp_rsp,
            r_rsp_valid   => r_rsp_valid,
            --
            M_AXI_AWADDR  => M_AXI_AWADDR,
            M_AXI_AWVALID => M_AXI_AWVALID,
            M_AXI_AWREADY => M_AXI_AWREADY,
            M_AXI_WDATA   => M_AXI_WDATA,
            M_AXI_WSTRB   => M_AXI_WSTRB,
            M_AXI_WVALID  => M_AXI_WVALID,
            M_AXI_WREADY  => M_AXI_WREADY,
            M_AXI_BRESP   => M_AXI_BRESP,
            M_AXI_BVALID  => M_AXI_BVALID,
            M_AXI_BREADY  => M_AXI_BREADY,
            M_AXI_ARADDR  => M_AXI_ARADDR,
            M_AXI_ARVALID => M_AXI_ARVALID,
            M_AXI_ARREADY => M_AXI_ARREADY,
            M_AXI_RDATA   => M_AXI_RDATA,
            M_AXI_RRESP   => M_AXI_RRESP,
            M_AXI_RVALID  => M_AXI_RVALID,
            M_AXI_RREADY  => M_AXI_RREADY);

end;
