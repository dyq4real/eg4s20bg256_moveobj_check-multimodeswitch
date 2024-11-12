module rgb_ycbcr (
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,

    input  wire                         pre_wr_en                  ,
    input  wire        [  15:0]         ov5640_data                ,
    input  wire                         pre_href                   ,
    input  wire                         pre_vsync                  ,
    
    output reg                          wr_en_dly                  ,
    output reg                          wr_en_dly_r                ,
    output wire        [  15:0]         rgb565_data                ,
    output wire        [   7:0]         img_y                      ,
    output wire        [   7:0]         img_cb                     ,
    output wire        [   7:0]         img_cr                     ,
    output wire                         yuv_href                   ,
    output wire                         yuv_vsync                   
);

reg                    [  15:0]         rgb_r_m0, rgb_r_m1, rgb_r_m2;
reg                    [  15:0]         rgb_g_m0, rgb_g_m1, rgb_g_m2;
reg                    [  15:0]         rgb_b_m0, rgb_b_m1, rgb_b_m2;
reg                    [  15:0]         img_y0                     ;//存放加法完成结果
reg                    [  15:0]         img_cb0                    ;//存放加法完成结果
reg                    [  15:0]         img_cr0                    ;//存放加法完成结果
reg                    [   7:0]         img_y1                     ;//用来存放数据高八位以表示右移八位
reg                    [   7:0]         img_cb1                    ;//用来存放数据高八位以表示右移八位
reg                    [   7:0]         img_cr1                    ;//用来存放数据高八位以表示右移八位
reg                                     wr_en_dly0                 ;
reg                                     wr_en_dly1                 ;
reg                                     wr_en_dly2                 ;
reg                                     wr_en_dly3                 ;
reg                    [   2:0]         vsync_reg                  ;
reg                    [   2:0]         href_reg                   ;
wire                   [   4:0]         img0_red                   ;//起始的rgb分量
wire                   [   4:0]         img0_blue                  ;//起始的rgb分量
wire                   [   5:0]         img0_green                 ;//起始的rgb分量

assign img0_red =   ov5640_data[15:11];
assign img0_blue =  ov5640_data[4:0];
assign img0_green = ov5640_data[10:5];

wire                   [   7:0]         rgb_888_r                  ;//rgb565 to 888
wire                   [   7:0]         rgb_888_g                  ;//rgb565 to 888
wire                   [   7:0]         rgb_888_b                  ;//rgb565 to 888
//*rule:用高位去填补低位
assign rgb_888_r = {img0_red,img0_red[4:2]}     ;
assign rgb_888_g = {img0_green,img0_green[5:4]} ;
assign rgb_888_b = {img0_blue,img0_blue[4:2]}   ;

assign img_y       = wr_en_dly ? img_y1  : 8'd0  ;
assign img_cb      = wr_en_dly ? img_cb1 : 8'd0  ;
assign img_cr      = wr_en_dly ? img_cr1 : 8'd0  ;
assign rgb565_data = wr_en_dly ? {img_y[7:3],img_y[7:2],img_y[7:3]} : 16'd0;
//RGB 888 to YCbCr

/********************************************************
            RGB888 to YCbCr
 Y  = 0.299R +0.587G + 0.114B
 Cb = 0.568(B-Y) + 128 = -0.172R-0.339G + 0.511B + 128
 CR = 0.713(R-Y) + 128 = 0.511R-0.428G -0.083B + 128

 Y  = (77 *R    +    150*G    +    29 *B)>>8
 Cb = (-43*R    -    85 *G    +    128*B)>>8 + 128
 Cr = (128*R    -    107*G    -    21 *B)>>8 + 128

 Y  = (77 *R    +    150*G    +    29 *B        )>>8
 Cb = (-43*R    -    85 *G    +    128*B + 32768)>>8
 Cr = (128*R    -    107*G    -    21 *B + 32768)>>8
*********************************************************/
//*step1 计算乘法项
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        rgb_r_m0 <= 16'd0;
        rgb_r_m1 <= 16'd0;
        rgb_r_m2 <= 16'd0;
        rgb_g_m0 <= 16'd0;
        rgb_g_m1 <= 16'd0;
        rgb_g_m2 <= 16'd0;
        rgb_b_m0 <= 16'd0;
        rgb_b_m1 <= 16'd0;
        rgb_b_m2 <= 16'd0;
    end
    else begin
        rgb_r_m0 <= rgb_888_r * 8'd77 ;
        rgb_r_m1 <= rgb_888_r * 8'd43 ;
        rgb_r_m2 <= rgb_888_r * 8'd128;
        rgb_g_m0 <= rgb_888_g * 8'd150;
        rgb_g_m1 <= rgb_888_g * 8'd85 ;
        rgb_g_m2 <= rgb_888_g * 8'd107;
        rgb_b_m0 <= rgb_888_b * 8'd29 ;
        rgb_b_m1 <= rgb_888_b * 8'd128;
        rgb_b_m2 <= rgb_888_b * 8'd21 ;
    end
end
//*step2:完成加法
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        img_y0  <= 16'd0;
        img_cb0 <= 16'd0;
        img_cr0 <= 16'd0;
    end
    else begin
        img_y0  <= rgb_r_m0 + rgb_g_m0 + rgb_b_m0;
        img_cb0 <= rgb_b_m1 - rgb_r_m1 - rgb_g_m1 + 16'd32768;
        img_cr0 <= rgb_r_m2 - rgb_g_m2 - rgb_b_m2 + 16'd32768;
    end
end
//*step3 括号内计算的数据右移8位
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        img_y1  <= 8'd0;
        img_cb1 <= 8'd0;
        img_cr1 <= 8'd0;
    end
    else begin
        img_y1  <= img_y0 [15:8];                                   //>>8
        img_cb1 <= img_cb0[15:8];                                   //>>8
        img_cr1 <= img_cr0[15:8];                                   //>>8
    end
end
//*打三拍
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)begin
        wr_en_dly  <= 1'b0;
        wr_en_dly0 <= 1'b0;
        wr_en_dly1 <= 1'b0;
        //wr_en_dly2 <= 1'b0;
        //wr_en_dly3 <= 1'b0;
        //wr_en_dly_r <= 1'b0;
    end
    else begin
        wr_en_dly0  <= pre_wr_en;
        wr_en_dly1  <= wr_en_dly0;
        wr_en_dly   <= wr_en_dly1;
        //wr_en_dly2  <= wr_en_dly;
        //wr_en_dly3 <= wr_en_dly2;
        //wr_en_dly_r <= wr_en_dly2;
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
    	vsync_reg <= 3'd0;
        href_reg  <= 3'd0;
    end
    else begin
        vsync_reg <= {vsync_reg[1],vsync_reg[0],pre_vsync};
        href_reg  <= {href_reg[1],href_reg[0],pre_href};
    end
end
assign yuv_vsync = vsync_reg[2];
assign yuv_href  = href_reg[2];
endmodule