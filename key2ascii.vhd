----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:55:25 11/10/2026 
-- Design Name: 
-- Module Name:    ket2ascii - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity key2ascii is
    port (
        key_code: in std_logic_vector(7 downto 0);
        ascii_code: out std_logic_vector(7 downto 0)
    );
end key2ascii;

architecture arch of key2ascii is
begin
    with key_code select
        ascii_code <=
        X"30" when X"45", -- 0
        X"31" when X"16", -- 1
        X"32" when X"1E", -- 2
        X"33" when X"26", -- 3
        X"34" when X"25", -- 4
        X"35" when X"2E", -- 5
        X"36" when X"36", -- 6
        X"37" when X"3D", -- 7
        X"38" when X"3E", -- 8
        X"39" when X"46", -- 9

        X"41" when X"1C", -- A
        X"42" when X"32", -- B
        X"43" when X"21", -- C
        X"44" when X"23", -- D
        X"45" when X"24", -- E
        X"46" when X"2B", -- F (corrigido: scan code de F é 0x2B)
        X"47" when X"34", -- G
        X"48" when X"33", -- H
        X"49" when X"43", -- I
        X"4A" when X"3B", -- J
        X"4B" when X"42", -- K
        X"4C" when X"4B", -- L
        X"4D" when X"3A", -- M
        X"4E" when X"31", -- N
        X"4F" when X"44", -- O (corrigido: scan code de O é 0x44)
        X"50" when X"4D", -- P
        X"51" when X"15", -- Q
        X"52" when X"2D", -- R
        X"53" when X"1B", -- S
        X"54" when X"2C", -- T
        X"55" when X"3C", -- U
        X"56" when X"2A", -- V
        X"57" when X"1D", -- W
        X"58" when X"22", -- X
        X"59" when X"35", -- Y
        X"5A" when X"1A", -- Z

        X"20" when X"29", -- espaço
        X"0D" when X"5A", -- enter
        X"08" when X"66", -- backspace
        X"2A" when others; -- *
end arch;

