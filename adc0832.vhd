library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc0832 is
  generic (
    clk_div: natural;     -- first clock divider
    sampling_div: natural -- second clock divider (must be greater than 26)
  );
  port (
    do_adc: in std_logic;
    clk_in: in std_logic;
    clk_adc: out std_logic;
    cs_adc: out std_logic;
    di_adc: out std_logic;
    -- Sampling clock (not used by the chip, but may be used to synchronize 
    -- to other hardware blocks, such as controllers)
    -- When this signal transitions to zero, the chip is sampling
    clk_sampling: out std_logic;
    measured_value_1: out std_logic_vector(7 downto 0);
    measured_value_2: out std_logic_vector(measured_value_1'range)
  );
end entity;

architecture arch of adc0832 is
  constant end_rec_state: natural := 12;
  signal clk: std_logic := '0';
  signal sampling: std_logic := '0';
  signal state: std_logic_vector(3 downto 0) := (others => '0');
  signal reset_counter: std_logic := '0';
  signal end_reception: std_logic := '0';
  signal shifting_byte: std_logic_vector(measured_value_1'range) := (others => '0');
  signal channel: std_logic := '0';
  signal di: std_logic := '0';
begin
  clock_divider: entity work.freq_divider
    generic map ( div => clk_div )
    port map (
      clk_in => clk_in,
      clk_out => clk
    );
  sampling_divider: entity work.freq_divider_low
    generic map ( div => sampling_div )
    port map (
      clk_in => clk,
      clk_out => sampling
    );

  process(clk)
  begin
    if rising_edge(clk) then
      reset_counter <= sampling or (end_reception and (not channel));
    end if;
  end process;
  
  counter: entity work.counter
    generic map ( bits => state'length )
    port map (
      clk => clk,
      enable => not end_reception,
      reset => reset_counter,
      q => state
    );
  
  shift_register: entity work.shift_register
    generic map ( bits => shifting_byte'length )
    port map (
      clk => clk,
      input => do_adc,
      output => shifting_byte
    );
  
  end_reception <= '1' when (unsigned(state) = to_unsigned(end_rec_state, state'length)) else '0';
  process(end_reception)
  begin
    if rising_edge(end_reception) then
      if channel = '0' then
        measured_value_1 <= shifting_byte;
      else
        measured_value_2 <= shifting_byte;
      end if;
        channel <= not channel;
    end if;
  end process;
  
  process(clk)
  begin
    if falling_edge(clk) then
       if unsigned(state) = to_unsigned(0, state'length) then
          di <= '1'; -- start bit
        elsif unsigned(state) = to_unsigned(1, state'length) then
          di <= '1'; -- SGL/DIF
        elsif unsigned(state) = to_unsigned(2, state'length) then
          di <= channel; -- ODD/SIGN
        else
          di <= 'X';
        end if;
     end if;
  end process;
  
  clk_adc <= clk;
  cs_adc <= reset_counter;
  di_adc <= di;
  clk_sampling <= sampling;
end architecture;