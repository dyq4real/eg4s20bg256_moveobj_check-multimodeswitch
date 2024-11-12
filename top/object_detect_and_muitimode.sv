module object_detect_and_muitimode (
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,
    input  wire                         cam_pclk                   ,
    input  wire                         cam_vs                     ,
    input  wire                         cam_hs                     ,
    input  wire        [   7:0]         cam_data                   ,

    output wire                         cam_scl                    ,
    inout  wire                         cam_sda                    ,

    output wire        [  23:0]         vga_rgb888                 ,
    output wire                         vga_hs                     ,
    output wire                         vga_vs                     ,
    output wire                         vga_clk                    ,
    output wire                         cam_rst_n                  ,
    output wire                         cam_pwdn                   ,

    output wire                         clk_50m                    ,
    output wire        [   3:0]         sel                        ,
    output wire        [   7:0]         seg_data                   ,

    output wire                         led_r                      ,
    output wire                         led_g                      ,
    output wire                         led_b                      ,
    output wire        [  15:0]         led                        ,
   	input wire			[15:0]			Switch						,
    output reg							buzzer_ctr,
    output reg			[3:0]			mode_out
    						 
);

assign	mode_out=~mode; 
    parameter                           DIFF_THR = 'D60            ;
    parameter                           CLK_FREQ = 'D40_000_000    ;
    parameter                           MIN_DISC = 'd100           ;
    parameter                           H_PIXEL     =   11'd800    ;//水平方向像素个数,用于设置SDRAM缓存大小
    parameter                           V_PIXEL     =   10'd600    ;//垂直方向像素个数,用于设置SDRAM缓存大小
wire                                    cfg_done                   ;
wire                                    sys_init_done              ;//初始化完成标志，摄像头+sdram
(*keep = 1*)wire       [  15:0]         ov5640_data_out            ;
(*keep = 1*)wire                        ov5640_wr_en               ;
wire									[3:0]	mode			;
wire                                    clk_100m                   ;
wire                                    clk_100m_shift             ;
(*keep = 1*)wire                        locked                     ;
//wire vga_clk;
wire                                    rst_n = locked & sys_rst_n ;

wire                                    ycbcr_wr_en                ;
(*keep = 1*)wire       [   7:0]         img_Y                      ;
(*keep = 1*)wire       [   7:0]         img_Y_r                     ;


(*keep = 1*)wire                        data_req                   ;
wire                   [   7:0]         last_pic                   ;
wire                   [   7:0]         new_pic                    ;
(*keep = 1*)wire                        isp_1bit_out               ;
(*keep = 1*)wire                        isp_wr_en                  ;
(*keep = 1*)wire                        isp_href                   ;
(*keep = 1*)wire                        isp_vsync                  ;
wire                   [  15:0]         isp_data_out               ;
(*keep = 1*)wire       [  15:0]         tft_rgb565                 ;
wire                                    ov5640_href_out            ;
wire                                    ov5640_vsync_out           ;
wire                   [  15:0]         boundary_data              ;
wire                                    boundary_wr_en             ;
reg									announce;

//*mul_obj_check
wire                                    mul_hs                     ;
wire                                    mul_vs                     ;
wire                                    mul_wr_en                  ;
wire [42:0] pos_data [15:0];
//*fusion
wire                                    fusion_hs                  ;
wire                                    fusion_vs                  ;
wire                                    fusion_wr_en               ;
wire                   [  15:0]         fusion_rgb565              ;
wire                   [  23:0]         fusion_rgb888              ;
wire                   [   7:0]         obj_num                    ;
wire                                    syn_wr_en                  ;
wire                                    syn_hs                     ;
wire                                    syn_vs                     ;
wire [15:0] syn_data ;  
(*keep = 1*)wire [15:0] vga_rgb;
(*keep = 1*)wire [15:0] rd_data;
wire                                    sdram_init_done            ;
assign sys_init_done = cfg_done /* & sdram_init_done */;
assign cam_rst_n = 1'b1;
assign cam_pwdn  = 1'b0;


clk_gen u_clk_gen(
    .refclk                            (sys_clk                   ),
    .reset                             (~sys_rst_n                ),
    .extlock                           (locked                    ),
    .clk0_out                          (                          ),
    .clk1_out                          (vga_clk                   ),
    .clk2_out                          (clk_100m                  ),
    .clk3_out                          (clk_100m_shift            ),
    .clk4_out                          (clk_50m                   ) 
);

