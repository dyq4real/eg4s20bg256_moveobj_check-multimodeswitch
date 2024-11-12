module image_process
(
    input  wire                         sys_clk                    ,
    input  wire                         rst_n                      ,
    input  wire                         pre_wr_en                  ,
    input  wire        [  15:0]         isp_data_in                ,
    input  wire        [   7:0]         last_pic                   ,
    input  wire                         pre_vsync                  ,
    input  wire                         pre_href                   ,

    output wire                         isp_vsync                  ,
    output wire                         isp_href                   ,
    output wire                         isp_1bit_out               ,
    output wire                         isp_wr_en                  ,
    output wire        [  15:0]         isp_data_out               ,
    output reg        [   7:0]         img_Y                      ,//中值
    output reg                         median_wr_En, //原始使能

    output reg        [   7:0]         img_Y_r                      ,//原始数据
    output reg                         ycbcr_wr_en, //原始使能
    output reg        [  15:0]         erosion_rgb565               ,//腐蚀
    output reg							erosion_wr_en2,
    output reg        [  15:0]         dilation_data               ,//膨胀
    output reg                                    dilation_wr_en             ,

    output reg        [  15:0]			post_sobel,//边缘检测
    output reg							post3_frame_clken,
    output reg        [  15:0]         post_img_b,//二值化
    output reg                         post_b_clken
 //               
);
    parameter                           DIFF_THR = 'd50            ;
(*keep = 1*)wire                        diff_1bit                  ;
(*keep = 1*)wire                        diff_wr_en                 ;
(*keep = 1*)wire                        erosion_wr_en1             ;
(*keep = 1*)wire                        erosion_1bit_out1          ;
(*keep = 1*)wire                        yuv_href                   ;
(*keep = 1*)wire                        yuv_vsync                  ;

(*keep = 1*)wire                        diff_href                  ;
(*keep = 1*)wire                        diff_vsync                 ;
(*keep = 1*)wire                        erosion_href1              ;
(*keep = 1*)wire                        erosion_vsync1             ;
(*keep = 1*)wire                        erosion_1bit_out2          ;
//(*keep = 1*)wire                        erosion_wr_en2             ;
(*keep = 1*)wire                        erosion_vsync2             ;
(*keep = 1*)wire                        erosion_href2              ;
//(*keep = 1*)wire       [   7:0]         img_Y_r                    ;
(*keep = 1*)wire                        median_hs                  ;
(*keep = 1*)wire                        median_vs                  ;
//(*keep = 1*)wire                        median_wr_En               ;
wire                                    dilation_hs                ;
wire                                    dilation_vs                ;
//wire                                    dilation_wr_en             ;
wire                                    dilation_1bit              ;
//中间量定义
wire	[7:0]img_Y_r1;//原始
wire	ycbcr_wr_en1;
wire	[7:0]img_Y1;//滤波
wire	post_b_vsync1;//二值化
wire	post_b_href1;
wire	post_b_clken1;
wire	[15:0]post_img_b1;
wire	median_wr_En1;
wire	[15:0]erosion_rgb5651;//腐蚀
wire	erosion_wr_en21;
wire	[15:0]dilation_data1;//膨胀
wire	dilation_wr_en1;
wire	[15:0]post_sobel1;//sobel
wire	post3_frame_clken1;
//原始灰度
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
       ycbcr_wr_en <= ycbcr_wr_en1;
       img_Y_r <= img_Y_r1;
    end 
    else begin
       ycbcr_wr_en <= ycbcr_wr_en1;
       img_Y_r <= img_Y_r1;
    end 
end
//中值灰度
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
       median_wr_En <= median_wr_En1;
       img_Y <= img_Y1;
    end 
    else begin
       median_wr_En <= median_wr_En1;
       img_Y <= img_Y1;
    end 
end
//中值后的二值化
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
       post_b_clken <= post_b_clken1;
       post_img_b <= post_img_b1;
    end 
    else begin
       post_b_clken <= post_b_clken1;
       post_img_b <= post_img_b1;
    end 
