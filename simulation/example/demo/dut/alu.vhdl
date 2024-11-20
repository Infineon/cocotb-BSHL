// **************************************************************************
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  Description : ALU DUT
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//  *****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
port(   clk : in std_logic; --clock
        a,b : in signed(31 downto 0); --input
        op : in unsigned(2 downto 0); --Operation 
        r : out signed(31 downto 0)  --output 
        );
end alu;

architecture Behavioral of alu is

signal Reg1,Reg2,Reg3 : signed(31 downto 0) := (others => '0');
begin

Reg1 <= a;
Reg2 <= b;
r <= Reg3;

process(clk)
begin
    if(rising_edge(clk)) then 
        case op is
            when "000" => Reg3 <= Reg1 + Reg2;		-- addition
            when "001" => Reg3 <= Reg1 - Reg2;		-- subtraction
            when "010" => Reg3 <= not Reg1;		-- NOT 
            when "011" => Reg3 <= Reg1 nand Reg2;	-- NOR               
            when "100" => Reg3 <= Reg1 nor Reg2;	-- NAND  
            when "101" => Reg3 <= Reg1 and Reg2;	-- AND 
            when "110" => Reg3 <= Reg1 or Reg2;		-- OR    
            when "111" => Reg3 <= Reg1 xor Reg2;	-- XOR   
            when others =>Reg3 <= (others => 'U');
        end case;       
    end if; 
end process;    

end Behavioral;
