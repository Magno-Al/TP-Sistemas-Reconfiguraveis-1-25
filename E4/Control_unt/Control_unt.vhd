library ieee;
use ieee.std_logic_1164.all;

entity Control_unt is
    port(
        -- Entradas
        clk_in           : in  std_logic;
        nrst             : in  std_logic;
        rom_q            : in  std_logic_vector(15 downto 8);
        c_flag_reg       : in  std_logic;
        z_flag_reg       : in  std_logic;
        v_flag_reg       : in  std_logic;

        -- Saídas
        wreg_on_dext     : out std_logic;
        reg_di_sel       : out std_logic;
        alu_a_in_sel     : out std_logic;
        alu_to_gpio_sel  : out std_logic;
        reg_wr_ena       : out std_logic;
        wreg_wr_ena      : out std_logic;
        sel_ra_ou_wreg   : out std_logic;
        men_to_wreg_sel  : out std_logic;
        c_flag_wr_ena    : out std_logic;
        z_flag_wr_ena    : out std_logic;
        v_flag_wr_ena    : out std_logic;
        alu_op           : out std_logic_vector(3 downto 0);
        stack_push       : out std_logic;
        stack_pop        : out std_logic;
        pc_ctrl          : out std_logic_vector(1 downto 0);
        mem_wr_ena       : out std_logic;
        mem_rd_ena       : out std_logic;
        inp              : out std_logic;
        outp             : out std_logic
    );
end Control_unt;

architecture behavior of Control_unt is
    type t_state is (s_fetch, s_decode, s_execute, s_execute_branch);
    signal current_state, next_state : t_state;

    -- Sinais internos para todas as portas de saída
    signal s_wreg_on_dext     : std_logic;
    signal s_reg_di_sel       : std_logic;
    signal s_alu_a_in_sel     : std_logic;
    signal s_alu_to_gpio_sel  : std_logic;
    signal s_reg_wr_ena       : std_logic;
    signal s_wreg_wr_ena      : std_logic;
    signal s_sel_ra_ou_wreg   : std_logic;
    signal s_men_to_wreg_sel  : std_logic;
    signal s_c_flag_wr_ena    : std_logic;
    signal s_z_flag_wr_ena    : std_logic;
    signal s_v_flag_wr_ena    : std_logic;
    signal s_alu_op           : std_logic_vector(3 downto 0);
    signal s_stack_push       : std_logic;
    signal s_stack_pop        : std_logic;
    signal s_pc_ctrl          : std_logic_vector(1 downto 0);
    signal s_mem_wr_ena       : std_logic;
    signal s_mem_rd_ena       : std_logic;
    signal s_inp              : std_logic;
    signal s_outp             : std_logic;

