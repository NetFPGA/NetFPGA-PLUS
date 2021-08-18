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
--        axis_sim_stim.vhd
--
--  Library:
--        hw/std/cores/axi_sim_stim_v1_0_0
--
--  Module:
--        axi_sim_stim
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

use std.textio.all;
use ieee.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.axis_sim_pkg.all;

entity axis_sim_stim is
    generic (
        C_M_AXIS_DATA_WIDTH : integer := 512;
        C_M_AXIS_TUSER_WIDTH: integer := 128;
        input_file          : string  := "../../stream_data_in.axi"
        );
    port (
        ACLK          : in std_logic;
        ARESETN       : in std_logic;

        -- axi streaming data interface
        M_AXIS_TDATA  : out std_logic_vector( C_M_AXIS_DATA_WIDTH-1 downto 0 );
        M_AXIS_TKEEP  : out std_logic_vector( C_M_AXIS_DATA_WIDTH/8-1 downto 0 );
        M_AXIS_TUSER  : out std_logic_vector( C_M_AXIS_TUSER_WIDTH-1 downto 0 );
        M_AXIS_TVALID : out std_logic;
        M_AXIS_TREADY : in  std_logic;
        M_AXIS_TLAST  : out std_logic;

	counter       : in std_logic_vector(10 downto 0);
	activity_stim : out std_logic;
        barrier_req   : out std_logic;
        barrier_proceed : in std_logic
        );
end entity axis_sim_stim;

architecture rtl of axis_sim_stim is
    file f: text open read_mode is input_file;
 
	signal b : integer := 0;
	signal m : std_logic;
