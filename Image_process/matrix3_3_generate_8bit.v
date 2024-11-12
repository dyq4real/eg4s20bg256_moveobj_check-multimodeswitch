module matrix3_3_generate_8bit (
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,

    input  wire                         wr_en                      ,
    input  wire        [   7:0]         img_Y                      ,//输入灰度数据

    output reg                          sobel_en,
    output reg                          martrix_wr_en              ,
    output reg         [   7:0]         matrix_p11                 ,
    output reg         [   7:0]         matrix_p12                 ,
    output reg         [   7:0]         matrix_p13                 ,
    output reg         [   7:0]         matrix_p21                 ,
    output reg         [   7:0]         matrix_p22                 ,
    output reg         [   7:0]         matrix_p23                 ,
    output reg         [   7:0]         matrix_p31                 ,
    output reg         [   7:0]         matrix_p32                 ,
    output reg         [   7:0]         matrix_p33                  
);
    parameter                           CNT_PIC_MAX = 'D1601       ;
wire                   [   7:0]         row1_data                  ;
wire                   [   7:0]         row2_data                  ;

reg                                     pre_sobel_en               ;
reg                    [   1:0]         wr_en_dly0                 ;
reg                    [   7:0]         row3_data                  ;
reg                    [  11:0]         cnt_pic                    ;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        cnt_pic <= 1'b0;
    else if(cnt_pic >= CNT_PIC_MAX)
        cnt_pic <= CNT_PIC_MAX;
    else if(wr_en == 1'b1)
        cnt_pic <= cnt_pic + 1'b1;
end
//当前数据放在第3行
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        row3_data <= 0;
    else begin
        if(wr_en)                                                   //数据传入使能
            row3_data <= img_Y ;
        else
            row3_data <= row3_data ;
    end
end
shift_register u_shift_register_8bit(
    .clken                             (wr_en                     ),
    .clock                             (sys_clk                   ),
    .shiftin                           (row3_data                 ),
    .shiftout                          (                          ),
    .taps0x                            (row2_data                 ),
    .taps1x                            (row1_data                 ) 
);
//打两拍以便同步信号
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)begin
        wr_en_dly0 <= 2'b00;
        martrix_wr_en <= 1'b0;
    end
    else begin
        wr_en_dly0[0] <= wr_en;
        wr_en_dly0[1] <= wr_en_dly0[0];
        martrix_wr_en <= wr_en_dly0[1];
    end
end
//在同步信号控制下，输出图像矩阵
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        {matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
    end
    else if(martrix_wr_en == 1'b1 && cnt_pic == CNT_PIC_MAX) begin
        {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p12, matrix_p13, row1_data};
        {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p22, matrix_p23, row2_data};
        {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p32, matrix_p33, row3_data};
    end
    else begin
        {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p11, matrix_p12, matrix_p13};
        {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p21, matrix_p22, matrix_p23};
        {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p31, matrix_p32, matrix_p33};
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)begin
        pre_sobel_en <= 1'b0;
    end
    else if(cnt_pic == CNT_PIC_MAX && martrix_wr_en == 1'b1)begin
        pre_sobel_en <= 1'b1;
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
    	sobel_en <= 1'b0;
    else 
        sobel_en <= pre_sobel_en;
end
endmodule                                                           //martix3×3_generate