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
		
		sys_clk_200M		:	in	std_logic;--system clock,320MHz
		---
	   store_en			:	in		std_logic;--system clock,200MHz
	   flag_bit			:	in		std_logic;--system clock,200MHz
	   verify_active	:	in		std_logic;--system clock,200MHz
	   ram_wr_en		:	in		std_logic;--system clock,200MHz
		ram_wr_data		:	in		std_logic_vector(15 downto 0);
		ram_wr_addr		:	in		std_logic_vector(15 downto 0);
		fifo_prog_empty:	in		std_logic;
		fifo_rd_vld		:	in		std_logic;
		fifo_rd_data	:	in		std_logic_vector(7 downto 0);
		fifo_rd_en		:	out	std_logic;
		
		compare_total_over: OUT std_logic_vector(31 downto 0);          
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
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------
signal compare_over_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal compare_cnt_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal compare_cnt_reg1: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal compare_cnt_reg2: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal compare_err_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);

signal data_num : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal ram_rd_addr : STD_LOGIC_VECTOR(14 DOWNTO 0);
signal ram_rd_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal ram_rd_data_fix : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal ram_rd_data_d1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal ram_rd_data_d2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal ram_rd_data_d3 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal fifo_rd_data_d1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal fifo_rd_data_d2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal fifo_rd_data_d3 : STD_LOGIC_VECTOR(31 DOWNTO 0);
--signal fifo_rd_data_d  : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal rd_cnt : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal rd_cnt_d2 : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal rd_cnt_d3 : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal rd_cnt_com : STD_LOGIC_VECTOR(1 DOWNTO 0);
--signal rd_cnt_com_d2 : STD_LOGIC_VECTOR(1 DOWNTO 0);
--signal rd_cnt_com_d3 : STD_LOGIC_VECTOR(1 DOWNTO 0);

signal data_equal_pre : STD_LOGIC;
signal data_equal		 : STD_LOGIC;
signal data_equal_d1	 : STD_LOGIC;
signal data_equal_d2	 : STD_LOGIC;
signal data_compare_en: STD_LOGIC;
--signal fifo_rd_vld_d  : STD_LOGIC;
signal fifo_rd_vld_d1 : STD_LOGIC;
signal fifo_rd_vld_d2 : STD_LOGIC;
signal fifo_rd_vld_d3 : STD_LOGIC;
signal verify_active_d1 : STD_LOGIC;
signal verify_active_d2 : STD_LOGIC;
signal fifo_rd_en_reg	: STD_LOGIC;

