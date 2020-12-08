----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    
-- Design Name: 
-- Module Name:    UartTX - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: UART TX  8 bits data, 1 stop bit, no parity bit
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

entity UartTX is
    generic(constant ticks_por_bit : natural := 868 ); --868 for 115200 bauds
    port(
         clock : in std_logic;
		 start_TX : in std_logic;                      --It allows to start TX
		 byte_TX : in std_logic_vector(7 downto 0);	   --Word to TX
         tx_data_serial : out std_logic			       
         );
end UartTX;

architecture Behavioral of UartTX is

	type estados is (idle, tx_StartBit, tx_Data, tx_StopBit);
	signal state : estados := idle;								--Start in idle
	signal ticks_counted : integer range 0 to ticks_por_bit;
	signal dataPosition : integer range 0 to 7 := 0;
	signal b_byte_TX : std_logic_vector(7 downto 0) := (others => '0');					

begin

	UART_TX: process(clock) is
	begin
		if(rising_Edge(clock)) then
		
			case state is
			
				when idle =>
					--o_tx_dv <= '0';
					tx_data_serial <= '1';									--Idle
					dataPosition <= 0;
					ticks_counted <= 0;
					if(start_TX = '1') then								
						b_byte_TX <= byte_TX;								
						state <= tx_StartBit;
					else
						state <= idle;
					end if;
				
				when tx_StartBit =>
					tx_data_serial <= '0';
					if(ticks_counted < (ticks_por_bit-1)) then
						ticks_counted <= ticks_counted + 1;
						state <= tx_StartBit;
					else
						ticks_counted <= 0;
						state <= tx_Data;
					end if;
					
				when tx_Data =>
					tx_data_serial <= b_byte_TX(dataPosition);
					if(ticks_counted < (ticks_por_bit-1)) then
						ticks_counted <= ticks_counted + 1;
						state <= tx_Data;
					else
						ticks_counted <= 0;
						if(dataPosition < 7) then
							dataPosition <= dataPosition + 1;
							state <= tx_Data;
						else
							dataPosition <= 0;
							state <= tx_StopBit;
						end if;	
					end if;
				
				when tx_StopBit =>
					tx_data_serial <= '1';
					if(ticks_counted < (ticks_por_bit-1)) then 	
						ticks_counted <= ticks_counted + 1;
						state <= tx_StopBit;
					else
						ticks_counted <= 0;
						state <= idle;
					end if;
			end case;
		end if;
	end process UART_TX;



end Behavioral;

