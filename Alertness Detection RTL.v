`timescale 1ns/1ps

module  ad_with_wdt(
				input clock,reset,in_put,		// circuit inputs ---- clock,reset and response button //
		        output ring,green,yellow,red	// circuit outputs ---- 3 LEDs and 1 bell //																							
				);

		wire wt_refresh;						// feedback signal from Alertness_Detection block to watchdog timer block //		
		wire wt_out;							// internal wire between AD and WDT //
		
		watchdog_timer dut1(clock,reset,wt_refresh,red,wt_out);     // Instantiation of watchdog timer module //
						
		alertness_detection dut2(clock,wt_out,in_put,ring,green,yellow,red,wt_refresh);   // Instantiation of alertness detection module //                     
		
endmodule


// watchdog timer (WDT) block //
module watchdog_timer(
			input clock,reset,wt_refresh,red,		// red is also used as a feedback signal //
			output reg wt_out						//output of WD timer --- reset for Alertness_Detection block //								
		   );
					
			reg [7:0] wt_counter;					// counts timer time //
			reg [1:0] flag; 						// internal variable used to hold reset state //
					
			always @(posedge clock,negedge reset) begin
				// when reset = 0,circuit is initialized //
				if(!reset)begin
					wt_counter = 1;
					wt_out = 0;
					flag = 1;                           
				end
				else begin
						//if there is positive feedback from AD block then circuit is refreshed // 
						if(wt_refresh)begin
							wt_counter = 1;
							wt_out = 1;	
							flag = 1;												
						end
						// normal timer operation, AD block is in active mode // 
						// if watchdog timer time exceeds 160, system is reset* //
						else if(wt_counter < 8'b1010_0000)begin    
							wt_out = 1;									
							wt_counter = wt_counter+1;
						end
						// *if timer is finished and AD block is in the final state then system will not be reset but //
						// timer will be refreshed otherwise the system is reset for sometime and then it is reinitialized //
						else begin									
							if(red)begin						  		
								wt_out = 1;						 
								wt_counter = 1;					 								
							end
							else begin							
								if(flag == 3)begin						
								    wt_out = 1;
								    wt_counter = 1;
								    flag = 1;
								end
								else begin
								    flag = flag+1;
									wt_out = 0;
							    end
						   
							end
						end
				end
			end
endmodule
//end of watchdog timer block //


// Alertness Detection (AD) block //
module alertness_detection(
		              input clk,rst,in_put,
		              output reg ring,green,yellow,red,wt_refresh
						  );
						  
	reg [7:0] count;				// port for counting time //
	reg [3:0] lfsr_out,hold;		// port	for LFSR output and holding LFSR output value //
	reg [2:0] state,next_state;         
	reg y;                         
	parameter a=0,b=1,c=2,d=3,e=4;    // assignment of states //


	// LFSR block //
	always @ (posedge clk or negedge rst) begin
		if(!rst)begin
			lfsr_out = 4'b1111;
			hold = 4'b1111;			// when circuit is initialized hold takes value 15 //
		end	
		else begin  
			y = lfsr_out[3]^lfsr_out[0];
			lfsr_out = {lfsr_out[2:0],y};
			// when AD is in the first state after response is given //
			// hold takes next random value from LFSR //
			if(state == a && in_put)
                hold = lfsr_out;
		end
	end
	// end of LFSR block //
 
	// State machine block //
	always @(posedge clk or negedge rst) 
	begin
		if(!rst)
			state <= a;
		else
			state <= next_state;
	end


	always @(posedge clk or negedge rst)
	begin
		if(!rst)begin
			count = 1;
			wt_refresh = 0;
		end		
		// if response is given in an unnecessary state(a,c), then bell rings untill response is withdrawn and count is paused //
		// otherwise whenever response is given in proper state(b,d,e), state change occurs //
		// Watchdog timer is refreshed and count restarts everytime state change occurs //
		else begin
			case(state)
				a: begin			                  // All LEDs are OFF, response is not required //
					wt_refresh = 0;
					if(in_put)
					   count = count;
					   
					else if(count < hold*10)begin   
					   count = count+1;          
					end
					else begin
					   count = 1;
					   next_state = b;
                       wt_refresh = 1;                       						
				    end 	
				   end
				   
				b: begin							// only green LED will glow, response can be given //	
					wt_refresh = 0;
					if(in_put)begin
						count = 1;
						next_state = a;
						wt_refresh = 1;						             
					end
					else begin
						if(count != 10)begin       
							count = count+1;							     
						end
						else begin
							count = 1;
							next_state = c;
                            wt_refresh = 1;                            
                        end    
					end
				   end
	
				c: begin							// all LEDs are OFF, response is not required //
					wt_refresh = 0;
					if(in_put)
					    count = count;
					    
					else if(count < hold*5)begin    						
						count = count+1;						
					end
					else begin
					   count = 1;
					   next_state = d;
                       wt_refresh = 1;                       
					end	
				   end

				d: begin							// only yellow LED will glow, response can be given //
					wt_refresh = 0;
					if(in_put)begin
						count = 1;
						next_state = a;
						wt_refresh = 1;						
					end
					else begin
						if(count != 10)begin       
						    count = count+1;						    
						end
						else begin
						    count = 1;
                            next_state = e;
                            wt_refresh = 1;
						end	 
					end
				   end
	
				e: begin 							// red LED glows and bell rings, response must be given //
					wt_refresh = 0;
					if(in_put)begin
						count = 1;
						next_state = a;
						wt_refresh = 1;						
					end
					else
						next_state = e;
				   end
	
				default: begin 
					next_state = a;
					count = 1;
					end
			endcase
		end
	end
	
	// state output //
	always @(state or in_put) begin           
		case(state)
			a: begin
				green=0;
				yellow=0;
				red=0;
				if(in_put)                     
					ring=1;
				else
					ring=0;
			   end
			b: begin 
				green=1;
				yellow=0;
				red=0;
				ring=0;
			   end
			c: begin
				green=0;
				yellow=0;
				red=0;
				if(in_put)
					ring=1;
				else                       
					ring=0;
						
			   end
			d: begin 
				green=0;
				yellow=1;
				red=0; 
				ring=0;
			   end
			e: begin 
				green=0;
				yellow=0;
				red=1;
				ring=1;
			   end
			default: begin
			    green=0;
				yellow=0;                  
				red=0;
				ring=0;
			end
				
		endcase
	end
	// end of state machine block //
	
endmodule