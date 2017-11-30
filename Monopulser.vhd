----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/27/2017 02:34:52 PM
-- Design Name: 
-- Module Name: Monopulser - Behavioral
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
use IEEE.std_logic_1164.all;


ENTITY Monopulser IS
PORT ( 	clk		: 	in 	STD_LOGIC;
		sig_in 	: 	in 	STD_LOGIC;
		Sig_out	:	out	STD_LOGIC);
end Monopulser;


ARCHITECTURE behavior of Monopulser is
type state_type is (Waitpress,pulse, waitrelease);
signal current_state, next_state : state_type;


BEGIN
process(clk) is
begin
	if rising_edge(clk) then
		current_state <= next_state;
	end if;
end process;


process(current_state, sig_in) is
begin
	sig_out <= '0';
    next_state <= current_state;
	case (current_state) is
    
    	when (waitpress) 	=> 	if (sig_in = '1') then
        							next_state <= pulse;
  								end if;
        when (pulse)		=>	sig_out <= '1';
        						next_state <= waitrelease;
        when (waitrelease)	=>	if (sig_in = '0') then
        							next_state <= waitpress;
      							end if;
        when others => next_state <= waitpress;
    end case;

end process;


end behavior;
