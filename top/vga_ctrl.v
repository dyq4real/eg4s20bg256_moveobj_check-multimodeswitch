module  vga_ctrl
(
    input  wire                         vga_clk                    ,//输入工作时钟,频率65MHz
    input  wire                         sys_rst_n                  ,//输入复位信号,低电平有效
    input  wire        [  15:0]         pix_data                   ,

    output wire                         data_req                   ,
    output reg                          vga_hs                     ,
    output reg                          vga_vs                     ,
    output reg         [  23:0]         rgb_888                     
);
parameter H_SYNC    =   11'd128	 ,   //行同步
          H_BACK    =   11'd88	 ,   //行时序后沿
          H_VALID   =   11'd800	 ,   //行有效数据
          H_FRONT   =   11'd40	 ,   //行时序前沿
          H_TOTAL   =   11'd1056 ;   //行扫描周期
parameter V_SYNC    =   11'd4	 ,   //场同步
          V_BACK    =   11'd23	 ,   //场时序后沿
          V_VALID   =   11'd600	 ,   //场有效数据
          V_FRONT   =   11'd1	 ,   //场时序前沿
          V_TOTAL   =   11'd628  ;   //场扫描周期
//wire  define
wire                                    rgb_valid                  ;//VGA有效显示区域
wire                                    hsync                      ;
wire                                    vsync                      ;
wire                   [  23:0]         vga_rgb_r                  ;
//reg   define
reg                    [  10:0]         cnt_h                      ;//行同步信号计数器
reg                    [  10:0]         cnt_v                      ;//场同步信号计数器

//行计数器对像素时钟计数
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        cnt_h <= 11'd0;                                  
    else begin
        if(cnt_h < H_TOTAL - 1'b1)                                               
            cnt_h <= cnt_h + 1'b1;                               
        else 
            cnt_h <= 11'd0;  
    end
end
//场计数器对行计数
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        cnt_v <= 11'd0;                                  
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)                                               
            cnt_v <= cnt_v + 1'b1;                               
        else 
            cnt_v <= 11'd0;  
    end
end
//vga_vs:场同步信号
assign  vsync = (cnt_v  <=  V_SYNC - 1'd1) ? 1'b0 : 1'b1  ;
//vga_hs:行同步信号
assign  hsync = (cnt_h  <=  H_SYNC - 1'd1) ? 1'b0 : 1'b1  ;
//rgb_valid:VGA有效显示区域
assign  rgb_valid = (((cnt_h >= H_SYNC + H_BACK )
                    && (cnt_h < H_SYNC + H_BACK  + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK)
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;
//data_req:像素点色彩信息请求信号,超前rgb_valid信号一个时钟周期
assign  data_req = (((cnt_h >= H_SYNC + H_BACK  - 1'b1)
                    && (cnt_h < H_SYNC + H_BACK  + H_VALID - 1'b1))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;
wire [23:0] vga_rgb888;
//rgb:输出像素点色彩信息
wire [7:0] vga_r,vga_g,vga_b;
assign vga_r = {pix_data[15:11],pix_data[15:13]};
assign vga_g = {pix_data[10:5],pix_data[10:9]};
assign vga_b = {pix_data[4:0],pix_data[4:2]};
assign  vga_rgb_r = (rgb_valid == 1'b1) ? vga_rgb888 : 24'b0 ;
assign vga_rgb888 = {vga_r,vga_g,vga_b};
//*打拍同步到当前时钟
always @(posedge vga_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
    	vga_hs  <= 1'b0;
        vga_vs  <= 1'b0;
        rgb_888 <= 24'd0;
    end
    else begin
        vga_hs  <= hsync;
        vga_vs  <= vsync;
        rgb_888 <= vga_rgb_r;
    end
end

endmodule