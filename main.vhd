library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
  port (
    clk50MHz: in std_logic;
     
    clk_adc: out std_logic;
    cs_adc: out std_logic;
    di_adc: out std_logic;
    do_adc: in std_logic;
     
    output: out std_logic
  );
end entity;

architecture arch of main is
  signal clk_sampling: std_logic := '0';
  signal pwm_out: std_logic := '0';
  signal setpoint: std_logic_vector(7 downto 0) := (others => '0');
  signal feedback: std_logic_vector(setpoint'range) := (others => '0');
  signal control_out: std_logic_vector(setpoint'range) := (others => '0');
begin
  -- freq = 10 kHz
  adc: entity work.adc0832
    generic map ( clk_div => 125, sampling_div => 40 )
    port map (
      clk_in => clk50MHz,
      clk_adc => clk_adc,
      cs_adc => cs_adc,
      do_adc => do_adc,
      di_adc => di_adc,
      clk_sampling => clk_sampling,
      measured_value_1 => setpoint,
      measured_value_2 => feedback
    );
  
  control: entity work.pi_control
    generic map ( use_saturator => false, n => 8, Kp => 1.0, Ti => 0.01, Ts => 0.0001 )
    port map (
      clk_in => clk_sampling,
      setpoint => setpoint,
      feedback => feedback,
      output => control_out
    );
  
  -- freq = 10.319 kHz
  pwm: entity work.pwm
    generic map ( div => 19, bits => control_out'length )
    port map (
      clk_in => clk50MHz,
      ratio => control_out,
      output => pwm_out
    );

  output <= pwm_out;
end architecture;