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

-- Sean los ticks_por_bit los pulsos de reloj necearios para cada bit, calculados de la siguiente manera:
-- ticks_por_bit = Fin/(Fuart), como queremos 115200 Baudios(bit per sec) -> ticks_por_bit = 100Mhz/115200 = 868
--Como haremos el "sampling" en la mitad de los datos entonces contaremos hasta la mitad de esos ticks por bit en el bit de start,
--Entonces como al estar en la mitad del bit de start pasamos ya al estado siguiente que es el de los datos, a partir de ahi
--contaremos hasta ticks_por_bit para samplear la mitad de cada bit, ver mis folios
--10416 para 9600 baudios


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity UartRX is
    generic(
    constant ticks_por_bit : natural := 868   --868 seria para 115200 baudios 
    );
    port(
         clock : in std_logic;
         rx_data : in std_logic;						--Por donde recibimos los bits 
         output_data : out std_logic_vector(7 downto 0);
         o_rx_dv : out std_logic                        --Señal para el transmisor interno de la basys para decirle que he recibido una nueva
         );                                             --palabra y asi poder enviarla, esto es opcional si solo queremos un receptor
end UartRX;

architecture Behavioral of UartRX is

    type estados is (reposo, rx_StartBit, rx_DataBit, rx_StopBit);
    signal estado_actual: estados := reposo;                               --Lo inicializamos a reposo(en el que estamos a 1)
    
    signal ticks_contados : integer range 0 to ticks_por_bit-1;             --Como empieza en 0 pues -1
    signal posicionData : integer range 0 to 7 := 0;                        --Posicion del vector de data de salida(8 bits)
    signal byte_Recibido : std_logic_vector(7 downto 0);

begin

    establecer_fsm : process(clock) is
    begin
        if(rising_edge(clock)) then
            
            o_rx_dv <= '0';												--Lo ponemos a 0 por default
            case estado_actual is
               
                when reposo =>
                    ticks_contados <= 0;
                    posicionData <= 0;
                    if(rx_data = '0') then                              --Bit empiece
                        estado_actual <= rx_StartBit;
                    else
                        estado_actual <= reposo;
                    end if;
               
                when rx_StartBit =>
                    if(ticks_contados = (ticks_por_bit-1)/2) then       --Si estamos en la mitad del bit
                        if(rx_data = '0') then                          --Y siguie siendo 0 el bit de start esque empezamos
                           ticks_contados <= 0;                         --Reseteamos el contar para el siguiente estado
                           estado_actual <= rx_DataBit;              	--Pasamos al siguiente estado en esa mitad del bit entonces,
                                                                        --Ahora contaremos hasta (ticks_por_bit-1) por que hemos empezado en la mitad del start bit. entonces ya sampleamos la data en la mitad de los bits
                        else
                           estado_actual <= reposo;
                        end if;
                    else
                        ticks_contados <= ticks_contados + 1;
                        estado_actual <= rx_StartBit;
                    end if;
                    
                when rx_DataBit =>
                    if(ticks_contados < (ticks_por_bit-1)) then			--Si todavia no hemos contado todos los ticks por bit, como habiamos..
                       ticks_contados <= ticks_contados + 1;            --..empezado en la mitad del startBit ahora estamos en la mitad del bit 1
                       estado_actual <= rx_DataBit;
                    else												--Si ya hemos contado el tiempo de sampleo sampleamos la señal
                        ticks_contados <= 0;
                        byte_recibido(posicionData) <= rx_data;
                        if(posicionData < 7) then
                            estado_actual <= rx_DataBit;
                            posicionData <= posicionData + 1;
                        else
                            posicionData <= 0;
                            estado_actual <= rx_StopBit;
                        end if;
                    end if;
              
                --Stop bit es siempre a 1
                when rx_StopBit =>
                    if(ticks_contados < (ticks_por_bit - 1)) then
                        ticks_contados <= ticks_contados + 1;
                        estado_actual <= rx_StopBit;
                    else
                        o_rx_dv <= '1';								--Hemos recibido un dato pues le decimos al transmisor interno que empiece a TX
                        estado_actual <= reposo;
                        ticks_contados <= 0;
                    end if;
        
                when others =>
                    estado_actual <= reposo;		
            end case;
        end if;
    end process establecer_fsm;
    
      
	output_data <= byte_Recibido;

end Behavioral;
