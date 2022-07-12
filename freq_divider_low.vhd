library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This frequency divider keeps the output signal in low state most of the time
-- For only one cycle of the input clock the output clock is in high state
entity freq_divider_low is
  generic (
    div: natural
  );
  port (
    clk_in: in std_logic;
    clk_out: out std_logic
  );
end entity;

architecture arch of freq_divider_low is
  constant max: natural := div-1;
  signal counter: natural range 0 to max := 0;
  signal o: std_logic := '0';
begin
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if counter = max then
        counter <= 0;
        o <= '1';
      else
        counter <= counter + 1;
        o <= '0';
      end if;
    end if;
  end process;
  
  clk_out <= o;
end architecture;