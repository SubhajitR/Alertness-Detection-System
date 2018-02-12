`timescale 1ns / 1ps

module tb_ad_with_wdt;

	// Inputs //
	reg clock,reset,in_put;
	
	
	// Outputs //
	wire ring,green,yellow,red;
	
	
	// Instantiate the Unit Under Test (UUT) //
	ad_with_wdt dut(
		.clock(clock), 
		.reset(reset),
		.in_put(in_put), 
		.ring(ring),
		.green(green),
		.yellow(yellow),
		.red(red)
	);
	
	initial clock=0;
	always #10 clock= ~clock;

	initial fork
		// Initialize Inputs //		
		reset = 0;
		in_put = 0;
		
		#100 reset=1;
		
		
		// delays should be changed while verifying multiple cases at once //
		
		
		// case-1: when no response is given //
			// no need of in_put 
		
		// case-2: response is given when red led glows //
			//#5500 in_put=1;
			//#5560 in_put=0;
		
		// case-3: response is given when yellow led glows //
			//#5000 in_put=1;
			//#5060 in_put=0;
		
		// case-4: response is given when green led glows //
			//#3300 in_put=1;	
			//#3360 in_put=0;
		
		// case-5: when response is given in unnecessary states //
			//#2000 in_put=1;
			//#2060 in_put=0;
			//#4000 in_put=1;
			//#4060 in_put=0;
		
		// case-6: when response button is always active //
			//#2000 in_put=1;
		    // another subcase of case 6 //
				//#3300 in_put=1;
			
    join
      
endmodule