library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pi_control is
  generic (
    use_saturator: boolean;
    n: natural; -- number of bits used
    Kp: real; -- Proportional gain (Kp > 0)
    Ti: real; -- Integral time (Ti > 0)
    Ts: real -- Sampling time (0 < Ts < Ti)
  );
  port (
    clk_in: in std_logic;
    setpoint: in std_logic_vector((n-1) downto 0);
    feedback: in std_logic_vector((n-1) downto 0);
    output: out std_logic_vector((n-1) downto 0)
  );
end entity;

architecture arch of pi_control is
  function only_positive(x: integer) return natural is
  begin
    if x > 0 then
      return natural(x);
    else
      return 0;
    end if;
  end function;
     
  -- Discrete gains in real precision (obtained using Tustin method of discretizaion)
  constant K1: real := Kp * (2.0 + Ts/Ti) / 2.0;
  constant K2: real := Kp * (2.0 - Ts/Ti) / 2.0;
  -- We multiply the gains by the factor because we want to remove the last bits from
  -- the control signal, which is equivalet to a division in the gains of the controller).
  -- This way we have more precision in the gains converted to digital numbers
  constant indice: natural := only_positive(integer(ceil(log2(real(K1)))));
  constant factor: real := (2.0**(n - indice)); 
  constant nK1: natural := natural(factor * K1);
  constant nK2: natural := natural(factor * K2);
  -- The maximum value allowed in control_signal (in case we use saturator)
  constant maximum: natural := 2**(2*n-1-indice)-1;
  -- Since we subtract a positive number from another positive number to compute the error,
  -- the error signal must be the same length as the setpoint plus a sign
  -- error and previous_error range: -(2**n-1) to (2**n-1)
  signal error: signed(n downto 0) := (others => '0');
  signal previous_error: signed(n downto 0) := (others => '0');
  -- Even though uK1 and uK2 are signed, their values are always positive.
  -- This is because we can't multiply signed and unsigned numbers,
  -- only signed with signed and unsigned with unsigned.
  -- Since the error is signed, the constants must be signed too.
  -- uK1 and uK2 range: 0 to (2**n-1)
  constant uK1: signed(n downto 0) := to_signed(nK1, error'length);
  constant uK2: signed(n downto 0) := to_signed(nK2, uK1'length);
  -- op1 is the multiplication of uK1 with error, so it's length must be equal
  -- to the sum of the lengths of uK1 and the error. But, since uK1 only has positive values,
  -- op1 doesn't use all of its bits (there is at least one bit unused). the same is valid for op2.
  -- op1 and op2 range: -(2**n-1)**2 to (2**n-1)**2
  -- where (2**n-1)**2 = 2**(2*n) + 2**(n+1) + 1
  signal op1: signed((2*n+1) downto 0) := (others => '0');
  signal op2: signed((2*n+1) downto 0) := (others => '0');
  -- In op3, all the bits may be used (which didn't happend with op1 and op2).
  -- op3 range: -2*(2**n-1)**2 to 2*(2**n-1)**2
  -- where 2*(2**n-1)**2 = 2**(2*n+1) + 2**(n+2) + 2
  signal op3: signed((2*n+1) downto 0) := (others => '0');
  -- Since the control signal is limited, the op4 cannot overflow as well (op4 has one bit more than op3)
  -- op4 range: -2*(2**n-1)**2 to (2*(2**n-1)**2 + 2**(2*n-1)-1)
  signal op4: signed((2*n+2) downto 0) := (others => '0');
  -- The control signal is limited to the range: 0 to 2**(2*n-1)-1
  signal control_signal: unsigned((2*n-1) downto 0) := (others => '0');
begin
  assert (indice <= n) report "The PI controller gains informed are too large for the required precision." severity failure;
  -- The operation we must perform is given by the following equation:
  -- control_signal <= control_signal + K1 * error - K2 * previous_error;
  op1 <= uK1 * error;
  op2 <= uK2 * previous_error;
  op3 <= op1 - op2;
  op4 <= signed("000" & control_signal) + ('0' & op3);
  -- The output is the higher part of the control_signal.
  -- This is equivalent to a division by the constant factor
  -- (this is why we multiply the gains by factor).
  output <= std_logic_vector(control_signal((2*n-1-indice) downto (n-indice)));
  
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      -- If a "signal" is updated inside the process and then assigned to other signal or ports etc., then "old value"
      -- of the signal will be assigned. The updated value will appear in next clock cycle.
      previous_error <= error;
      -- Sum of a positive with a negative number of the same size can't overflow
      error <= signed('0' & setpoint) - signed('0' & feedback);
      -- Saturator in output signal
      if use_saturator then
        if op4 < 0 then
          control_signal <= (others => '0');
        elsif op4 >= maximum then
          control_signal <= to_unsigned(maximum, control_signal'length);
        else
          control_signal <= unsigned(op4((2*n-1) downto 0));
        end if;
      else
        control_signal <= unsigned(op4((2*n-1) downto 0));
      end if;
    end if;
  end process;
end architecture;