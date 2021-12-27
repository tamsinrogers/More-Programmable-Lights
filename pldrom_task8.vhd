-- Tamsin Rogers
-- 10/19/20
-- CS232 Project5
-- pldrom_task8.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pldrom_task8 is
	port 
	(
		addr :  in std_logic_vector (3 downto 0);		-- address of the instruction to return	(4 bit)
		data : out std_logic_vector (9 downto 0)		-- the instruction to be executed (10 bit)
	);

end entity;

architecture rtl of pldrom_task8 is
begin

	data <= 
    "0010100000" when addr = "0000" else	-- 0: move 0000 from the IR into the low 4 bits of the ACC 	
    "0011100011" when addr = "0001" else 	-- 1: move 0001 from the IR into the high 4 bits of the ACC
    "0001000000" when addr = "0010" else 	-- 2: move 16 (10000) from the ACC into the LR
    
    "0100110101" when addr = "0011" else 	-- 3: subtract 1 from LR
    "1110000110" when addr = "0100" else 	-- 4: end the loop by branching to instruction #6
    "1000000011" when addr = "0101" else	-- 5: continue the loop by branching back to instruction #3 while the LR has value > zero
    
    "0000100000" when addr = "0110" else 	-- 6: move 00000000 from the IR into the LR
    "0010101000" when addr = "0111" else 	-- 7: move 8 (1000) from the IR into the low 4 bits of the ACC
    
    "0100110001" when addr = "1000" else 	-- 8: subtract 1 from ACC
    
    "0001101111" when addr = "1001" else 	-- 9: move 11111111 from the IR into the LR
    "0001100000" when addr = "1010" else 	-- 10: move 00000000 from the IR into the LR
	"1100000000" when addr = "1011" else	-- 11: start the program over by branching back to instruction #0
	"1000001000" when addr = "1100" else	-- 12: continue the loop by branching back to instruction #8 while ACC still has value > zero
    "1111111111";      
    
end rtl;
