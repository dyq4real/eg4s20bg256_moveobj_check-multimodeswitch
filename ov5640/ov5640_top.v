module ov5640_top (
    input  wire                         sys_rst_n                  ,
    input  wire                         sys_clk                    ,
    input  wire                         ov5640_pclk                ,
    input  wire                         ov5640_href                ,
    input  wire        [   7:0]         ov5640_data                ,
    input  wire                         sys_init_done              ,//sdram & ov5640 init end
    input  wire                         ov5640_vsync               ,

    output wire                         ov5640_wr_en               ,
    output wire        [  15:0]         ov5640_data_out            ,
    output wire                         cfg_done                  ,
    output wire cam_hs,
    output wire cam_vs,
    output wire                         sccb_scl                   ,
    inout  wire                         sccb_sda                    
);
    parameter                           OV5640_ADDR = 7'H3C        ;
    parameter                           CLK_FREQ   = 26'd50_000_000;// i2c_dri模块的驱动时钟频率(CLK_FREQ)
    parameter                           I2C_FREQ   = 18'd250_000   ;// I2C的SCL时钟频率
    parameter                           BIT_CTRL   = 1'B1          ;
wire                                    cfg_end                    ;
wire                                    cfg_start                  ;
wire                   [  23:0]         cfg_data                   ;
wire                                    cfg_clk                    ;
i2c_ctrl
   #(
    .SLAVE_ADDR                        (OV5640_ADDR               ),//参数传递
    .CLK_FREQ                          (CLK_FREQ                  ),
    .I2C_FREQ                          (I2C_FREQ                  ) 
    )
u_i2c_ctrl(
    .clk                               (sys_clk                   ),
    .rst_n                             (sys_rst_n                 ),
        
    .i2c_exec                          (cfg_start                 ),
    .bit_ctrl                          (BIT_CTRL                  ),
    .i2c_rh_wl                         (1'b0                      ),//固定为0，只用到了IIC驱动的写操作   
    .i2c_addr                          (cfg_data[23:8]            ),
    .i2c_data_w                        (cfg_data[7:0]             ),
    
    
    .i2c_data_r                        (                          ),
    .i2c_done                          (cfg_end                   ),
    .scl                               (sccb_scl                  ),
    .sda                               (sccb_sda                  ),
        
    .dri_clk                           (cfg_clk                   ) //I2C操作时钟
);


ov5640_cfg u_ov5640_cfg(
    .sys_clk                           (cfg_clk                   ),
    .cfg_end                           (cfg_end                   ),
    .sys_rst_n                         (sys_rst_n                 ),
    .cfg_done                          (cfg_done                  ),
    .cfg_start                         (cfg_start                 ),
    .cfg_data                          (cfg_data                  ) 
);
ov5640_data u_ov5640_data(
    .ov5640_pclk                       (ov5640_pclk               ),
    .sys_rst_n                         (sys_rst_n & sys_init_done ),
    .ov5640_href                       (ov5640_href               ),
    .ov5640_vsync                      (ov5640_vsync              ),
    .ov5640_data                       (ov5640_data               ),
    .ov5640_wr_en                      (ov5640_wr_en              ),
    .cam_hs(cam_hs),
    .cam_vs(cam_vs),
    .ov5640_data_out                   (ov5640_data_out           ) 
);



endmodule                                                           //ov5640_top