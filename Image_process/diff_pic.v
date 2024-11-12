module diff_pic           
(
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,

    input  wire                         pre_wr_en                  ,
    input  wire        [   7:0]         new_pic                    ,
    input  wire        [   7:0]         last_pic                   ,
    input  wire                         pre_vsync                  ,
    input  wire                         pre_href                   ,
    
    output wire                         diff_vsync                 ,
    output wire                         diff_href                  ,
    output reg                          diff_1bit_out              ,
    output wire                         diff_wr_en                 ,
    //output wire        [  15:0]         raw_rgb565                 ,
    output wire        [  15:0]         diff_rgb_565                
);
    parameter                           DIFF_THR = 10'd50  ;
(*noprune*) reg        [   7:0]         last_pic_reg0              ;
(*noprune*) reg        [   7:0]         new_pic_reg0               ;
reg [7:0] new_pic_reg1;
(*noprune*) reg        [   1:0]         wr_en_dly                  ;

reg                    [   1:0]         vsync_reg                  ;
reg                    [   1:0]         href_reg                   ;
//*将当前数据打一拍，前一帧与当前帧差两个时钟周期，读出数据使用了一个clk
/* always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)begin
        last_pic_reg0 <= 1'b0;
    end
    else begin
        last_pic_reg0 <= last_pic;
    end
end */
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)begin
        new_pic_reg0 <= 1'b0;
        new_pic_reg1 <= 1'b0;
    end
    else begin
        new_pic_reg0 <= new_pic;
        new_pic_reg1 <= new_pic_reg0;
    end
end
//*差分计算
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        diff_1bit_out <= 1'b0;
    else if(wr_en_dly[0] == 1'b1) begin
        if(last_pic >= new_pic_reg0) begin
            if((last_pic - new_pic_reg0) >= DIFF_THR)
                diff_1bit_out <= 1'b0;//*输出黑色，显示区域
            else
                diff_1bit_out <= 1'b1;
        end
        else if(new_pic_reg0 > last_pic) begin
            if((new_pic_reg0 - last_pic) >= DIFF_THR)
                diff_1bit_out <= 1'b0;
            else
                diff_1bit_out <= 1'b1;
        end
    end
end

//*rgb_data
assign diff_rgb_565 = diff_1bit_out ? 16'hffff : 16'h0000;
//assign raw_rgb565 = {new_pic_reg1[7:3],new_pic_reg1[7:2],new_pic_reg1[7:3]};

//*同步wr_en 打两拍
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
        wr_en_dly <= 1'd0;
        vsync_reg <= 1'd0;
        href_reg  <= 1'd0;
    end
    else begin
        wr_en_dly <= {wr_en_dly[0],pre_wr_en};
        vsync_reg <= {vsync_reg[0],pre_vsync};
        href_reg  <= { href_reg[0],pre_href };
    end
end
assign diff_wr_en = wr_en_dly[1];
assign diff_vsync = vsync_reg[1];
assign diff_href  = href_reg[1] ;
endmodule