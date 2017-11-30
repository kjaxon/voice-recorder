----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2017 03:17:07 PM
-- Design Name: 
-- Module Name: block_control - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity block_control is
Port ( 
        write_address_in : in std_logic_vector(3 downto 0);
        read_address_in : in std_logic_vector(3 downto 0);
        
        read_enable : out std_logic;
        write_enable : out std_logic_vector(0 downto 0);
        
        address_out : out std_logic_vector(3 downto 0));        
end block_control;

architecture Behavioral of block_control is

begin


end Behavioral;
