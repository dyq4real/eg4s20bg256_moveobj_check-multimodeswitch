module Mode_Switch( 
	input 		wire			clk,
    input 		wire			rst_n,
    input		wire [15:0]			Switch,

    output 	reg [4:0]			mode

);



always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
        mode <= 4'd0;
    end	
	else begin	
    	if(Switch[0] == 1&&Switch[1] == 0&&Switch[2] == 0&&Switch[3] == 0&&Switch[4] == 0&&Switch[5] == 0&&Switch[6] == 0)	begin	
            mode  <= 4'd1;
        end	
        else if(Switch[0] == 1&&Switch[1] == 1&&Switch[2] == 0&&Switch[3] == 0&&Switch[4] == 0&&Switch[5] == 0&&Switch[6] == 0)	begin	
            mode  <= 4'd2;
        end	
        else if(Switch[0] == 1&&Switch[1] == 1&&Switch[2] == 1&&Switch[3] == 0&&Switch[4] == 0&&Switch[5] == 0&&Switch[6] == 0)	begin		
            mode  <= 4'd3;
        end	
        else if(Switch[0] == 1&&Switch[1] == 1&&Switch[2] == 1&&Switch[3] == 1&&Switch[4] == 0&&Switch[5] == 0&&Switch[6] == 0)	begin	
            mode  <= 4'd4;
        end	
        else if(Switch[0] == 1&&Switch[1] == 1&&Switch[2] == 1&&Switch[3] == 1&&Switch[4] == 1&&Switch[5] == 0&&Switch[6] == 0)	begin	
            mode  <= 4'd5;
        end	
        else if(Switch[0] == 1&&Switch[1] == 1&&Switch[2] == 1&&Switch[3] == 1&&Switch[4] == 1&&Switch[5] == 1&&Switch[6] == 0)	begin
            mode  <= 4'd6;
        end
         else if(Switch[0] == 1&&Switch[1] == 1&&Switch[2] == 1&&Switch[3] == 1&&Switch[4] == 1&&Switch[5] == 1&&Switch[6] == 1)	begin
            mode  <= 4'd7;
        end	  	  
        else begin	
           mode  <= 4'd0;
        end	
    end	
    
end	

endmodule
