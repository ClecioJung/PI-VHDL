library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_divider is
  generic (
    div: natural;
    ratio_must_be_half: boolean := false
  );
  port (
    clk_in: in std_logic;
    clk_out: out std_logic
  );
end entity;

architecture arch of freq_divider is
  constant max: natural := div-1;
  constant half: natural := max/2;
  constant div_is_even: boolean := ((div mod 2) = 0);
  signal counter: natural range 0 to max := 0;
  signal rise_square_wave: std_logic := '0';
  signal fall_square_wave: std_logic := '0';
begin
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if counter = max then
        counter <= 0;
      else
        counter <= counter + 1;
      end if;
      if counter > half then
        rise_square_wave <= '1';
      else
        rise_square_wave <= '0';
      end if;
    end if;

    if (not div_is_even) and ratio_must_be_half then
      if falling_edge(clk_in) then
        if counter > half then
          fall_square_wave <= '1';
        else
          fall_square_wave <= '0';
        end if;
      end if;
    end if;
  end process;
  
  clk_out <= rise_square_wave when (div_is_even or (not ratio_must_be_half))
    else (rise_square_wave or fall_square_wave);
end architecture;