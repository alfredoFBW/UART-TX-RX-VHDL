----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:27:37 02/01/2020 
-- Design Name: 
-- Module Name:    UartTX - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Transmisor de UART con 8 bits de data y un stop bit, sin parity bit
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
-- Sean los ticks_por_bit los pulsos de reloj necearios para cada bit, calculados de la siguiente manera:
-- ticks_por_bit = Fin/(Fuart), como queremos 115200 Baudios(bit per sec) -> ticks_por_bit = 100Mhz/115200 = 868
-- Enviaremos los datos con esa anchura de bit si queremos una frecuencia de transmision de 115200 baudios

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UartTX is
    generic(constant ticks_por_bit : natural := 868 ); --868 seria para 115200 baudios
    port(
         clock : in std_logic;
		 start_TX : in std_logic;                      --Permite empezar la transimision
		 byte_TX : in std_logic_vector(7 downto 0);	   --Palabra a transmitir
         tx_data_serial : out std_logic			       --Transmision serie
		 --o_tx_dv : out std_logic					   --Señal opcional para decirle a alguna logica externa que ya he parado de transmitir
         );
end UartTX;

architecture Behavioral of UartTX is

	type estados is (reposo, tx_StartBit, tx_Data, tx_StopBit);
	signal estado_actual : estados := reposo;								--Empezamos en reposo
	signal ticks_contados : integer range 0 to ticks_por_bit;
	signal posicionData : integer range 0 to 7 := 0;
	signal b_byte_TX : std_logic_vector(7 downto 0) := (others => '0');					

begin

	UART_TX: process(clock) is
	begin
		if(rising_Edge(clock)) then
		
			case estado_actual is
			
				when reposo =>
					--o_tx_dv <= '0';
					tx_data_serial <= '1';									--Ponemos la linea a 1 que es el estado de idle
					posicionData <= 0;
					ticks_contados <= 0;
					if(start_TX = '1') then									--Si nos llega una señal de que hay que empezar a TX(puede ser un enter,
						b_byte_TX <= byte_TX;								--..de un propio receptor UART de la basys.. mirar UART_RX
						estado_actual <= tx_StartBit;
					else
						estado_actual <= reposo;
					end if;
				
				when tx_StartBit =>
					tx_data_serial <= '0';
					if(ticks_contados < (ticks_por_bit-1)) then
						ticks_contados <= ticks_contados + 1;
						estado_actual <= tx_StartBit;
					else
						ticks_contados <= 0;
						estado_actual <= tx_Data;
					end if;
					
				when tx_Data =>
					tx_data_serial <= b_byte_TX(posicionData);
					if(ticks_contados < (ticks_por_bit-1)) then
						ticks_contados <= ticks_contados + 1;
						estado_actual <= tx_Data;
					else
						ticks_contados <= 0;
						if(posicionData < 7) then
							posicionData <= posicionData + 1;
							estado_actual <= tx_Data;
						else
							posicionData <= 0;
							estado_actual <= tx_StopBit;
						end if;	
					end if;
				
				when tx_StopBit =>
					tx_data_serial <= '1';
					--o_tx_dv <= '1';							--Avisa a alguna logica interna o externa que ya estoy en el stop bit para que multiplexe la data a transmitir
					if(ticks_contados < (ticks_por_bit-1)) then --.Es opcional requiere timing en la otra logica, mirar Proyecto enconder cuadratura
						ticks_contados <= ticks_contados + 1;
						estado_actual <= tx_StopBit;
					else
						ticks_contados <= 0;
						estado_actual <= reposo;
					end if;
			end case;
		end if;
	end process UART_TX;



end Behavioral;

