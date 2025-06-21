library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity prog_cnt is
  Port (
    clk_in        : in  std_logic;
    nrst          : in  std_logic;
    pc_ctrl       : in  std_logic_vector(1 downto 0);
    new_pc_in     : in  std_logic_vector(10 downto 0);
    from_stack    : in  std_logic_vector(10 downto 0);
    next_pc_out   : out std_logic_vector(10 downto 0);
    pc_out        : out std_logic_vector(10 downto 0)
  );
end prog_cnt;

architecture Behavioral of prog_cnt is
  signal pc_reg      : std_logic_vector(10 downto 0) := (others => '0');
  signal next_pc_sig : std_logic_vector(10 downto 0);
begin

  -- Lógica combinacional para determinar o próximo valor
  process(pc_ctrl, new_pc_in, from_stack, pc_reg)
  begin
    case pc_ctrl is
      when "01" => next_pc_sig <= new_pc_in;
      when "10" => next_pc_sig <= from_stack;
      when "11" => next_pc_sig <= std_logic_vector(unsigned(pc_reg) + 1);
      when others => next_pc_sig <= pc_reg;
    end case;
  end process;

  -- Lógica sequencial para atualizar o registrador
  process(clk_in, nrst)
  begin
    if nrst = '0' then
      pc_reg <= (others => '0');
    elsif rising_edge(clk_in) then
      pc_reg <= next_pc_sig;
    end if;
  end process;

  pc_out      <= pc_reg;
  next_pc_out <= next_pc_sig;

end Behavioral;
