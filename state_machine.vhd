----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/23/2017 03:12:39 PM
-- Design Name: 
-- Module Name: state_machine - Behavioral
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

entity state_machine is
Port (  
        sclk : in std_logic;
        
        --button presses
        play_start : in std_logic;
        rec_start : in std_logic;
        stop : in std_logic;
        echo : in std_logic;
        
        --control signals for amp, mic, block
        play_en : out std_logic;
        rec_en : out std_logic;
        
        --addresses/input for register from mic and amp
        write_address : in std_logic_vector(16 downto 0);
        read_address : in std_logic_vector(16 downto 0);
        mic_data_in : in std_logic_vector(15 downto 0);
        
        --enable signals for register
        write_enable : out std_logic_vector(0 downto 0);
        read_enable : out std_logic;
        
        --mic data and address pointer
        reg_address : out std_logic_vector(16 downto 0);
        mic_data_out : out std_logic_vector(15 downto 0);
        new_read_limit : out std_logic_vector(16 downto 0));
end state_machine;

architecture Behavioral of state_machine is

signal reg_slot_count : integer;
signal echo_en : std_logic;
signal echo_count : integer := 0;
type state_type is (idle, recording, play, clearing);
signal current : state_type := idle;
signal next_state : state_type;
signal address_buff : std_logic_vector(16 downto 0) := "00000000000000000";

begin

state_change : process(sclk) is
begin
    if rising_edge(sclk) then 
        current <= next_state;
    end if;
end process;

state_logic : process(play_start, rec_start, stop, echo, write_address, read_address, current) is
begin
--default state
 next_state <= current;
 --component control
 rec_en <= '0';
 play_en <= '0';
 --RAM control
 write_enable <= "0";
 read_enable <= '0';
 reg_address <= address_buff;
 mic_data_out <= mic_data_in;
    case(current) is
        when idle => if (rec_start = '1') then 
                        next_state <= recording;                      
                     end if;
                     if echo = '1' and play_start = '1' then
                        next_state <= play;
                        echo_en <= '1';
                     end if;
                     if echo = '1' and echo_en = '1' then
                        next_state <= play;
                        echo_en <= '1';
                     end if;
                     if (play_start = '1') then
                        next_state <= play;
                        echo_en <= '0';                       
                     end if;
        when recording => rec_en <= '1';
                          write_enable <= "1";
                          read_enable <= '1';
                          --play_en <= '1';
                          reg_address <= write_address;
                          if (write_address = "10101111110001111") then
                            next_state <= idle;
                          end if;
       when play => play_en<= '1';
                    write_enable <= "0";
                    read_enable <= '1';
                    reg_address <= read_address;
                    if echo = '1' then
                        echo_en <= '1';
                    else
                        echo_en <= '0';
                    end if;
                    if (stop = '1') then
                      next_state <= idle;                    
                      end if;
                    if (read_address = "10101111110001111") then
                        next_state <= idle;                           
                    end if;                                
         when others => next_state <= idle;
                        rec_en <= '0';
                        play_en <= '0';
    end case;
end process;

               
end Behavioral;
