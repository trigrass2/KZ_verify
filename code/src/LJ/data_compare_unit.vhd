----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:15:27 02/27/2015 
-- Design Name: 
-- Module Name:    data_compare_unit - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_compare_unit is
port(
	-- fix by herry make sys_clk_80M to sys_clk_160M
	   sys_clk_80M		:	in	std_logic;--system clock,80MHz
		sys_rst_n		:	in	std_logic;--system reset,low active
		
		sys_clk_320M		:	in	std_logic;--system clock,320MHz
		---
	   flag_bit			:	in		std_logic;--system clock,200MHz
	   verify_active	:	in		std_logic;--system clock,200MHz
	   ram_wr_en		:	in		std_logic;--system clock,200MHz
		ram_wr_data		:	in		std_logic_vector(7 downto 0);
		ram_wr_addr		:	in		std_logic_vector(19 downto 0);
		fifo_prog_empty:	in		std_logic;
		fifo_rd_vld		:	in		std_logic;
		fifo_rd_data	:	in		std_logic_vector(31 downto 0);
		fifo_rd_en		:	out	std_logic;
		
		compare_total_cnt : OUT std_logic_vector(31 downto 0);          
		compare_error_cnt : OUT std_logic_vector(31 downto 0);      
		
		compare_result_wr  : out 	std_logic;
		compare_result		 : out 	std_logic_vector(63 downto 0)
	);
end data_compare_unit;

architecture Behavioral of data_compare_unit is
------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT kz_ram
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------
signal compare_cnt_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal compare_err_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);

signal ram_rd_addr : STD_LOGIC_VECTOR(16 DOWNTO 0);
signal ram_rd_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal ram_rd_data_fix : STD_LOGIC_VECTOR(31 DOWNTO 0);

signal verify_active_d1 : STD_LOGIC;