end
//腐蚀
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
       erosion_wr_en2 <= post1_frame_clken;
       erosion_rgb565 <= post_img_Erosion;
    end 
    else begin
       erosion_wr_en2 <= post1_frame_clken;
       erosion_rgb565 <= post_img_Erosion;
    end 
end
//膨胀
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
       dilation_wr_en <= post2_frame_clken;
       dilation_data <= post_img_Dilation;
    end 
    else begin
       dilation_wr_en <= post2_frame_clken;
       dilation_data <= post_img_Dilation;
    end 
end
//sobel
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
       post3_frame_clken <= post3_frame_clken1;
       post_sobel <= post_sobel1;
    end 
    else begin
       post3_frame_clken <= post3_frame_clken1;
       post_sobel <= post_sobel1;
    end 
end
rgb_ycbcr u_rgb_ycbcr(
    .sys_clk                           (sys_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .pre_wr_en                         (pre_wr_en                 ),
    .ov5640_data                       (isp_data_in               ),
    .pre_href                          (pre_href                  ),
    .pre_vsync                         (pre_vsync                 ),
    .wr_en_dly                         (ycbcr_wr_en1               ),
    .yuv_href                          (yuv_href                  ),
    .yuv_vsync                         (yuv_vsync                 ),
    .rgb565_data                       (                          ),
    .img_y                             (img_Y_r1                   ),
    .img_cb                            (                          ),
    .img_cr                            (                          ) 
);
VIP_Gray_Median_Filter u_VIP_Gray_Median_Filter(
    .clk                               (sys_clk                   ),
    .rst_n                             (rst_n                     ),
    .pe_frame_vsync                    (yuv_vsync                 ),
    .pe_frame_href                     (yuv_href                  ),
    .pe_frame_clken                    (ycbcr_wr_en1               ),
    .pe_img_Y                          (img_Y_r1                   ),
    .pos_frame_vsync                   (median_vs                 ),
    .pos_frame_href                    (median_hs                 ),
    .pos_frame_clken                   (median_wr_En1              ),
    .pos_img_Y                         (img_Y1                     ) 
);
binarization u_binarization(
    //module clock
    .clk                (sys_clk    ),          // 时钟信号
    .rst_n              (rst_n  ),          // 复位信号（低有效）
    //图像处理前的数据接口
    .pre_frame_vsync    (median_vs),            // vsync信号
    .pre_frame_hsync    (median_hs),            // href信号
    .pre_frame_de       (median_wr_En1),            // data enable信号
    .color              (img_Y1),
    //图像处理后的数据接口
    .post_frame_vsync   (post_b_vsync1), // vsync信号
    .post_frame_hsync   (post_b_href1), // href信号
    .post_frame_de      (post_b_clken1   ), // data enable信号
    .post_binary(post_img_b1)
    //user interface
);
wire	post1_frame_vsync;
wire	post1_frame_href;
wire	post1_frame_clken;
wire	[15:0]post_img_Erosion;

	
Erosion_Detector u_Erosion_Detector(
    .clk         	 (sys_clk),
    .rst_n           (rst_n),
    
    .pre_frame_vsync (post_b_vsync1),
    .pre_frame_hsync (post_b_href1),
    .pre_frame_clken (post_b_clken1),
    .pre_sobel_img_Y (post_img_b1),
    
    .post_frame_vsync(post1_frame_vsync),
    .post_frame_hsync(post1_frame_href),
    .post_frame_clken(post1_frame_clken),	
    .post_img_Y      (post_img_Erosion)
    

);
wire	post2_frame_vsync;
wire	post2_frame_href;
wire	post2_frame_clken;
wire	[15:0]post_img_Dilation;
Dilation_Detector u_Dilation_Detector(
    .clk         	 (sys_clk),
    .rst_n           (rst_n),
    
    .pre_frame_vsync 	(post1_frame_vsync),
    .pre_frame_hsync 	(post1_frame_href),
    .pre_frame_clken 	(post1_frame_clken),
    .pre_Dilation_img_Y (post_img_Erosion),
    
    .post_frame_vsync	(post2_frame_vsync),
    .post_frame_hsync	(post2_frame_href),
    .post_frame_clken	(post2_frame_clken),
    .post_img_Y      	(post_img_Dilation),
    .post_img_Bit4		() 
);
wire	post3_frame_vsync;
wire	post3_frame_href;
Sobel_Process	u_Sobel_Process(
    .clk         	 (sys_clk),
    .rst_n           (rst_n),
    
    .pre_frame_vsync (post1_frame_vsync),
    .pre_frame_hsync (post1_frame_href),
    .pre_frame_clken (post1_frame_clken),
    .pre_sobel_img_Y (post_img_Dilation),//post_img_Dilation
    
    .post_frame_vsync(post3_frame_vsync),
    .post_frame_hsync(post3_frame_href),
    .post_frame_clken(post3_frame_clken1),	
    .post_img_Y      (post_sobel1)
);

 diff_pic
#(
    .DIFF_THR                          (DIFF_THR                  ) 
)
 u_diff_pic(
    .sys_clk                           (sys_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .pre_wr_en                         (ycbcr_wr_en1                  ),
    .pre_href                          (yuv_href                     ),
    .pre_vsync                         (yuv_vsync                     ),

    .diff_vsync                        (diff_vsync                ),
    .diff_href                         (diff_href                 ),
    .new_pic                           (img_Y1               ),
    .last_pic                          (last_pic                  ),
    .diff_1bit_out                     (diff_1bit                 ),
    .diff_wr_en                        (diff_wr_en                ),
    .diff_rgb_565                      (                          ) 
);
img1bit_erosion u_1bit_erosion1(
    .sys_clk                           (sys_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .wr_en                             (diff_wr_en                ),
    .img_1bit_in                       (diff_1bit                 ),
    .pre_href                          (diff_href                 ),
    .pre_vsync                         (diff_vsync                ),
    
    .erosion_href                      (erosion_href1             ),
    .erosion_vsync                     (erosion_vsync1            ),
    .erosion_wr_en                     (erosion_wr_en1            ),
    .img_1bit_out                      (erosion_1bit_out1         ),
    .erosion_rgb565                    (                          ) 
);
img1bit_erosion u_1bit_erosion2(
    .sys_clk                           (sys_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .wr_en                             (erosion_wr_en1            ),
    .img_1bit_in                       (erosion_1bit_out1         ),
    .pre_href                          (erosion_href1             ),
    .pre_vsync                         (erosion_vsync1            ),
    
    .erosion_href                      (erosion_href2             ),
    .erosion_vsync                     (erosion_vsync2            ),
    .erosion_wr_en                     (erosion_wr_en21            ),
    .img_1bit_out                      (erosion_1bit_out2         ),
    .erosion_rgb565                    (erosion_rgb5651                          ) 
);

img1bit_dilation u_1bit_dilation(
    .sys_clk                           (sys_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .wr_en                             (erosion_wr_en21            ),
    .img_1bit_in                       (erosion_1bit_out2         ),
    .pre_href                          (erosion_href2             ),
    .pre_vsync                         (erosion_vsync2            ),
    
    .dilation_href                     (dilation_hs               ),
    .dilation_vsync                    (dilation_vs               ),
    .dilation_wr_en                    (dilation_wr_en1            ),
    .img_1bit_out                      (dilation_1bit             ),
    .dilation_data                     (dilation_data1                          ) 
);
img1bit_dilation u_1bit_dilation2(
    .sys_clk                           (sys_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .wr_en                             (dilation_wr_en1            ),
    .img_1bit_in                       (dilation_1bit             ),
    .pre_href                          (dilation_hs               ),
    .pre_vsync                         (dilation_vs               ),

    .dilation_vsync                    (isp_vsync                 ),
    .dilation_href                     (isp_href                  ),
    .dilation_wr_en                    (isp_wr_en                 ),
    .img_1bit_out                      (isp_1bit_out              ),
    .dilation_data                     (isp_data_out              ) 
);



endmodule                                                           //isp_top