begin

    process
	
        -----------------------------------------------------------------------
        -- quiescent()
        --
        --      Quiesce outputs.
        procedure quiescent is
        begin
            M_AXIS_TDATA <= (others => '0');
            M_AXIS_TKEEP <= (others => '0');
            M_AXIS_TUSER <= (others => '0');
            M_AXIS_TLAST <= '0';
            M_AXIS_TVALID <= '0';
        end procedure;
        -----------------------------------------------------------------------
        -- wait_cycle()
        --
        --      Wait for N cycles (1 by default).
        procedure wait_cycle( n: natural := 1 ) is
            variable lp: natural := n;
        begin
            while lp /= 0 loop
                wait until rising_edge(ACLK);
                lp := lp - 1;
            end loop;
        end procedure;
        -----------------------------------------------------------------------
	variable l: line;
        variable i, x: integer := 0;
        variable c: character;
        variable ok, dontcare: boolean;
	variable barrier_count : integer := 0;
	variable exp_pkts: integer :=0;
	
    begin

        quiescent;                      -- sane initial outputs

        -- Wait for a couple cycles in case reset is not asserted straight
        -- away.
        --
        -- NB: Reset is ignored except at the beginning of simulation.
        wait_cycle( 10 );
        while ARESETN = '0' loop        -- wait until reset goes away
            wait_cycle;
        end loop;

	activity_stim <= '0';
        barrier_req <= '0';

        -- begin reading stimuli
        while not endfile( f ) loop
            -- Main dispatch: Get and parse input
	        readline( f, l );
	        lookahead_char( l, c, ok );
	        next when not ok;

		if c = 'B' then 
		    barrier_count := barrier_count + 1;	        
		    read_char( l, c );
		    parse_int( l, x );
		    report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
		    write(l, string'("Info: Input file contains:"));
		    writeline( output, l );
		    write(l, string'("Info: ") & integer'image(barrier_count) & string'(" barriers"));
		    writeline( output, l ); 
		    quiescent;
		    wait for ( x * 1 ns);
		    wait_cycle;
		  
		elsif c = 'N' then
		    read_char( l, c );
		    parse_int( l, i );
		    exp_pkts := exp_pkts + i;
		    quiescent;
		    wait for ( i * 1 ns);
		    wait_cycle;

		elsif c = 'S' then 
		    read_char( l, c );
		    parse_int( l, i );
		    report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
		    write(l, string'("Info: ") & integer'image(i) & string'(" ingress packets"));
        	    writeline( output, l );
		    quiescent;
		    wait for ( i * 1 ns);
		    wait_cycle;

			report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
			write(l, string'("Info: barrier request: expecting ") & integer'image(exp_pkts) & string'(" pkts")); 
			writeline( output, l );
			wait for 1 ns;
			
			while (to_integer(UNSIGNED(counter)) /= exp_pkts) loop
                     		wait until (to_integer(UNSIGNED(counter)) >= exp_pkts);
                  	end loop;
			
			barrier_req <= '1'; 
			while (barrier_proceed = '0') loop
				wait until (barrier_proceed = '1');
				end loop;
			wait for 1 ns;
		   	barrier_req <= '0';
			wait until (barrier_proceed = '0');
			
			report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
			write(l, string'("Info: barrier complete"));
			writeline( output, l ); 	     

            -- operator *(N): wait for N cycles
                elsif c = '*' then             -- wait n cycles
            	    read_char( l, c );      -- discard operator
            	    parse_int( l, i );
            	    quiescent;
            	    wait_cycle( i );

            -- operator @(N): wait until absolute time N ns
            	elsif c = '@' then          -- wait until absolute time (ns)              
		    read_char( l, c );      -- discard operator
         	    parse_int( l, i );
            	    quiescent;
		    wait for ( i * 1 ns);
                    wait_cycle;

            -- operator +(N): wait for N ns
            	elsif c = '+' then          -- wait for relative time (ns)
               	    read_char( l, c );      -- discard operator
                    parse_int( l, i );
                    quiescent;
		    wait for ( i * 1 ns);                
                    wait_cycle;

            -- data transfer: a cycle containing active data
            	else
                     wait for 0.5ns;
                    	M_AXIS_TVALID <= '1';
			activity_stim <= '1';
                -- parse out each component of the stimulus
                    	parse_slv( l, M_AXIS_TDATA, dontcare );
                    	assert not dontcare
                        	report input_file & ": bad input: nf_axis_sim_stim doesn't accept 'don't-cares'"
                        	severity failure;
                    	read_char( l, c );      -- discard ','
                    	parse_slv( l, M_AXIS_TKEEP, dontcare );
                    	assert not dontcare
                        	report input_file & ": bad input: nf_axis_sim_stim doesn't accept 'don't-cares'"
                        	severity failure;
                    	read_char( l, c );      -- discard ','
                    	parse_slv( l, M_AXIS_TUSER, dontcare );
                    	assert not dontcare
                        	report input_file & ": bad input: nf_axis_sim_stim doesn't accept 'don't-cares'"
                        	severity failure;
                    	read_char( l, c );      -- read terminal flag for TLAST...
                    	if c = '.' then         -- '.' == end of packet
                        	M_AXIS_TLAST <= '1';
				report "Time is " & integer'image(now / 1 ns) & string'(" ns.");
				write(l, string'("Sending next ingress packet")); 
				writeline( output, l ); 
                    	elsif c = ',' then      -- ',' == more pkt data to follow
                        	M_AXIS_TLAST <= '0';
                    	else
                        	assert false
                            	report input_file & ": bad input: expected terminal ',' or '.'"
                            	severity failure;
                    	end if;
                    	wait_cycle;
		
                -- block until target ready
                    	while M_AXIS_TREADY /= '1' loop
                        wait_cycle;
                    	end loop;
		activity_stim <= '0';	
                end if;
	 	
            deallocate(l);              -- finished with input line
        end loop;

        -- End of stimuli.
        quiescent;
        write( l, string'("") );
        writeline( output, l );
        write( l, input_file & string'(": end of stimuli @ ") &
                  integer'image(now / 1 ns) & string'(" ns.") );
        writeline( output, l );
        wait;
    end process;
end;
