library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- output frequency = clk_in frequency / ((2 ^ bits) * div)
entity pwm is
  generic ( div: natural; bits: natural );
  port (
    clk_in: in std_logic;
    ratio: in std_logic_vector((bits-1) downto 0);
    output: out std_logic
  );
end entity;

architecture arch of pwm is
  signal clk: std_logic := '0';
  signal counter : unsigned(ratio'range) := (others => '0');
begin
  clock_divider: entity work.freq_divider
    generic map ( div => div )
    port map (
      clk_in => clk_in,
      clk_out => clk
    );

  process(clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
    end if;
  end process;
  
  output <= '1' when (counter < unsigned(ratio)) else '0';
end architecture;