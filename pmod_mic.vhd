----------------------------------------------------------------------------------
-- Company: ENGS 31
-- Engineer: Julia Holgado and Khalil Jackson
-- 
-- Create Date: 05/03/2017 11:31:48 AM
-- Design Name: 
-- Module Name: pmod_ad1 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pmod_mic is
port (	sclk	: in std_logic;
		ss	: out std_logic;
		mic_audio_in : in std_logic;
		take_sample : in std_logic;
		rec_enable : in std_logic;
		write_add : out std_logic_vector(16 downto 0);
        ad_data	: out std_logic_vector(15 downto 0));
end pmod_mic;

architecture Behavior of pmod_mic is

signal shift_en, load_en, ser_data_reg : std_logic;
signal shift_reg : std_logic_vector(15 downto 0);
type state_type is (idle, shift, update);
signal current : state_type := idle;
signal next_state : state_type;
signal count : unsigned(4 downto 0) := "00000";
signal write_add_buff : std_logic_vector(16 downto 0) := "00000000000000000";

BEGIN

process(sclk) is
begin
	if rising_edge(sclk) then
    	current <= next_state;
    end if;
end process;

state : process(current, rec_enable, count, take_sample) is
begin
next_state <= current;
shift_en <= '0';
load_en <= '0';
ss <= '1';
	case(current) is
    	when idle =>  if rec_enable = '1' and take_sample = '1' then
        				next_state <= shift;
                      else next_state <= idle;                    	   
        			  end if;
        when shift =>	shift_en <= '1';
                        ss <= '0';
                        if shift_en = '1' then
        					if count = 15 then
                            	next_state <= update;
                            else 
                            	next_state <= shift;	
                            end if;
        				end if;
        when update =>	load_en <= '1';
                        next_state <= idle;
        when others => next_state <= idle;
                       shift_en <= '0';
                       load_en <= '0';
    end case;
end process;

s_proc : process(sclk) is
begin
	if rising_edge(sclk) then
    	if shift_en = '1' then
        	shift_reg <= shift_reg(14 downto 0) & mic_audio_in;
        end if;
    end if;
end process;

count_proc : process(sclk) is 
begin
    if rising_edge(sclk) then
        if shift_en = '1' then
            if count = 15 then
                count <= "00000";
            else
                count <= count + 1;
            end if;
        end if;
    end if;
end process;

l_proc : process(sclk) is
begin
if rising_edge(sclk) then 
	if load_en = '1' then
    	ad_data <= shift_reg;
    	if write_add_buff = "10101111110010000" then
    	   write_add_buff <= "00000000000000000";
    	else
    	   write_add_buff <= std_logic_vector(unsigned(write_add_buff) + 1);
    	end if;
    end if;
    if write_add_buff = "10101111110010000" then
        write_add_buff <= "00000000000000000";
    end if;
end if;
end process;

write_add <= std_logic_vector(unsigned(write_add_buff) - 1);


end behavior;
