library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_register is
  generic ( bits: natural );
  port (
    clk: in std_logic;
    input: in std_logic;
    output: out std_logic_vector((bits-1) downto 0)
  );
end entity;

architecture arch of shift_register is
  signal o: std_logic_vector(output'range) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
       -- o <= o((bits-2) downto 0) & input;
      for i in 1 to o'high loop
        o(i) <= o(i-1);
      end loop;
      o(0) <= input;
    end if;
  end process;
  output <= o;
end architecture;