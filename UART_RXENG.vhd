----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alfredo Gonzalez Calvin
-- 
-- Create Date: 31.01.2020 17:45:27
-- Design Name: 
-- Module Name: UartRX - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Receptor de UART de 8 bits con start, stop bit y no bit de paridad
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


--10416 for 9600 bauds


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity UartRX is
    generic(
    constant ticks_por_bit : natural := 868   --868 for  115200 bauds 
    );
    port(
         clock : in std_logic;
         rx_data : in std_logic;						--Serial RX
         output_data : out std_logic_vector(7 downto 0);
         o_rx_rcvwd : out std_logic                        --To tell the TX that we have received a word so he can TX
         );                                             
end UartRX;

architecture Behavioral of UartRX is

    type states is (idle, rx_StartBit, rx_DataBit, rx_StopBit);
    signal state: states := idle;                              		--Idle inicialization
    
    signal ticks_counted : integer range 0 to ticks_por_bit-1;             
    signal dataPos       : integer range 0 to 7 := 0;                        
    signal byte_Received : std_logic_vector(7 downto 0);

begin

    establecer_fsm : process(clock) is
    begin
        if(rising_edge(clock)) then
            
            o_rx_rcvwd <= '0';											--Default
            case state is
               
                when idle =>
                    ticks_counted <= 0;
                    dataPos <= 0;
                    if(rx_data = '0') then                              --Start bit
                        state <= rx_StartBit;
                    else
                        state <= idle;
                    end if;
               
                when rx_StartBit =>
                    if(ticks_counted = (ticks_por_bit-1)/2) then       --IF we are at the middle of the bit...
                        if(rx_data = '0') then                         --and start bit is still 0, data is coming
                           ticks_counted <= 0;                         
                           state <= rx_DataBit;              	
                                                                        
                        else
                           state <= idle;
                        end if;
                    else
                        ticks_counted <= ticks_counted + 1;
                        state <= rx_StartBit;
                    end if;
                    
                when rx_DataBit =>
                    if(ticks_counted < (ticks_por_bit-1)) then		 	-- Since we started at the middle, and we are sampling at the middle
                       ticks_counted <= ticks_counted + 1;            
                       state <= rx_DataBit;
                    else												
                        ticks_counted <= 0;
                        byte_Received(dataPos) <= rx_data;
                        if(dataPos < 7) then
                            state <= rx_DataBit;
                            dataPos <= dataPos + 1;
                        else
                            dataPos <= 0;
                            state <= rx_StopBit;
                        end if;
                    end if;
              
                --Stop bit es siempre a 1
                when rx_StopBit =>
                    if(ticks_counted < (ticks_por_bit - 1)) then
                        ticks_counted <= ticks_counted + 1;
                        state <= rx_StopBit;
                    else
                        o_rx_rcvwd <= '1';								--Data received, TX can Transmit
                        state <= idle;
                        ticks_counted <= 0;
                    end if;
        
                when others =>
                    state <= idle;		
            end case;
        end if;
    end process establecer_fsm;
    
      
	output_data <= byte_Received;

end Behavioral;
