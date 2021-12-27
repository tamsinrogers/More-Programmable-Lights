-- Tamsin Rogers
-- 10/9/20
-- CS232 Project5
-- pld2.vhd
-- implements the circuit and uses the pldrom as a component

-- Quartus II VHDL Template
-- Four-State Moore State Machine

-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pld2 is

	port
	(
		clk		 : in	std_logic;
		reset	 	 : in	std_logic;								-- key0
		fastButton	 	 : in	std_logic;						-- key1
		pause	 	 : in	std_logic;								-- key2
		lightsig	 : out	std_logic_vector(7 downto 0);
		IRView	 : out	std_logic_vector(9 downto 0)
	);

end entity;

architecture rtl of pld2 is

	component pldrom_task9

	port 
	(
		addr	:  in std_logic_vector(3 downto 0);
		data  : out std_logic_vector(9 downto 0)
	);
	
	end component;

	type state_type is (sFetch, sExecute1, sExecute2);	-- state machine
	
	-- internal signals (3C)
	signal IR			:	std_logic_vector(9 downto 0);	-- register
	signal PC			:	unsigned(3 downto 0);			-- register
	signal LR			:	unsigned(7 downto 0);			-- drives board LED dislplay
	signal ROMvalue	:	std_logic_vector(9 downto 0);

	-- Register to hold the current state
	signal state   : state_type;
	signal slowclock : std_logic;								-- the slowclock signal
  	signal counter: unsigned (24 downto 0);				-- the counter to be used in the slowclock
	
	signal ACC	:	unsigned (7 downto 0);
	signal SRC : unsigned(7 downto 0);
	
	-- signal lightsig : std_logic_vector(7 downto 0);