Mode_Switch u_Mode_Switch(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
     
    .Switch(Switch),
    .mode(mode)

);
ov5640_top
#(
    .CLK_FREQ                          (CLK_FREQ                  ) 
)
u_camera_top(
    .sys_rst_n                         (rst_n                     ),
    .sys_clk                           (vga_clk                   ),
    .ov5640_pclk                       (cam_pclk                  ),
    .ov5640_href                       (cam_hs                    ),
    .ov5640_data                       (cam_data                  ),
    .sys_init_done                     (sys_init_done             ),

    .ov5640_vsync                      (cam_vs                    ),
    .ov5640_wr_en                      (ov5640_wr_en              ),
    .ov5640_data_out                   (ov5640_data_out           ),
    .cfg_done                          (cfg_done                  ),
    .cam_hs                            (ov5640_href_out           ),
    .cam_vs                            (ov5640_vsync_out          ),
    .sccb_scl                          (cam_scl                   ),
    .sccb_sda                          (cam_sda                   ) 
);

Sdram_Control_4Port u_Sdram_Control_4Port(
    .CTRL_CLK                          (clk_100m                  ),
    .SDRAM_CLK                         (clk_100m_shift            ),
    .RESET_N                           (rst_n                     ),

    .WR1_DATA                          ({8'd0,img_Y}              ),
    .WR1                               (ycbcr_wr_en               ),
    .WR1_ADDR                          (H_PIXEL*V_PIXEL           ),
    .WR1_MAX_ADDR                      (H_PIXEL*V_PIXEL*2         ),
    .WR1_LENGTH                        (10'd256                   ),
    .WR1_LOAD                          (~rst_n                    ),
    .WR1_CLK                           (cam_pclk                  ),
    .WR1_FULL                          (                          ),
    .WR1_USE                           (                          ),

    .WR2_DATA                          (show_data   /* isp_data_out */          ),
    .WR2                               (post_en    /* isp_wr_en */          ),
    .WR2_ADDR                          (0                         ),
    .WR2_MAX_ADDR                      (H_PIXEL*V_PIXEL           ),
    .WR2_LENGTH                        (10'd256                   ),
    .WR2_LOAD                          (~rst_n                    ),
    .WR2_CLK                           (cam_pclk                  ),
    .WR2_FULL                          (                          ),
    .WR2_USE                           (                          ),

    .RD1_DATA                          (last_pic                  ),
    .RD1                               (ycbcr_wr_en               ),
    .RD1_ADDR                          (H_PIXEL*V_PIXEL           ),
    .RD1_MAX_ADDR                      (H_PIXEL*V_PIXEL*2         ),
    .RD1_LENGTH                        (10'd256                   ),
    .RD1_LOAD                          (~rst_n                    ),
    .RD1_CLK                           (cam_pclk                  ),
    .RD1_EMPTY                         (                          ),
    .RD1_USE                           (                          ),

    .RD2_DATA                          (vga_rgb                   ),
    .RD2                               (data_req                  ),
    .RD2_ADDR                          (0                         ),
    .RD2_MAX_ADDR                      (H_PIXEL*V_PIXEL           ),
    .RD2_LENGTH                        (10'd256                   ),
    .RD2_LOAD                          (~rst_n                    ),
    .RD2_CLK                           (vga_clk                   ),
    .RD2_EMPTY                         (                          ),
    .RD2_USE                           (                          ) 
);
image_process 
#(
    .DIFF_THR                          (DIFF_THR                  ) 
)
image_process (
    .sys_clk                           (cam_pclk                  ),
    .rst_n                             (rst_n                     ),
    .pre_wr_en                         (ov5640_wr_en              ),
    .isp_data_in                       (ov5640_data_out           ),
    .last_pic                          (last_pic                  ),
    .pre_vsync                         (ov5640_vsync_out          ),
    .pre_href                          (ov5640_href_out           ),

    .isp_vsync                         (isp_vsync                 ),
    .isp_href                          (isp_href                  ),
    .img_Y                             (img_Y                     ),
    .median_wr_En					(median_wr_En	),
    
    .isp_1bit_out                      (isp_1bit_out              ),
    .isp_wr_en                         (isp_wr_en                 ),
    .isp_data_out                      (isp_data_out              ),
    .ycbcr_wr_en                       (ycbcr_wr_en               ),
    .img_Y_r							(img_Y_r)					,
    .erosion_rgb565						(erosion_rgb565) ,
    .erosion_wr_en2						(erosion_wr_en2),
    .dilation_data						(dilation_data),
    .dilation_wr_en						(dilation_wr_en),
    .post_sobel					(post_sobel),
    .post3_frame_clken				(post3_frame_clken),
    .post_img_b                     (post_img_b),
    .post_b_clken                   (post_b_clken)
); 
     wire        [   7:0]         img_Y                      ;//中值
     wire                         median_wr_En; //原始使能

     wire        [   7:0]         img_Y_r                      ;//原始数据
     wire                         ycbcr_wr_en; //原始使能
     wire        [  15:0]         erosion_rgb565               ;//腐蚀
     wire							erosion_wr_en2;
     wire        [  15:0]         dilation_data               ;//膨胀
     wire                                    dilation_wr_en             ;
     wire        [  15:0]         post_img_b               ;//膨胀
     wire                                    post_b_clken;
     wire        [  15:0]			post_sobel;//边缘检测
     wire							post3_frame_clken;
wire	[15:0]	show_data;
wire post_en;
image_select u_image_select
(
    .clk(cam_pclk),
    .rst_n(sys_rst_n),
    .mode(mode),
    .binary_img(post_img_b),
    .binary_img_en(post_b_clken),
    .original_image(ov5640_data_out),
    .ov5640_wr_en(ov5640_wr_en),
    .fusion_rgb565(fusion_rgb565),
    .fusion_wr_en(fusion_wr_en),
    .img_Y(img_Y),
    .median_wr_En(median_wr_En),
    .img_Y_r(img_Y_r),
    .ycbcr_wr_en(ycbcr_wr_en),
    .erosion_rgb565(erosion_rgb565),
    .erosion_wr_en2(erosion_wr_en2),
    .dilation_data(dilation_data),
    .dilation_wr_en(dilation_wr_en),
    .post_sobel(post_sobel),
    .post3_frame_clken(post3_frame_clken),
    .show_data(show_data),
    .post_en(post_en)


);
cam_syn u_cam_syn(
    .sys_clk                           (cam_pclk                  ),
    .sys_rst_n                         (rst_n                     ),
    .pre_wr_en                         (ov5640_wr_en              ),
    .pre_vs                            (ov5640_vsync_out          ),
    .pre_hs                            (ov5640_href_out           ),
    .cam_data                          (ov5640_data_out           ),
    .syn_wr_en                         (syn_wr_en                 ),
    .syn_hs                            (syn_hs                    ),
    .syn_vs                            (syn_vs                    ),
    .syn_data                          (syn_data                  ) 
);

mul_obj_check
#(
    .H_PIXEL                           (H_PIXEL                   ),
    .V_PIXEL                           (V_PIXEL                   ),
    .MIN_DISC                          (MIN_DISC                  ) 
)
u_mul_obj_check(
    .sys_clk                           (cam_pclk                  ),
    .sys_rst_n                         (rst_n                     ),
    .pre_hs                            (isp_href                  ),
    .pre_vs                            (isp_vsync                 ),
    .pre_wr_en                         (isp_wr_en                 ),
    .pre_1bit                          (isp_1bit_out              ),

    .mul_hs                            (mul_hs                    ),
    .mul_vs                            (mul_vs                    ),
    .mul_wr_en                         (mul_wr_en                 ),
    .pos_data_out                      (pos_data                  ) 
);

boundary_fusion
#(
    .H_PIXEL                           (H_PIXEL                   ),
    .V_PIXEL                           (V_PIXEL                   ) 
)
u_boundary_fusion(
    .sys_clk                           (cam_pclk                  ),
    .sys_rst_n                         (rst_n                     ),
    .pre_wr_en                         (mul_wr_en                 ),
    .pre_hs                            (mul_hs                    ),
    .pre_vs                            (mul_vs                    ),
    .pos_data                          (pos_data                  ),
    .cam_data                          (syn_data                  ),

    .fusion_rgb565                     (fusion_rgb565             ),
    .fusion_rgb888                     (fusion_rgb888             ),
    .fusion_hs                         (fusion_hs                 ),
    .fusion_vs                         (fusion_vs                 ),
    .fusion_wr_en                      (fusion_wr_en              ),
    .fusion_r                          (                          ),
    .fusion_g                          (                          ),
    .fusion_b                          (                          ),
    .obj_num                           (obj_num                   ) 
);
vga_ctrl u_vga_ctrl(
    .vga_clk                           (vga_clk                   ),
    .sys_rst_n                         (rst_n                     ),
    .pix_data                          (vga_rgb                   ),
    .data_req                          (data_req                  ),
    .vga_hs                            (vga_hs                    ),
    .vga_vs                            (vga_vs                    ),
    .rgb_888                           (vga_rgb888                ) 
);


seg_4 u_seg4(
    .clk_24m                           (cam_pclk                  ),
    .rst_n                             (rst_n                     ),
    .sm_seg_num                        (obj_num                   ),
    .sm_seg                            (seg_data                  ),
    .sm_bit                            (sel                       ) 
);
rgb_led u_rgb_led(
    .clk_24m                           (clk_50m                   ),
    .led_r                             (led_r                     ),
    .led_g                             (led_g                     ),
    .led_b                             (led_b                     ) 
);
running_led u_running_led(
    .clk_24m                           (clk_50m                   ),
    .rst_n                             (rst_n                     ),
    .led                               (led                       ) 
);

endmodule                                                           //ov5640_mov_detect