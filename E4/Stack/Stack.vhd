library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stack is
  Port (
    clk_in     : in  std_logic;
    nrst       : in  std_logic;
    stack_in   : in  std_logic_vector(10 downto 0);
    stack_push : in  std_logic;
    stack_pop  : in  std_logic;
    stack_out  : out std_logic_vector(10 downto 0)
  );
end stack;

architecture Behavioral of stack is
  type stack_array is array(0 to 7) of std_logic_vector(10 downto 0);
  signal stack_reg : stack_array := (others => (others => '0'));
begin

  process(clk_in, nrst)
  begin
    if nrst = '0' then
      stack_reg <= (others => (others => '0'));
    elsif rising_edge(clk_in) then
      if stack_push = '1' then
        for i in 7 downto 1 loop
          stack_reg(i) <= stack_reg(i - 1);
        end loop;
        stack_reg(0) <= stack_in;
      elsif stack_pop = '1' then
        for i in 0 to 6 loop
          stack_reg(i) <= stack_reg(i + 1);
        end loop;
        stack_reg(7) <= (others => '0');
      end if;
    end if;
  end process;

  stack_out <= stack_reg(0);

end Behavioral;
