module img1bit_dilation (
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,

    input  wire                         wr_en                      ,
    input  wire                         img_1bit_in                ,
    input  wire                         pre_href                   ,
    input  wire                         pre_vsync                  ,

    output wire                         dilation_vsync             ,
    output wire                         dilation_href              ,
    output reg                          dilation_wr_en             ,
    output wire                         img_1bit_out               ,
    output wire        [  15:0]         dilation_data               
);
(*keep = 1*)wire                        matrix_p11, matrix_p12, matrix_p13;//3X3 Matrix output
(*keep = 1*)wire                        matrix_p21, matrix_p22, matrix_p23;
(*keep = 1*)wire                        matrix_p31, matrix_p32, matrix_p33;
wire                                    matrix_wr_en_out           ;
wire                                    matrix_hs                  ;
wire                                    matrix_vs                  ;
reg                    [   1:0]         wr_en_dly                  ;
reg                    [   2:0]         vsync_reg                  ;
reg                    [   2:0]         href_reg                   ;
(*nprune = 1*)reg                       post_img_Bit1,	post_img_Bit2,	post_img_Bit3,post_img_Bit4;

VIP_Matrix_Generate_3X3_1bit u_VIP_Matrix_Generate_3X3_1bit(
    .clk                               (sys_clk                   ),
    .rst_n                             (sys_rst_n                 ),
    .per_frame_vsync                   (pre_vsync                 ),
    .per_frame_href                    (pre_href                  ),
    .per_frame_clken                   (wr_en                     ),
    .pre_1bit                          (img_1bit_in               ),

    .matrix_frame_vsync                (matrix_vs                 ),
    .matrix_frame_href                 (matrix_hs                 ),
    .matrix_frame_clken                (matrix_wr_en_out          ),
    .matrix_p11                        (matrix_p11                ),
    .matrix_p12                        (matrix_p12                ),
    .matrix_p13                        (matrix_p13                ),
    .matrix_p21                        (matrix_p21                ),
    .matrix_p22                        (matrix_p22                ),
    .matrix_p23                        (matrix_p23                ),
    .matrix_p31                        (matrix_p31                ),
    .matrix_p32                        (matrix_p32                ),
    .matrix_p33                        (matrix_p33                ) 
);

//*黑色为0，全&操作实现膨胀，即一个为0全部为0
//Step1
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)
        begin
        post_img_Bit1 <= 1'b0;
        post_img_Bit2 <= 1'b0;
        post_img_Bit3 <= 1'b0;
        end
    else
        begin
        post_img_Bit1 <= matrix_p11 & matrix_p12 & matrix_p13;
        post_img_Bit2 <= matrix_p21 & matrix_p22 & matrix_p23;
        post_img_Bit3 <= matrix_p31 & matrix_p32 & matrix_p33;
        end
end

//Step 2
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)
        post_img_Bit4 <= 1'b0;
    else
        post_img_Bit4 <= post_img_Bit1 & post_img_Bit2 & post_img_Bit3;
end

assign img_1bit_out = dilation_wr_en ? post_img_Bit4 : 1'b0;
assign dilation_data = img_1bit_out ? 16'hffff : 16'h0000;

//*同步行场信号
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)begin
        wr_en_dly[0]  <= 1'b0;
        wr_en_dly[1]  <= 1'b0;
        dilation_wr_en <= 1'b0;
    end
    else begin
        wr_en_dly[0]  <= wr_en;
        wr_en_dly[1]  <= wr_en_dly[0];
        dilation_wr_en <= wr_en_dly[1];
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
    	href_reg <= 3'd0;
        vsync_reg <= 3'd0;
    end
    else begin
        href_reg <= {href_reg[1:0],pre_href};
        vsync_reg <= {vsync_reg[1:0],pre_vsync};
    end
end
assign dilation_vsync = vsync_reg[2];
assign dilation_href = href_reg[2];
endmodule                                                           //isp_1bit_dilation