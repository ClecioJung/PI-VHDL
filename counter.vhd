library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic ( bits: natural );
  port (
    clk: in std_logic;
    enable: in std_logic;
    reset: in std_logic;
    q: out std_logic_vector((bits-1) downto 0);
    ovf: out std_logic
  );
end entity;

architecture arch of counter is
  constant max: natural := 2**bits - 1;
  signal a: unsigned(q'range) := (others => '0');
begin
  process(clk, enable, reset)
  begin
    if reset = '1' then
      a <= (others => '0');
    elsif rising_edge(clk) and enable = '1' then
      a <= a + 1;
    end if;
  end process;
  
  q <= std_logic_vector(a);
  ovf <= enable when a = max else '0';
end architecture;