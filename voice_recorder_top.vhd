----------------------------------------------------------------------------------
-- Company: 			Engs 31 16X
-- Engineer: 			Eric Hansen
-- 
-- Create Date:    	 	07/22/2016
-- Design Name: 		
-- Module Name:    		lab5_top 
-- Project Name: 		Lab5
-- Target Devices: 		Digilent Basys3 (Artix 7)
-- Tool versions: 		Vivado 2016.1
-- Description: 		SPI Bus lab
--				
-- Dependencies: 		mux7seg, multiplexed 7 segment display
--						pmod_ad1, SPI bus interface to Pmod AD1
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
--use ieee.math_real.all;				-- needed for automatic register sizing

library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity voice_recorder is
port (mclk		: in std_logic;	    -- FPGA board master clock (100 MHz)
       
      play_data : in std_logic;     --control buttons
      record_data : in std_logic;
      echo_data : in std_logic;
      stop_data : in std_logic;
      
      spi_sclk : out std_logic;
      spi_sclk2 : out std_logic;
      
      spi_csm : out std_logic;
      spi_csa : out std_logic;
      
      spi_sdata : in std_logic;     --in from mic
      
      take_sample_test : out std_logic;
      test_out : out std_logic    
      ); 
end voice_recorder;

architecture Behavioral of voice_recorder is
-- YOUR COMPONENT DECLARATIONS GO HERE
component pmod_mic is
Port (	sclk	: in std_logic;
		ss	: out std_logic;
		mic_audio_in : in std_logic;
		rec_enable : in std_logic;
		take_sample : in std_logic;
		write_add : out std_logic_vector(16 downto 0);
        ad_data	: out std_logic_vector(15 downto 0));
end component;

component pmod_amp is
Port ( sclk : in std_logic;
       ss : out std_logic;
       amp_audio_in : in std_logic_vector(15 downto 0);
       ram_read_address : out std_logic_vector(16 downto 0);
       bit_out : out std_logic;
       play_en : in std_logic;
       take_sample : in std_logic);
end component;

component state_machine is 
Port (  
        sclk : in std_logic;
        
        --button presses
        play_start : in std_logic;
        rec_start : in std_logic;
        stop : in std_logic;
        echo : in std_logic;
        
        --control signals for amp and mic
        play_en : out std_logic;
        rec_en : out std_logic;
        
        --control for register        
        write_address : in std_logic_vector(16 downto 0);
        read_address : in std_logic_vector(16 downto 0);
        write_enable : out std_logic_vector(0 downto 0);
        read_enable : out std_logic;
        reg_address : out std_logic_vector(16 downto 0);
        mic_data_out : out std_logic_vector(15 downto 0);
        mic_data_in : in std_logic_vector(15 downto 0));
end component;

component blk_mem_gen_0 is
PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
end component;

component Monopulser is 
PORT ( 	clk		: 	in 	STD_LOGIC;
		sig_in 	: 	in 	STD_LOGIC;
		Sig_out	:	out	STD_LOGIC);
end component;

component debounce is 
PORT(
    clk     : IN  STD_LOGIC;  -- assumes 100Mhz clock
    button  : IN  STD_LOGIC;  -- input signal to be debounced
    result  : OUT STD_LOGIC); -- debounced signal out
END component;
-------------------------------------------------
-- SIGNAL DECLARATIONS 
-- Signals for the serial clock divider, which divides the 100 MHz clock down to 1 MHz
constant SCLK_DIVIDER_VALUE: integer := 100 / 2;
--constant SCLK_DIVIDER_VALUE: integer := 5;     -- for simulation
constant COUNT_LEN: integer := 30;
signal sclkdiv: unsigned(COUNT_LEN-1 downto 0) := (others => '0');  -- clock divider counter
signal sclk_unbuf: std_logic := '0';    -- unbuffered serial clock 
signal sclk: std_logic := '0';          -- internal serial clock

-- Signals for the sampling clock, which ticks at 10 Hz
constant SAMPLING_RATE: integer := 30000;          -- 10 Hz
constant SAMPLE_CLK_DIVIDER_VALUE: integer := 1E6 / SAMPLING_RATE;
constant SAMPLE_CLK_LEN: integer := 30;
signal sample_clkdiv: unsigned(SAMPLE_CLK_LEN-1 downto 0) := (others => '0');
signal take_sample : std_logic := '0';

-- SIGNAL DECLARATIONS FOR YOUR CODE GO HERE
signal ad_data: std_logic_vector(15 downto 0) := (others => '0');	-- A/D output
signal mic2reg : std_logic_vector(15 downto 0) := "0000000000000000";
signal fil2rom : std_logic_vector(15 downto 0) := "0000000000000000";
signal reg2amp : std_logic_vector(15 downto 0) := "0000000000000000";
signal mic_send_to_register : std_logic_vector(15 downto 0) := "0000000000000000";

--State machine wires
signal rec_mac2mic : std_logic := '0';
signal play_mac2amp : std_logic := '0';
signal clear_from_mac : std_logic := '0';

