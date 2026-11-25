----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:10:51 11/10/2026 
-- Design Name: 
-- Module Name:    lcd_vhd - Behavioral 
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd is
    Port (
        CLK        : in  std_logic; -- Clock principal de 50 MHz da Spartan-3
        rst        : in  std_logic; -- Reset principal
        ps2d, ps2c : in  std_logic; -- Linhas do teclado PS/2
        LCD_DB     : out std_logic_vector(7 downto 0); -- Voo de dados do LCD
        RS         : out std_logic; -- Register Select
        RW         : out std_logic; -- Read/Write
        OE         : out std_logic; -- Enable (E)
        tecla      : out std_logic_vector(7 downto 0)
    );
end lcd;

architecture Behavioral of lcd is

    component kb_code
        port (
            clk, reset: in std_logic;
            ps2d, ps2c: in std_logic;
            rd_key_code: in std_logic;
            key_code: out std_logic_vector(7 downto 0);
            kb_buf_empty: out std_logic
        );
    end component kb_code;

    type mstate is (
        stPowerOn_Delay, stFunctionSet, stFunctionSet_Delay,
        stDisplayCtrlSet, stDisplayCtrlSet_Delay, stDisplayClear,
        stDisplayClear_Delay, stInitDne, stActWr, stCharDelay
    );

    type wstate is (stRW, stEnable, stIdle);

    -- Gerador de pulso de 1 microsegundo síncrono (50 MHz / 50 = 1 us)
    signal clk_cnt    : integer range 0 to 49 := 0;
    signal tick_1us   : std_logic := '0';

    signal count      : unsigned(16 downto 0) := (others => '0');
    signal delayOK    : std_logic := '0';
    signal stCur      : mstate := stPowerOn_Delay;
    signal stNext     : mstate;
    signal stCurW     : wstate := stIdle;
    signal stNextW    : wstate;
    signal activateW  : std_logic := '0';
    signal writeDone  : std_logic := '0';

    signal rd_key_code: std_logic := '0';
    signal key_read   : std_logic_vector(7 downto 0);
    signal kb_empty   : std_logic;
    
    -- Registradores do jogo da Forca
    signal tentativas : integer range 0 to 5 := 5;
    signal certo_reg  : std_logic_vector(4 downto 0) := "00000"; -- [4]=F, [3]=O, [2]=R, [1]=C, [0]=A
    signal game_over  : std_logic := '0';
    signal game_win   : std_logic := '0';

    type LCD_CMDS_T is array(0 to 24) of std_logic_vector(9 downto 0);
    signal LCD_CMDS : LCD_CMDS_T := (
        0  => "00" & X"38", -- Function Set (8 bits, 2 linhas)
        1  => "00" & X"0C", -- Display ON, Cursor OFF
        2  => "00" & X"01", -- Clear Display
        3  => "00" & X"02", -- Return Home
        4  => "10" & X"4A", -- J
        5  => "10" & X"4F", -- O
        6  => "10" & X"47", -- G
        7  => "10" & X"4F", -- O
        8  => "10" & X"20", -- 
        9  => "10" & X"44", -- D
        10 => "10" & X"41", -- A
        11 => "10" & X"20", -- 
        12 => "10" & X"46", -- F
        13 => "10" & X"4F", -- O
        14 => "10" & X"52", -- R
        15 => "10" & X"43", -- C
        16 => "10" & X"41", -- A
        17 => "00" & X"C0", -- Mudar para Linha 2
        18 => "10" & X"5F", -- _
        19 => "10" & X"5F", -- _
        20 => "10" & X"5F", -- _
        21 => "10" & X"5F", -- _
        22 => "10" & X"5F", -- _
        23 => "00" & X"CE", -- Posição do contador na Linha 2
        24 => "10" & X"35"  -- '5'
    );
    signal lcd_cmd_ptr : integer range 0 to 25 := 0;

