LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY alu IS
	PORT (
		-- Entradas
		a_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Operando A
		b_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Operando B
		c_in : IN STD_LOGIC;                       -- Carry-in
		op_sel : IN STD_LOGIC_VECTOR(3 DOWNTO 0);  -- Opera��o Selecionada
		
		-- Sa�das
		r_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Resultado
		c_out : OUT STD_LOGIC;                    -- Carry/Borrow
		z_out : OUT STD_LOGIC;                    -- Indicador de Zero
		v_out : OUT STD_LOGIC                     -- Indicador de Overflow
	);
END ENTITY;

ARCHITECTURE arch OF alu IS
	SIGNAL temp_soma : STD_LOGIC_VECTOR(8 DOWNTO 0); -- Resultado da soma
	SIGNAL temp_sub  : STD_LOGIC_VECTOR(8 DOWNTO 0); -- Resultado da subtra��o
	SIGNAL temp_r    : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Resultado final
	SIGNAL c_ext : unsigned(8 downto 0);
BEGIN
	c_ext <= (8 downto 1 => '0') & c_in;
	
	-- C�lculo da Soma (ADD e ADDC)
	temp_soma <= 
	STD_LOGIC_VECTOR(unsigned('0' & a_in) + unsigned('0' & b_in)) WHEN op_sel = "0000" ELSE
	STD_LOGIC_VECTOR(unsigned('0' & a_in) + unsigned('0' & b_in) + c_ext) WHEN op_sel = "0001" ELSE
	(others => '0');

	-- C�lculo da Subtra��o (SUB e SUBC)
	temp_sub <= 
	STD_LOGIC_VECTOR(unsigned('0' & a_in) - unsigned('0' & b_in)) WHEN op_sel = "0010" ELSE
	STD_LOGIC_VECTOR(unsigned('0' & a_in) - unsigned('0' & b_in) - c_ext) WHEN op_sel = "0011" ELSE
	(others => '0');
    
    WITH op_sel SELECT
		temp_r <= 
			temp_soma(7 DOWNTO 0) WHEN "0000", -- ADD
			temp_soma(7 DOWNTO 0) WHEN "0001", -- ADDC
			temp_sub(7 DOWNTO 0) WHEN "0010",  -- SUB
			temp_sub(7 DOWNTO 0) WHEN "0011",  -- SUBC
			
			a_in AND b_in WHEN "0100", -- AND
			a_in OR  b_in WHEN "0101", -- OR
			a_in XOR b_in WHEN "0110", -- XOR
			NOT a_in WHEN "0111",      -- NOT

			a_in(6 DOWNTO 0) & a_in(7) WHEN "1000", -- RL
			a_in(0) & a_in(7 DOWNTO 1) WHEN "1001", -- RR 
			a_in(6 DOWNTO 0) & c_in    WHEN "1010", -- RLC 
			c_in & a_in(7 DOWNTO 1)    WHEN "1011", -- RRC 
			a_in(6 DOWNTO 0) & '0'     WHEN "1100", -- SLL 
			'0' & a_in(7 DOWNTO 1)     WHEN "1101", -- SRL 
			a_in(7) & a_in(7 DOWNTO 1) WHEN "1110", -- SRA 
			b_in WHEN "1111";                       -- PASS_B
		
	-- Sa�da de Carry/Borrow
	c_out <= 
		temp_soma(8) WHEN (op_sel = "0000" OR op_sel = "0001") ELSE -- Carry da ADD/ADDC
		NOT temp_sub(8) WHEN (op_sel = "0010" OR op_sel = "0011") ELSE -- Borrow da SUB/SUBC
		a_in(7) WHEN (op_sel = "1000" OR op_sel = "1010" OR op_sel = "1100") ELSE -- Rota��o/Deslocamento � esquerda
		a_in(0) WHEN (op_sel = "1001" OR op_sel = "1011" OR op_sel = "1101" OR op_sel = "1110") ELSE -- Rota��o/Deslocamento � direita
		'0';

	-- Sa�da de Zero
	z_out <= '1' WHEN temp_r = "00000000" ELSE '0'; -- Recebe 1 quando o resultado final � zero, caso contr�rio, recebe 0

	-- Sa�da de Overflow
	v_out <= 
		-- Overflow na Soma
		((NOT a_in(7) AND NOT b_in(7) AND temp_r(7)) OR (a_in(7) AND b_in(7) AND NOT temp_r(7)))
		WHEN (op_sel = "0000" OR op_sel = "0001") ELSE
		-- Overflow na Subtra��o
		((a_in(7) AND NOT b_in(7) AND NOT temp_r(7)) OR (NOT a_in(7) AND b_in(7) AND temp_r(7)))
		WHEN (op_sel = "0010" OR op_sel = "0011") ELSE
		'0';

	-- Atribui��o final da sa�da
	r_out <= temp_r;
END arch;