signal mach2write : std_logic_vector(0 downto 0) := "0";
signal mach2read : std_logic := '0';
signal mic2mac_write_address : std_logic_vector(16 downto 0) := "00000000000000000";
signal amp2mac_read_address : std_logic_vector(16 downto 0) := "00000000000000000";
signal mac2reg_address : std_logic_vector(16 downto 0) := "00000000000000000";

--Monopulser wires
signal mono_rec2state : std_logic := '0';
signal mono_play2state : std_logic := '0';
signal mono_stop2state : std_logic := '0';
signal mono_echo2state : std_logic := '0';

--Debouncer wires
signal deb_rec_2mono : std_logic := '0';
signal deb_play_2mono : std_logic := '0';
signal deb_stop_2mono : std_logic := '0';
signal deb_echo_2mono : std_logic := '0';

--debug signals
signal mic2amp : std_logic_vector(15 downto 0) := "0000000000000000";
-------------------------------------------------
begin
-- Clock buffer for sclk
-- The BUFG component puts the signal onto the FPGA clocking network
Slow_clock_buffer: BUFG
	port map (I => sclk_unbuf,
		      O => sclk );
    
-- Divide the 100 MHz clock down to 2 MHz, then toggling a flip flop gives the final 
-- 1 MHz system clock
Serial_clock_divider: process(mclk)
begin
	if rising_edge(mclk) then
	   	if sclkdiv = SCLK_DIVIDER_VALUE-1 then 
			sclkdiv <= (others => '0');
			sclk_unbuf <= NOT(sclk_unbuf);
		else
			sclkdiv <= sclkdiv + 1;
		end if;
	end if;
end process Serial_clock_divider;

-- Further divide the 1 MHz clock down to make the take_sample pulse for the A/D
-- Makes a tick, not a 50% duty cycle clock
Sample_clock_divider: process(sclk)
begin
    if rising_edge(sclk) then
        if sample_clkdiv = SAMPLE_CLK_DIVIDER_VALUE-1 then
            sample_clkdiv <= (others => '0');
            take_sample <= '1';
        else
            sample_clkdiv <= sample_clkdiv+1;
            take_sample <= '0';
        end if;
        take_sample_test <= take_sample;
    end if;
end process Sample_clock_divider;
        
spi_sclk <= sclk;
spi_sclk2 <= sclk;
-- INSTANTIATE THE A/D CONVERTER SPI BUS INTERFACE COMPONENT
pmodM : pmod_mic port map (
        sclk => sclk,
        ss => spi_csm,
        mic_audio_in => spi_sdata,
        rec_enable => rec_mac2mic,
        write_add => mic2mac_write_address,
        take_sample => take_sample,
        ad_data => mic_send_to_register);
        --ad_data => mic2amp);

pmodA : pmod_amp port map (
        sclk => sclk,
        play_en => play_mac2amp,
        bit_out => test_out,
        ss => spi_csa,
        ram_read_address => amp2mac_read_address,
        take_sample => take_sample, 
        amp_audio_in => reg2amp);
        --amp_audio_in => mic2amp);

state_mac : state_machine port map  (
        sclk => sclk,
        
        play_start => mono_play2state,
        rec_start => mono_rec2state,
        stop => mono_stop2state,
        echo => echo_data,
        
        play_en => play_mac2amp,
        rec_en => rec_mac2mic,
        
        --set enables for block
        write_enable => mach2write,
        read_enable => mach2read,
        
        --get addresses for read/write
        write_address => mic2mac_write_address,
        read_address => amp2mac_read_address,
        
        --read/write to send to block
        reg_address => mac2reg_address,
        mic_data_in => mic_send_to_register,
        mic_data_out => mic2reg
        );
        
ram_block : blk_mem_gen_0 port map (
        clka => sclk,
        ena => mach2read,
        wea => mach2write,
        addra => mac2reg_address,
        dina => mic2reg,
        douta => reg2amp);
        
monopulse_record : Monopulser port map(
        clk => sclk,
        sig_in => deb_rec_2mono,
        --sig_in => record_data,
        sig_out => mono_rec2state);

monopulse_play : Monopulser port map(
        clk => sclk,
        sig_in => deb_play_2mono,
        --sig_in => play_data,
        sig_out => mono_play2state);

monopulse_stop : Monopulser port map(
        clk => sclk,
        sig_in => deb_stop_2mono,
        --sig_in => play_data,
        sig_out => mono_stop2state);

--monopulse_echo : Monopulser port map(
--        clk => sclk,
--        sig_in => deb_echo_2mono,
--        --sig_in => play_data,
--        sig_out => mono_echo2state);

debounce_record : debounce port map(
        clk => mclk,
        button => record_data,
        result => deb_rec_2mono);

debounce_play : debounce port map(
        clk => mclk,
        button => play_data,
        result => deb_play_2mono);

debounce_stop : debounce port map(
        clk => mclk,
        button => stop_data,
        result => deb_stop_2mono);
        
--debounce_echo : debounce port map(
--                clk => mclk,
--                button => echo_data,
--                result => deb_echo_2mono);
        
end Behavioral; 