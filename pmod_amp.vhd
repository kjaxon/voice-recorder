----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/23/2017 02:57:31 PM
-- Design Name: 
-- Module Name: pmod_amp - Behavioral
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

entity pmod_amp is
Port ( sclk : in std_logic;
       ss : out std_logic;
       amp_audio_in : in std_logic_vector(15 downto 0);
       play_en : in std_logic;
       take_sample : in std_logic;
       ram_read_address : out std_logic_vector(16 downto 0);
       --audio_out : out std_logic_vector(15 downto 0));
       bit_out : out std_logic);       
end pmod_amp;

architecture Behavioral of pmod_amp is
signal buff   : std_logic_vector(15 downto 0);
signal pointer : unsigned(16 downto 0) := "00000000000000000";
signal count : integer := 15;
signal address_pointer : std_logic_vector(16 downto 0) := "00000000000000000";
signal shift_en, load_en, ser_data_reg : std_logic;
type state_type is (idle, shift, update);
signal current : state_type := idle;
signal next_state : state_type;

begin

state_change : process(sclk) is
begin
    if rising_edge(sclk) then 
        current <= next_state;
    end if;
end process;


state : process(current, play_en, count, take_sample) is
begin
next_state <= current;
shift_en <= '0';
load_en <= '0';
ss <= '1';
	case(current) is
    	when idle =>  if play_en = '1' and take_sample = '1' then
        				next_state <= shift;                        
                      else
                        next_state <= idle;
                        ss <= '1';
        			  end if;
        when shift => ss <= '0';
                      shift_en <='1';
        			  if count = 0 then
                           next_state <= update;
                      else 
                           next_state <= shift;
                      end if;
        when update => load_en <= '1';
                       next_state <= idle;
        when others => next_state <= idle;
                       shift_en <= '0';
                       load_en <= '0';
    end case;
end process;

load : process(sclk) is
begin
    if rising_edge(sclk) then
        if shift_en = '1' then
            bit_out <= buff(count);
        end if;
    end if;            
end process;
    
count_inc : process(sclk) is
begin
    if rising_edge(sclk) then
        if shift_en = '1' then
           count <= count - 1;
        end if;
        if count = 0 then
            count <= 15;                                   
        end if;          
     end if;
end process; 

reg_add_proc : process(sclk) is 
begin

if rising_edge(sclk) then
    if load_en = '1' then
        buff <= amp_audio_in;   
        if pointer = 89999 then
            pointer <= "00000000000000000";
        else
            pointer <= pointer + 1;
        end if;
    end if;
    if pointer = 89999 then
           pointer <= "00000000000000000";
    end if;
end if;
end process;
               
address_pointer <= std_logic_vector(pointer);
ram_read_address <= address_pointer;
    
end Behavioral;