begin

    -- Lógica sequencial para atualização de estado
    process(clk_in, nrst)
    begin
        if (nrst = '0') then -- Lógica de reset alterada para ativo em baixo
            current_state <= s_fetch;
        elsif (rising_edge(clk_in)) then
            current_state <= next_state;
        end if;
    end process;
    
    -- Atribuições concorrentes dos sinais internos para as portas de saída
    wreg_on_dext    <= s_wreg_on_dext;
    reg_di_sel      <= s_reg_di_sel;
    alu_a_in_sel    <= s_alu_a_in_sel;
    alu_to_gpio_sel <= s_alu_to_gpio_sel;
    reg_wr_ena      <= s_reg_wr_ena;
    wreg_wr_ena     <= s_wreg_wr_ena;
    sel_ra_ou_wreg  <= s_sel_ra_ou_wreg;
    men_to_wreg_sel <= s_men_to_wreg_sel;
    c_flag_wr_ena   <= s_c_flag_wr_ena;
    z_flag_wr_ena   <= s_z_flag_wr_ena;
    v_flag_wr_ena   <= s_v_flag_wr_ena;
    alu_op          <= s_alu_op;
    stack_push      <= s_stack_push;
    stack_pop       <= s_stack_pop;
    pc_ctrl         <= s_pc_ctrl;
    mem_wr_ena      <= s_mem_wr_ena;
    mem_rd_ena      <= s_mem_rd_ena;
    inp             <= s_inp;
    outp            <= s_outp;

    -- Lógica combinacional para controle
    process(current_state, rom_q, c_flag_reg, z_flag_reg, v_flag_reg)
    begin
        -- Inicializa todos os sinais com valores padrão (inativos)
        s_wreg_on_dext    <= '0'; 
        s_reg_di_sel      <= '0'; 
        s_alu_a_in_sel    <= '0';
        s_alu_to_gpio_sel <= '0'; 
        s_reg_wr_ena      <= '0'; 
        s_wreg_wr_ena     <= '0';
        s_sel_ra_ou_wreg  <= '0'; 
        s_men_to_wreg_sel <= '0'; 
        s_c_flag_wr_ena   <= '0';
        s_z_flag_wr_ena   <= '0'; 
        s_v_flag_wr_ena   <= '0'; 
        s_alu_op          <= "0000";
        s_stack_push      <= '0'; 
        s_stack_pop       <= '0'; 
        s_pc_ctrl         <= "00";
        s_mem_wr_ena      <= '0'; 
        s_mem_rd_ena      <= '0'; 
        s_inp             <= '0';
        s_outp            <= '0';
        
        -- Lógica da Máquina de Estados
        case current_state is
            when s_fetch =>
                s_pc_ctrl <= "01";
                next_state <= s_decode;

            when s_decode =>
                if (rom_q(15 downto 12) = "1110") or (rom_q(15 downto 11) = "11110") then
                    next_state <= s_execute_branch;
                else
                    next_state <= s_execute;
                end if;

            when s_execute =>
                -- Habilita escrita nos flags para todas as operações da ULA
                if (rom_q(15 downto 14) = "00" or rom_q(15 downto 14) = "01" or rom_q(15 downto 14) = "10") then
                    s_c_flag_wr_ena <= '1'; 
                    s_z_flag_wr_ena <= '1'; 
                    s_v_flag_wr_ena <= '1';
                end if;

                case rom_q(15 downto 14) is
                    when "00" | "01" | "10" => -- Formatos de ULA
                        s_alu_op(3) <= '0';
                        s_alu_op(2 downto 0) <= rom_q(13 downto 11);
                        if (rom_q(8) = '0') then 
							s_wreg_wr_ena <= '1'; 
						else 
							s_reg_wr_ena <= '1'; 
						end if;
                    
                    when "11" => -- Formato Memória e E/S
                        if (rom_q(15 downto 13) = "110") then
                            case rom_q(12 downto 11) is
                                when "00" => -- LDM
                                    s_mem_rd_ena <= '1'; 
                                    s_wreg_wr_ena <= '1'; 
                                    s_men_to_wreg_sel <= '1';
                                when "01" => -- STM
                                    s_mem_wr_ena <= '1';
                                when "10" => -- INP
                                    s_inp <= '1';
                                    if (rom_q(8) = '0') then 
										s_wreg_wr_ena <= '1'; 
									else 
										s_reg_wr_ena <= '1'; 
									end if;
                                when "11" => -- OUT
                                    s_outp <= '1';
                                when others => null;
                            end case;
                        end if;
                    when others => null;
                end case;
                next_state <= s_fetch;

            when s_execute_branch =>
                if (rom_q(15 downto 12) = "1110") then -- JMP, CALL
                    case rom_q(11) is
                        when '0' => -- JMP
                            s_pc_ctrl <= "10";
                        when '1' => -- CALL
                            s_stack_push <= '1'; 
                            s_pc_ctrl <= "10";
                        when others => null;
                    end case;
                elsif (rom_q(15 downto 11) = "11110") then -- SKIPS, RET
                    case rom_q(10 downto 9) is
                        when "00" => -- SKIPC
                            if (c_flag_reg = '1') then 
								s_pc_ctrl <= "01"; 
							end if;
                        when "01" => -- SKIPZ
                            if (z_flag_reg = '1') then 
								s_pc_ctrl <= "01"; 
							end if;
                        when "10" => -- SKIPV
                            if (v_flag_reg = '1') then 
								s_pc_ctrl <= "01"; 
							end if;
                        when "11" => -- RET
                            s_stack_pop <= '1'; 
                            s_pc_ctrl <= "10";
                        when others => null;
                    end case;
                end if;
                next_state <= s_fetch;
        end case;
    end process;

end behavior;