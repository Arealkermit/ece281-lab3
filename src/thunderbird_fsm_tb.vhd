--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port(
		i_clk, i_reset    : in std_logic;
		i_left, i_right   : in std_logic;
		o_lights_L        : out std_logic_vector(2 downto 0);
		o_lights_R        : out std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

	-- test I/O signals
	signal w_clk      : std_logic := '0';
	signal w_reset    : std_logic := '0';
	signal w_left     : std_logic := '0';
	signal w_right    : std_logic := '0';
	signal w_lights_L : std_logic_vector(2 downto 0) := "000";
	signal w_lights_R : std_logic_vector(2 downto 0) := "000";
	-- constants
	constant k_clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm
	   port map(
	       i_clk    => w_clk,
	       i_reset  => w_reset, 
	       i_left   => w_left,
	       i_right  => w_right,
	       o_lights_L => w_lights_L,
	       o_lights_R => w_lights_R
	  );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
   clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process;
    

	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	--Tests to performm:
	-- 1. Apply reset and verify all lights off.
	-- 2. Verify the left blinking battern
	-- 3. "Activate" Left switch and make sure a pattern repeats
	-- 4. Change input or release and make sure the current state pattern finishes before switching to other state.
	-- 5. Verify the right blinking pattern
	-- 6. Verify the hazard lights blink in pattern
	-- 7. Change input or release inputs during hazard pattern to make sure the pattern finishes before changing
	
		-- TEST 1
	sim_proc : process
	begin
		w_left  <= '0';
		w_right <= '0';
		w_reset <= '1';
		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "Reset failed: lights should be OFF"
			severity failure;

		w_reset <= '0';
		wait for k_clk_period;

		-- TEST 2
		w_left <= '1';
		wait for k_clk_period;
		assert (w_lights_L = "001" and w_lights_R = "000")
			report "LEFT test failed: expected L1"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "011" and w_lights_R = "000")
			report "LEFT test failed: expected L2"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "111" and w_lights_R = "000")
			report "LEFT test failed: expected L3"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "LEFT test failed: expected OFF after L3"
			severity failure;

		-- TEST 3
		wait for k_clk_period;
		assert (w_lights_L = "001" and w_lights_R = "000")
			report "LEFT hold test failed: pattern did not repeat"
			severity failure;

		-- TEST 4
		w_left <= '0';
		wait for k_clk_period;
		assert (w_lights_L = "011" and w_lights_R = "000")
			report "Mid-pattern LEFT release failed: expected L2"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "111" and w_lights_R = "000")
			report "Mid-pattern LEFT release failed: expected L3"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "Mid-pattern LEFT release failed: expected OFF"
			severity failure;

		-- TEST 5
		w_right <= '1';
		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "001")
			report "RIGHT test failed: expected R1"
			severity failure;

		-- change request in the middle of right pattern
		w_right <= '0';
		w_left  <= '1';

		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "011")
			report "Mid-pattern input change failed: expected R2"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "111")
			report "Mid-pattern input change failed: expected R3"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "Mid-pattern input change failed: expected OFF after R3"
			severity failure;

		-- now that we are back at off, left lights should take effect
		wait for k_clk_period;
		assert (w_lights_L = "001" and w_lights_R = "000")
			report "Mid-pattern input change failed: LEFT did not begin after OFF"
			severity failure;

		-- TEST 6
		w_reset <= '1';
		w_left  <= '0';
		w_right <= '0';
		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "Reset before hazard test failed"
			severity failure;

		w_reset <= '0';
		wait for k_clk_period;

		w_left  <= '1';
		w_right <= '1';

		wait for k_clk_period;
		assert (w_lights_L = "111" and w_lights_R = "111")
			report "Hazard test failed: expected ALL ON"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "Hazard test failed: expected ALL OFF"
			severity failure;

		wait for k_clk_period;
		assert (w_lights_L = "111" and w_lights_R = "111")
			report "Hazard test failed: expected ALL ON again"
			severity failure;

		-- TEST 7
		w_left  <= '0';
		w_right <= '1';

		-- hazard should still go back to off first
		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "000")
			report "Hazard exit test failed: expected OFF first"
			severity failure;

		-- then right lights should begin
		wait for k_clk_period;
		assert (w_lights_L = "000" and w_lights_R = "001")
			report "Hazard exit test failed: expected R1 after OFF"
			severity failure;

		report "All thunderbird_fsm testbench checks passed." severity note;
		wait;
	
	end process;
	-----------------------------------------------------	
	
end test_bench;