begin

	pldrom1: pldrom_task9										
		port map(addr => std_logic_vector(PC), data => ROMvalue);

	-- slow down the clock
  process(clk, reset) 
    begin
      if reset = '0' then
        counter <= "0000000000000000000000000";
		  
      elsif (rising_edge(clk)) then
			if fastButton = '0' then							-- if fastButton (key1) pressed
				counter <= counter + 12;						-- run faster
			else
				counter <= counter + 1;							-- slowclock case
			end if;
      end if;
  end process;
	
  slowclock <= counter(24);
 
	-- Logic to advance to the next state
	process (slowclock, reset)
	begin
	
		if reset = '0' then
			state <= sFetch;
			PC <= "0000";
			IR <= "0000000000";
			LR <= "00000000";
			ACC <= "00000000";
			SRC <= "00000000";
			
		elsif (rising_edge(slowclock) and pause = '1') then
		--elsif (rising_edge(clk)) then
			case state is
			
				when sFetch =>
					IR <= ROMvalue;
					PC <= PC+1;
					state <= sExecute1;
					
				when sExecute1 =>
			
					case IR(9 downto 8) is
					
						when "00" =>
							-- MOVE (copy data from source to destination)
							case IR(5 downto 4) is						-- bits 5 & 4 of the IR control SRC
								when "00" => 							
									SRC <= ACC;				
								when "01" => 							
									SRC <= LR;
								when "10" => 	
									SRC <= IR(3) & IR(3) & IR(3) & IR(3) & unsigned(IR(3 downto 0));	
								when "11" => 							
									SRC <= "11111111";
								when others =>
									null;
							end case;
					
						when "01" =>
							-- BINARY OPERATIONS (execute a binary operation on the destination & source, store result in destination)
							case IR(4 downto 3) is
								when "00" =>					
									SRC <= ACC;
								when "01" =>
									SRC <= LR;
								when "10" =>
									SRC <= IR(1) & IR(1) & IR(1) & IR(1) & IR(1) & IR(1) & unsigned(IR(1 downto 0));
								when "11" =>
									SRC <= "11111111";
								when others =>
									null;
							end case;
							
						when "10" =>
							-- BRANCH #1 (branch to given address)
							PC <= unsigned(IR(3 downto 0));
					
						when "11" =>
							-- BRANCH #2 (branch to given address if source register = 0)
							--if SRC = ACC then
							--	PC <= unsigned(IR(3 downto 0));
							--end if;
							
							--if SRC = LR then
							--	PC <= unsigned(IR(3 downto 0));
							--end if;
							
							if IR(2) = '1' and LR = "00000000" then
								PC <= unsigned(IR(3 downto 0));
								elsif IR(2) = '0' and ACC = "00000000" then
									PC <= unsigned(IR(3 downto 0));
							end if;
							
							
						when others =>
							null;
						
						end case;
						state <= sExecute2;								
						
				when sExecute2 =>
				
					case IR(9 downto 8) is
					
						when "00" =>
							-- MOVE (copy data from source to destination)
							case IR(7 downto 6) is	
							
								when "00" => 							
									ACC <= SRC;	
								when "01" => 							
									LR <= SRC;
								when "10" => 							
									--ACC(3 downto 0) <= SRC(3 downto 0);
									ACC <= "0000" & SRC(3 downto 0);
								when "11" => 							
									--ACC(7 downto 4) <= SRC(7 downto 4);
									ACC <= SRC(7 downto 4) & "0000";
								when others =>
									null;
									
							end case;
					
						when "01" =>
							-- BINARY OPERATIONS (execute a binary operation on the destination & source, store result in destination)
								
							case IR(7 downto 5) is
							
							-- ADD
							when "000" =>
								case IR(2) is
									 when '0' =>
										 ACC <= ACC + SRC;
									 when '1' =>
										 LR  <= LR  + SRC;
									 when others=>
										null;
								 end case;
						
							-- SUBTRACT
							 when "001"=>
								 case IR(2) is
									 when '0' =>
										 ACC <= ACC - SRC;
									 when '1' =>
										 LR  <= LR  - SRC;
									 when others=>
										null;
								 end case;

							 -- SHIFT LEFT
							 when "010"=>
								 case IR(2) is
									 when '0' =>
										 ACC <= ACC(6 downto 0) & '0';
									 when '1' =>
										 LR  <= LR(6 downto 0) & '0';
									 when others=>
										null;
								 end case;
								
							-- SHIFT RIGHT
							 when "011"=>
								 case IR(2) is
									 when '0' =>
										 ACC <= ACC(7) & ACC(7 downto 1);
									 when '1' =>
										 LR  <= LR(7) & LR(7 downto 1);
									 when others=>
										null;
								 end case;
						
							-- XOR
							when "100" =>
								case IR(2) is
									 when '0' =>
										 ACC <= ACC XOR SRC;
									 when '1' =>
										 LR  <= LR  XOR SRC;
									 when others=>
										null;
								 end case;
						
							-- AND
							 when "101"=>
								 case IR(2) is
									 when '0' =>
										 ACC <= ACC AND SRC;
									 when '1' =>
										 LR  <= LR  AND SRC;
									 when others=>
										null;
								 end case;

							 -- ROTATE LEFT
							 when "110"=>
								 case IR(2) is
									 when '0' =>
										 ACC <= SRC ROL 1;
									 when '1' =>
										 LR  <= SRC  ROL 1;
									 when others=>
										null;
								 end case;
								
							-- ROTATE RIGHT
							 when "111"=>
								 case IR(2) is
									 when '0' =>
										 ACC <= SRC ROR 1;
									 when '1' =>
										 LR  <= SRC ROR 1;
									 when others=>
										null;
								 end case;
							
							when others =>
									null;
										
						end case; 	-- ends case IR(7 downto 5) 
						
						when others =>
							null;
					
					end case;		-- ends case IR(9 downto 8)
					
					state <= sFetch;
					
			end case;				-- ends case state
			
		end if;
	end process;

	IRview <= IR;
	lightsig <= std_logic_vector(LR);	-- connect internal signals to output signals
  	
end rtl;