begin
	--�����ȽϿ�ʼ�ź�
	process (sys_clk_80M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			fifo_rd_en	<= '0';
		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
			fifo_rd_en	<= fifo_prog_empty;
		end if;
	end process;
	
	compare_total_cnt	<= compare_cnt_reg;
	process (sys_clk_80M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			ram_rd_addr			<= (others => '0');
			compare_cnt_reg	<= (others => '0');
		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
			if(verify_active = '0') then
				ram_rd_addr			<= (others => '0');
				compare_cnt_reg	<= (others => '0');
			elsif(fifo_rd_vld = '1') then
				if(fifo_rd_data = ram_rd_data_fix) then
					ram_rd_addr			<= ram_rd_addr + '1';
				end if;
				compare_cnt_reg	<= compare_cnt_reg + '1';
			end if;
		end if;
	end process;
	
	compare_error_cnt	<= compare_err_reg;
--	process (sys_clk_80M, sys_rst_n) begin
--		if(sys_rst_n = '0') then
--			compare_err_reg	<= (others => '0');
--			compare_result		<= (others => '0');
--			compare_result_wr <= '0';
--		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
--			verify_active_d1	<= verify_active;
--			if(fifo_rd_vld = '1' and verify_active = '1') then
--				if(fifo_rd_data /= ram_rd_data_fix) then
--					compare_result_wr <= '1';
--					compare_result		<= flag_bit & compare_cnt_reg(30 downto 0) & fifo_rd_data;
--					compare_err_reg	<= compare_err_reg + '1';
--				else
--					compare_result_wr <= '0';
--				end if;
--			else
--				compare_result_wr <= '0';
--				if(verify_active_d1 = '0' and verify_active = '1') then
--					compare_err_reg	<= (others => '0');
--				end if;
--			end if;
--		end if;
--	end process;
	process (sys_clk_80M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			compare_err_reg	<= (others => '0');
			compare_result		<= (others => '0');
			compare_result_wr <= '0';
		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
			verify_active_d1	<= verify_active;
			if(verify_active = '1') then
				if(fifo_rd_vld = '1') then
					if(fifo_rd_data /= ram_rd_data_fix) then
						if() then
						
						else
						
						end if;
						compare_result_wr <= '1';
						compare_result		<= flag_bit & compare_cnt_reg(30 downto 0) & fifo_rd_data;
						compare_err_reg	<= compare_err_reg + '1';
					else
						compare_result_wr <= '0';
					end if;
				else
					compare_result_wr <= '0';
					
				end if;
			else
				if(verify_active_d1 = '0' and verify_active = '1') then
					compare_err_reg	<= (others => '0');
				end if;
			end if;
		end if;
	end process;
-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
kz_ram_inst : kz_ram
  PORT MAP (
    clka => sys_clk_80M,
    wea(0) => ram_wr_en,
    addra => ram_wr_addr(18 downto 0),
    dina => ram_wr_data,
    clkb => sys_clk_80M,
    addrb => ram_rd_addr,
    doutb => ram_rd_data
  );
  
	process (sys_clk_80M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			ram_rd_data_pre	<= (others => '0');
		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
			if(fifo_rd_vld = '1') then
				ram_rd_data_pre	<= ram_rd_data;
			end if;
		end if;
	end process;
	
	process (sys_clk_80M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			equal_all <= '0';
			equal_1 <= x"0";
			equal_2 <= x"0";
			equal_3 <= x"0";
			equal_4 <= x"0";
		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
			if(fifo_rd_vld = '1' and verify_active = '1') then
				if(fifo_rd_data = ram_rd_data_fix) then
					equal_all <= '1';
				else
					equal_all <= '0';
				end if;
				--��һ���ֽ���RAM��һ���ֽ���ͬ
				if(fifo_rd_data(31 downto 24) = ram_rd_data_fix(31 downto 24)) then
					equal_0(0) <= '1';
				else
					equal_0(0) <= '1';
				end if;
				--��һ���ֽ���RAM�ڶ����ֽ���ͬ
				if(fifo_rd_data(31 downto 24) = ram_rd_data_fix(23 downto 16)) then
					equal_0(1) <= '1';
				else
					equal_0(1) <= '1';
				end if;
				--��һ���ֽ���RAM�������ֽ���ͬ
				if(fifo_rd_data(31 downto 24) = ram_rd_data_fix(15 downto 8)) then
					equal_0(2) <= '1';
				else
					equal_0(2) <= '1';
				end if;
				--��һ���ֽ���RAM���ĸ��ֽ���ͬ
				if(fifo_rd_data(31 downto 24) = ram_rd_data_fix(7 downto 0)) then
					equal_0(3) <= '1';
				else
					equal_0(3) <= '1';
				end if;
				
				--�ڶ����ֽ���RAM��һ���ֽ���ͬ
				if(fifo_rd_data(23 downto 16) = ram_rd_data_fix(31 downto 24)) then
					equal_1(0) <= '1';
				else
					equal_1(0) <= '1';
				end if;
				--�ڶ����ֽ���RAM�ڶ����ֽ���ͬ
				if(fifo_rd_data(23 downto 16) = ram_rd_data_fix(23 downto 16)) then
					equal_1(1) <= '1';
				else
					equal_1(1) <= '1';
				end if;
				--�ڶ����ֽ���RAM�������ֽ���ͬ
				if(fifo_rd_data(23 downto 16) = ram_rd_data_fix(15 downto 8)) then
					equal_1(2) <= '1';
				else
					equal_1(2) <= '1';
				end if;
				--�ڶ����ֽ���RAM���ĸ��ֽ���ͬ
				if(fifo_rd_data(23 downto 16) = ram_rd_data_fix(7 downto 0)) then
					equal_1(3) <= '1';
				else
					equal_1(3) <= '1';
				end if;
				
				--�������ֽ���RAM��һ���ֽ���ͬ
				if(fifo_rd_data(15 downto 8) = ram_rd_data_fix(31 downto 24)) then
					equal_2(0) <= '1';
				else
					equal_2(0) <= '1';
				end if;
				--�������ֽ���RAM�ڶ����ֽ���ͬ
				if(fifo_rd_data(15 downto 8) = ram_rd_data_fix(23 downto 16)) then
					equal_2(1) <= '1';
				else
					equal_2(1) <= '1';
				end if;
				--�������ֽ���RAM�������ֽ���ͬ
				if(fifo_rd_data(15 downto 8) = ram_rd_data_fix(15 downto 8)) then
					equal_2(2) <= '1';
				else
					equal_2(2) <= '1';
				end if;
				--�������ֽ���RAM���ĸ��ֽ���ͬ
				if(fifo_rd_data(15 downto 8) = ram_rd_data_fix(7 downto 0)) then
					equal_2(3) <= '1';
				else
					equal_2(3) <= '1';
				end if;
				
				--���ĸ��ֽ���RAM��һ���ֽ���ͬ
				if(fifo_rd_data(7 downto 0) = ram_rd_data_fix(31 downto 24)) then
					equal_3(0) <= '1';
				else
					equal_3(0) <= '1';
				end if;
				--���ĸ��ֽ���RAM�ڶ����ֽ���ͬ
				if(fifo_rd_data(7 downto 0) = ram_rd_data_fix(23 downto 16)) then
					equal_3(1) <= '1';
				else
					equal_3(1) <= '1';
				end if;
				--���ĸ��ֽ���RAM�������ֽ���ͬ
				if(fifo_rd_data(7 downto 0) = ram_rd_data_fix(15 downto 8)) then
					equal_3(2) <= '1';
				else
					equal_3(2) <= '1';
				end if;
				--���ĸ��ֽ���RAM���ĸ��ֽ���ͬ
				if(fifo_rd_data(7 downto 0) = ram_rd_data_fix(7 downto 0)) then
					equal_3(3) <= '1';
				else
					equal_3(3) <= '1';
				end if;
			else
				null;
			end if;
		end if;
	end process;
	--RAM��2��3��4�ֽ���FIFO��1��2��3��ͬ�� 1-1�ֽڲ�ͬ
	drop_1 <= equal_0(0) & equal_1(0) & equal_2(1) & equal_3(2);
	--RAM��3��4�ֽ���FIFO��2��3��ͬ�� 1-1�ֽ���ͬ 2-2�ֽڲ�ͬ
	drop_2 <= equal_0(0) & equal_1(1) & equal_2(1) & equal_3(2);
	--RAM��4�ֽ���FIFO��3��ͬ�� 1-1�ֽ���ͬ 2-2�ֽ���ͬ 3-3�ֽڲ�ͬ 
	drop_3 <= equal_0(0) & equal_1(1) & equal_2(2) & equal_4(2);
	
	--RAM��1��2��3�ֽ���FIFO��2��3��4��ͬ�� 1-1�ֽڲ�ͬ
	add_1 <= equal_0(0) & equal_0(1) & equal_1(2) & equal_2(3);
	--RAM��2��3�ֽ���FIFO��3��4��ͬ�� 1-1�ֽ���ͬ��2-2�ֽڲ�ͬ
	add_2 <= equal_0(0) & equal_1(1) & equal_1(2) & equal_2(3);
	--RAM��3�ֽ���FIFO��4��ͬ�� 1-1�ֽ���ͬ��2-2�ֽ���ͬ��3-3�ֽڲ�ͬ
	add_3 <= equal_0(0) & equal_1(1) & equal_2(2) & equal_2(3);
	
--	--RAM��1��2��3��4�ֽ���FIFO��1��2��3��4�ֽڶ�Ӧ�ֽڴ���
--	err_1 <= equal_0(0) & equal_1(1) & equal_2(2) & equal_3(3);
	
	process (drop_1, drop_2, drop_3) begin
		if(drop_1 = "0111" or drop_2 = "1011" or  drop_3 = "1101") then
			drop_byte <= '1';
		else
			drop_byte <= '0';
		end if;
	end process;
	
	process (add_1, add_2, add_3) begin
		if(add_1 = "0111" or add_2 = "1011" or  add_3 = "1101") then
			add_byte <= '1';
		else
			add_byte <= '0';
		end if;
	end process;
	
	process (err_1) begin
		if(equal_all = '0' and add_byte = '0' and  drop_byte = '0') then
			err_byte <= '1';
		else
			err_byte <= '0';
		end if;
	end process;
	
	process (drop_byte) begin
		if(drop_byte = '1') then
			ram_rd_data_fix <= ram_rd_data_pre(31 downto 24) & ram_rd_data(7 downto 0) & ram_rd_data(15 downto 8) & ram_rd_data(23 downto 16);
		else
			ram_rd_data_fix <= ram_rd_data(7 downto 0) & ram_rd_data(15 downto 8) & ram_rd_data(23 downto 16) & ram_rd_data(31 downto 24);
		end if;
	end process;
	
	--���������1���ֽڣ���Ƚϵ�FIFO����Ϊ��һ������
	process (add_byte) begin
		if(add_byte = '1') then
			fifo_rd_data_fix <= fifo_rd_data_pre(7 downto 0) & fifo_rd_data(31 downto 24) & fifo_rd_data(23 downto 16) & fifo_rd_data(15 downto 8);
		else
			fifo_rd_data_fix <= fifo_rd_data;
		end if;
	end process;
end Behavioral;