begin
	
	--1.fifo的读出方式为，FIFO非空，因此在没有比较时，外部数据是什么不影响比较结果
	--2.比较开始前，RAM中的比较数据已经先写入，RAM容量为64KB，即数据的最大重复长度为64KB
	--  建议重复长度为2 K，
	--3.比较过程如下：初始时，比较使能计数rd_com_cnt为3，rd_cnt为0，RAM地址为0
	--  a.fifo读出1字节rd_cnt + 1 如果rd_com_cnt与rd_cnt相等，产生比较使能信号1个时钟周期
	--  b.如果比较结果相等：更新rd_com_cnt（值为rd_cnt），RAM地址+1
	--              否则：rd_com_cnt不变，RAM地址不变
	--  c.
	--  由以上两步可以看出，当数据流有错误出现时，当前比较值不变，数据流保持流动，数据可以在下一次重复到达时重新同步上，
	--  当然数据可能在下一次重复到达前相等，此时会更新比较值，继续等待下一次重复到达，所以比较数据在单次重复过程中最好不要有重复的
	--  4字节数据，这应该很容易实现
	--步骤3的实现按流水线设计，1.数据到达；2.rd_cnt计数,比较数据;3.更新rd_com_cnt，更新比较RAM；4.地址更新比较结果
	fifo_rd_en	<= fifo_rd_en_reg;
	process (sys_clk_200M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			fifo_rd_en_reg		<= '0';
			verify_active_d1	<= '0';
			verify_active_d2	<= '0';
		elsif (sys_clk_200M'event and sys_clk_200M = '1') then
			fifo_rd_en_reg		<= (not fifo_prog_empty) and (not fifo_rd_en_reg);
			verify_active_d1	<= verify_active;
			verify_active_d2	<= verify_active_d1;
		end if;
	end process;
	--RAM 的数据输出有2个延时
--	process (sys_clk_200M, sys_rst_n) begin
--		if(sys_rst_n = '0') then
--			fifo_rd_data_d	<= (others => '0');
--			fifo_rd_vld_d		<= '0';
--		elsif (sys_clk_200M'event and sys_clk_200M = '1') then
--			fifo_rd_vld_d	<= fifo_rd_vld;
--			fifo_rd_data_d	<= fifo_rd_data;
--		end if;
--	end process;
	---对读出的fifo数据进行拼装，输入的8bit数据按字节移位组成4字节数据
	---每读出1字节数据，2bit的rd_cnt + 1
	---ram_rd_data_d1 由读出的ram_rd_data_fix数据得到
	---RAM写入时按字节写入，读出时按4字节读出，先写入的数据会在读出4字节的高字节，所以需要调整
	ram_rd_data_fix <= ram_rd_data(15 downto 0) & ram_rd_data(31 downto 16);
	process (sys_clk_200M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			rd_cnt				<= (others => '0');
			fifo_rd_data_d1	<= (others => '0');
--			ram_rd_addr_d1		<= (others => '0');
			ram_rd_data_d1		<= (others => '0');
			fifo_rd_vld_d1		<= '0';
		elsif (sys_clk_200M'event and sys_clk_200M = '1') then
			fifo_rd_vld_d1	<= fifo_rd_vld;
			if(verify_active = '0') then
				rd_cnt				<= (others => '0');
				fifo_rd_data_d1	<= (others => '0');
--				ram_rd_addr_d1		<= (others => '0');
				ram_rd_data_d1		<= (others => '0');
			elsif(fifo_rd_vld = '1') then
				fifo_rd_data_d1 	<= fifo_rd_data_d1(23 downto 0) & fifo_rd_data;
				rd_cnt				<= rd_cnt + '1';
--				ram_rd_addr_d1		<= ram_rd_addr;
				ram_rd_data_d1		<= ram_rd_data_fix;
			end if;
		end if;
	end process;
	
	---数据比较
	process (fifo_rd_data_d1, ram_rd_data_d1) begin
		if(fifo_rd_data_d1 = ram_rd_data_d1) then
			data_equal			<= '1';
		else
			data_equal			<= '0';
		end if;
	end process;
	
	---1.FIFO valid
	---compare_cnt_reg记录的是当前比较数据在RAM中的位置
	---当数据比较相等时，更新rd_cnt_com的值为当前fifo读出计数%2
	---
	ram_rd_addr	<= compare_cnt_reg(14 downto 0);
	process (sys_clk_200M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			rd_cnt_com			<= (others => '0');
			rd_cnt_d2			<= (others => '0');
			fifo_rd_data_d2	<= (others => '0');
			compare_cnt_reg	<= (others => '0');
			compare_over_reg	<= (others => '0');
			ram_rd_data_d2		<= (others => '0');
			data_equal_d1		<= '0';
			fifo_rd_vld_d2		<= '0';
		elsif (sys_clk_200M'event and sys_clk_200M = '1') then
			rd_cnt_d2			<= rd_cnt;
			fifo_rd_vld_d2		<= fifo_rd_vld_d1;
			data_equal_d1		<= data_equal;
			fifo_rd_data_d2	<= fifo_rd_data_d1;
			ram_rd_data_d2		<= ram_rd_data_d1;
			if(data_equal = '1' and fifo_rd_vld_d1 = '1') then
				rd_cnt_com			<= rd_cnt;
				compare_cnt_reg	<= compare_cnt_reg + '1';
			elsif(verify_active_d1 = '1' and verify_active_d2 = '0') then
				rd_cnt_com			<= "11";
				compare_cnt_reg	<= (others => '0');
			end if;
			
			if(verify_active_d1 = '1' and verify_active_d2 = '0') then
					compare_over_reg	<= (others => '0');
				else
					if(compare_cnt_reg(30) = '1' and compare_cnt_reg(30) = '0') then
						compare_over_reg	<= compare_over_reg + 1;
					end if;
				end if;
		end if;
	end process;
	--产生比较使能信号，当数据使能，且rd_cnt_d2的值与rd_cnt_com值相同
	process (sys_clk_200M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			fifo_rd_vld_d3		<= '0';
			rd_cnt_d3			<= "00";
			data_equal_d2		<= '0';
			data_compare_en	<= '0';
			fifo_rd_data_d3	<= (others => '0');
			ram_rd_data_d3		<= (others => '0');
		elsif (sys_clk_200M'event and sys_clk_200M = '1') then
			rd_cnt_d3			<= rd_cnt_d2;
			fifo_rd_vld_d3		<= fifo_rd_vld_d2;
			fifo_rd_data_d3	<= fifo_rd_data_d2;
			ram_rd_data_d3		<= ram_rd_data_d2;
			data_equal_d2		<= data_equal_d1;
			if(fifo_rd_vld_d2 = '1' and rd_cnt_d2 = rd_cnt_com) then
				data_compare_en	<= '1';
			else
				data_compare_en	<= '0';
			end if;
		end if;
	end process;
	
	--当比较使能时，如果比较结果不一致，则将错误结果写入FIFO
	--写入的结果为flag_bit & compare_cnt_reg(30 downto 0) & fifo_rd_data_d3;
	--64位宽，
	process (sys_clk_200M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			data_equal_pre <= '0';
			compare_result_wr <= '0';
			data_num					<= (others => '0');
			compare_result			<= (others => '0');
			compare_err_reg		<= (others => '0');
		elsif (sys_clk_200M'event and sys_clk_200M = '1') then
			if(data_compare_en = '1') then
				if(data_equal_d2 = '0' ) then
					compare_err_reg	<= compare_err_reg + '1';
					compare_result_wr <= (data_equal_pre or flag_bit) and store_en;
					if(data_equal_pre = '1' or flag_bit = '1') then
						data_num	<= data_num + '1';
					end if;
					data_equal_pre 	<= '0';
					compare_result		<= data_num & compare_cnt_reg(23 downto 0) & fifo_rd_data_d3;
				else
					compare_result_wr <= '0';
					data_equal_pre <= '1';
				end if;
			else
				compare_result_wr	<= '0';
				if(verify_active_d1 = '1' and verify_active_d2 = '0') then
					compare_result			<= (others => '0');
					compare_err_reg		<= (others => '0');
					data_num					<= (others => '0');
					data_equal_pre 		<= '0';
				end if;
			end if;
		end if;
	end process;
	

--	compare_total_over	<= compare_over_reg;	
	process (sys_clk_80M, sys_rst_n) begin
		if(sys_rst_n = '0') then
			compare_total_over<= (others => '0');
			compare_total_cnt	<= (others => '0');
			compare_error_cnt	<= (others => '0');
			compare_cnt_reg1	<= (others => '0');
			compare_cnt_reg2	<= (others => '0');
		elsif (sys_clk_80M'event and sys_clk_80M = '1') then
			compare_cnt_reg1	<= compare_cnt_reg;
			compare_total_over<= compare_over_reg;
			compare_error_cnt	<= compare_err_reg;
			compare_error_cnt(31)	<= '0';
			compare_total_cnt	<= compare_cnt_reg2;
			compare_total_cnt(31)	<= '0';
			
		end if;
	end process;
---- The following code must appear in the VHDL architecture
---- body. Substitute your own instance name and net names.
--
--------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
kz_ram_inst : kz_ram
  PORT MAP (
    clka => sys_clk_80M,
    wea(0) => ram_wr_en,
    addra => ram_wr_addr(11 downto 0),
    dina => ram_wr_data,
    clkb => sys_clk_200M,
    addrb => ram_rd_addr(10 downto 0),
    doutb => ram_rd_data
  );
end Behavioral;

