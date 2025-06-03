library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity port_io is
  generic (
    base_addr : std_logic_vector(7 downto 0) := "00000000"
  );
  port (
    clk_in    : in  std_logic;
    nrst      : in  std_logic;
    abus      : in  std_logic_vector(7 downto 0);
    dbus      : inout std_logic_vector(7 downto 0);
    wr_en     : in  std_logic;
    rd_en     : in  std_logic;
    port_io   : inout std_logic_vector(7 downto 0)
  );
end port_io;

architecture Behavioral of port_io is
  signal dir_reg  : std_logic_vector(7 downto 0) := (others => '0');
  signal port_reg : std_logic_vector(7 downto 0) := (others => '0');
  signal latch    : std_logic_vector(7 downto 0) := (others => '0');
begin

  process(clk_in, nrst)
  begin
    if nrst = '0' then
      dir_reg  <= (others => '0');
      port_reg <= (others => '0');
    elsif rising_edge(clk_in) then
      if wr_en = '1' and abus = base_addr then
        port_reg <= dbus;
      elsif wr_en = '1' and abus = std_logic_vector(unsigned(base_addr) + 1) then
        dir_reg <= dbus;
      end if;
    end if;
  end process;

  -- latch
  process(port_io, dir_reg)
  begin
    for i in 0 to 7 loop
      if dir_reg(i) = '0' then
        latch(i) <= port_io(i);
      else
        latch(i) <= 'Z';
      end if;
    end loop;
  end process;

  -- controle da porta
  gen_port : for i in 0 to 7 generate
    port_io(i) <= port_reg(i) when dir_reg(i) = '1' else 'Z';
  end generate;

  -- leitura via dbus
  dbus <= latch when (rd_en = '1' and abus = base_addr) else
          dir_reg when (rd_en = '1' and abus = std_logic_vector(unsigned(base_addr) + 1)) else
          (others => 'Z');

end Behavioral;