begin

    leitura: kb_code PORT MAP (CLK, rst, ps2d, ps2c, rd_key_code, key_read, kb_empty);
    tecla <= key_read;

    -- Divisor síncrono para gerar pulso de 1 us a cada 50 ciclos de 50 MHz
    process(CLK, rst)
    begin
        if rst = '1' then
            clk_cnt <= 0;
            tick_1us <= '0';
        elsif rising_edge(CLK) then
            tick_1us <= '0';
            if clk_cnt = 49 then
                clk_cnt <= 0;
                tick_1us <= '1';
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    -- Lógica de processamento das jogadas do teclado
    process(CLK, rst)
    begin
        if rst = '1' then
            certo_reg   <= "00000";
            tentativas  <= 5;
            rd_key_code <= '0';
        elsif rising_edge(CLK) then
            rd_key_code <= '0';
            if kb_empty = '0' and rd_key_code = '0' and game_over = '0' and game_win = '0' then
                rd_key_code <= '1';
                case key_read is
                    when X"46" => certo_reg(4) <= '1'; -- 'F'
                    when X"4F" => certo_reg(3) <= '1'; -- 'O'
                    when X"52" => certo_reg(2) <= '1'; -- 'R'
                    when X"43" => certo_reg(1) <= '1'; -- 'C'
                    when X"41" => certo_reg(0) <= '1'; -- 'A'
                    when others =>
                        if tentativas > 0 then
                            tentativas <= tentativas - 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Condições de vitória e derrota
    game_win  <= '1' when certo_reg = "11111" else '0';
    game_over <= '1' when tentativas = 0 else '0';

    -- Atualização dinâmica dos caracteres no comando do LCD
    LCD_CMDS(18) <= "10" & X"46" when certo_reg(4) = '1' else "10" & X"5F";
    LCD_CMDS(19) <= "10" & X"4F" when certo_reg(3) = '1' else "10" & X"5F";
    LCD_CMDS(20) <= "10" & X"52" when certo_reg(2) = '1' else "10" & X"5F";
    LCD_CMDS(21) <= "10" & X"43" when certo_reg(1) = '1' else "10" & X"5F";
    LCD_CMDS(22) <= "10" & X"41" when certo_reg(0) = '1' else "10" & X"5F";
    LCD_CMDS(24) <= "10" & std_logic_vector(to_unsigned(48 + tentativas, 8));

    -- Mensagem de término (Linha 1)
    process(game_win, game_over)
    begin
        if game_win = '1' then
            LCD_CMDS(4)  <= "10" & X"47"; -- G
            LCD_CMDS(5)  <= "10" & X"41"; -- A
            LCD_CMDS(6)  <= "10" & X"4E"; -- N
            LCD_CMDS(7)  <= "10" & X"48"; -- H
            LCD_CMDS(8)  <= "10" & X"4F"; -- O
            LCD_CMDS(9)  <= "10" & X"55"; -- U
            LCD_CMDS(10) <= "10" & X"21"; -- !
        elsif game_over = '1' then
            LCD_CMDS(4)  <= "10" & X"50"; -- P
            LCD_CMDS(5)  <= "10" & X"45"; -- E
            LCD_CMDS(6)  <= "10" & X"52"; -- R
            LCD_CMDS(7)  <= "10" & X"44"; -- D
            LCD_CMDS(8)  <= "10" & X"45"; -- E
            LCD_CMDS(9)  <= "10" & X"55"; -- U
            LCD_CMDS(10) <= "10" & X"21"; -- !
        end if;
    end process;

    -- Contador de tempo para os deltas do LCD (incrementado a cada 1 us)
    process(CLK, rst)
    begin
        if rst = '1' then
            count <= (others => '0');
        elsif rising_edge(CLK) then
            if tick_1us = '1' then
                if delayOK = '1' then
                    count <= (others => '0');
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    delayOK <= '1' when (
        (stCur = stPowerOn_Delay and count >= 20000) or
        (stCur = stFunctionSet_Delay and count >= 50) or
        (stCur = stDisplayCtrlSet_Delay and count >= 50) or
        (stCur = stDisplayClear_Delay and count >= 1600) or
        (stCur = stCharDelay and count >= 2000)
    ) else '0';

    -- FSM Principal do LCD
    process(CLK, rst)
    begin
        if rst = '1' then
            stCur <= stPowerOn_Delay;
            lcd_cmd_ptr <= 0;
        elsif rising_edge(CLK) then
            if tick_1us = '1' then
                stCur <= stNext;
                if (stNext = stInitDne or stNext = stDisplayCtrlSet or stNext = stDisplayClear) and writeDone = '0' then
                    lcd_cmd_ptr <= lcd_cmd_ptr + 1;
                elsif writeDone = '1' then
                    lcd_cmd_ptr <= 3;
                end if;
            end if;
        end if;
    end process;

    writeDone <= '1' when (lcd_cmd_ptr = 24) else '0';

    process(stCur, delayOK)
    begin
        stNext <= stCur;
        activateW <= '0';
        RS <= LCD_CMDS(lcd_cmd_ptr)(9);
        RW <= LCD_CMDS(lcd_cmd_ptr)(8);
        LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);

        case stCur is
            when stPowerOn_Delay =>
                if delayOK = '1' then stNext <= stFunctionSet; end if;
            when stFunctionSet =>
                activateW <= '1';
                stNext <= stFunctionSet_Delay;
            when stFunctionSet_Delay =>
                if delayOK = '1' then stNext <= stDisplayCtrlSet; end if;
            when stDisplayCtrlSet =>
                activateW <= '1';
                stNext <= stDisplayCtrlSet_Delay;
            when stDisplayCtrlSet_Delay =>
                if delayOK = '1' then stNext <= stDisplayClear; end if;
            when stDisplayClear =>
                activateW <= '1';
                stNext <= stDisplayClear_Delay;
            when stDisplayClear_Delay =>
                if delayOK = '1' then stNext <= stInitDne; end if;
            when stInitDne =>
                stNext <= stActWr;
            when stActWr =>
                activateW <= '1';
                stNext <= stCharDelay;
            when stCharDelay =>
                if delayOK = '1' then stNext <= stInitDne; end if;
        end case;
    end process;

    -- FSM do pulso Enable (OE) do LCD
    process(CLK, rst)
    begin
        if rst = '1' then
            stCurW <= stIdle;
        elsif rising_edge(CLK) then
            if tick_1us = '1' then
                stCurW <= stNextW;
            end if;
        end if;
    end process;

    process(stCurW, activateW)
    begin
        stNextW <= stCurW;
        OE <= '0';
        case stCurW is
            when stIdle =>
                if activateW = '1' then stNextW <= stRW; end if;
            when stRW =>
                OE <= '1';
                stNextW <= stEnable;
            when stEnable =>
                OE <= '1';
                stNextW <= stIdle;
        end case;
    end process;

end Behavioral;
