module seg_4
#(
	parameter CNT_TIME = 2400_000 //0.1s
)
( 
	input	wire       clk_24m,
	input   wire rst_n,
    input   wire  [3:0] 	sm_seg_num ,
    output	wire [7:0] sm_seg,
    output	wire [3:0] sm_bit
);
reg [24:0] 	cnt;
//计数器，约为10ms扫描一次
reg [17:0] 	cnt_w;
//数码管位选
reg [3:0] 	sm_bit_reg;

reg [7:0]	sm_seg_reg;	
localparam
			S0 = 4'b0000 ,
			S1 = 4'b0001 ,
			S2 = 4'b0010 ,
			S3 = 4'b0011 ,
			S4 = 4'b0100 ,
			S5 = 4'b0101 ,
			S6 = 4'b0110 ,
			S7 = 4'b0111 ,
			S8 = 4'b1000 ,
			S9 = 4'b1001 ;
		
always@(posedge clk_24m or negedge rst_n)
begin
	if(!rst_n)
		cnt_w <= 18'd0;
	else if(cnt_w == 18'b111_111_111_111_111_111)  
	// else if(&cnt_w)  
		cnt_w <= 18'd0;
	else
		cnt_w <= cnt_w + 1;
end		
always@(*)
begin
	case ( sm_seg_num )
	S0:
		sm_seg_reg <= 8'hc0;
	S1:               
		sm_seg_reg <= 8'hf9;
	S2:               
		sm_seg_reg <= 8'ha4;
	S3:               
		sm_seg_reg <= 8'hb0;
	S4:               
		sm_seg_reg <= 8'h99;
	S5:               
		sm_seg_reg <= 8'h92;
	S6:               
		sm_seg_reg <= 8'h82;
	S7:               
		sm_seg_reg <= 8'hf8;
	S8:               
		sm_seg_reg <= 8'h80;
	S9:               
		sm_seg_reg <= 8'h90;
	default:sm_seg_reg <= 8'hc0;
	endcase
end	
					
assign sm_seg = sm_seg_reg;	
assign sm_bit = 4'b0000;	
	
endmodule
