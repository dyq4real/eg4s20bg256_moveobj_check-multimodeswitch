module ov5640_cfg
  #(
    parameter CMOS_H_PIXEL = 24'd800,//CMOS水平方向像素个数
    parameter CMOS_V_PIXEL = 24'd600  //CMOS垂直方向像素个数
    )
   (  
    input                sys_clk      ,   //时钟信号
    input                sys_rst_n    ,   //复位信号，低电平有效
    
    input                cfg_end ,   //I2C寄存器配置完成信号
    output  reg          cfg_start ,   //I2C触发执行信号   
    output  reg  [23:0]  cfg_data ,   //I2C要配置的地址与数据(高16位地址,低8位数据)
    output  reg          cfg_done    //初始化完成信号
    );

//parameter define
localparam  REG_NUM = 8'd248  ;       //总共需要配置的寄存器个数
localparam  TOTAL_H_PIXEL = CMOS_H_PIXEL + 13'd1216;  //水平总像素大小
localparam  TOTAL_V_PIXEL = CMOS_V_PIXEL + 13'd504;   //垂直总像素大小
localparam WAIT_MAX = 'D50_000;
//reg define
reg   [14:0]   start_init_cnt;        //等待延时计数器
reg    [7:0]   init_reg_cnt  ;        //寄存器配置个数计数器
reg [19:0] cnt_1ms;
reg flag_1ms;
//*设计复位逻辑
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	cnt_1ms <= 20'd0;
        flag_1ms <= 1'b0;
    end
    else if (cnt_1ms == WAIT_MAX - 1) begin
        flag_1ms <= 1'b1;
        cnt_1ms  <= 20'd0;
    end
    else begin
        flag_1ms <= 1'b0;
        cnt_1ms <= cnt_1ms + 1'b1;
    end
end
//cam_scl配置成250khz,输入的clk为1Mhz,周期为1us,20000*1us = 20ms
//OV5640上电到开始配置IIC至少等待20ms
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        start_init_cnt <= 15'd0;
    else if(start_init_cnt < 15'd20000)
        start_init_cnt <= start_init_cnt + 1'b1;                    
end

//寄存器配置个数计数    
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        init_reg_cnt <= 8'd0;
    else if (init_reg_cnt == 8'd0 && (!flag_1ms)) begin
        init_reg_cnt <= init_reg_cnt;
    end
    else if(cfg_start)   
        init_reg_cnt <= init_reg_cnt + 8'b1;
end

//i2c触发执行信号   
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cfg_start <= 1'b0;
    else if(start_init_cnt == 15'd19999)
        cfg_start <= 1'b1;
    else if(cfg_end && (init_reg_cnt < REG_NUM))
        cfg_start <= 1'b1;
    else
        cfg_start <= 1'b0;
end 

//初始化完成信号
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cfg_done <= 1'b0;
    else if((init_reg_cnt == REG_NUM) && cfg_end)  
        cfg_done <= 1'b1;  
end

//配置寄存器地址与数据
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cfg_data <= 24'd0;
    else begin
        case(init_reg_cnt)
            //先对寄存器进行软件复位，使寄存器恢复初始值
            8'd0  : cfg_data <= {16'h3008,8'h82}; //Bit[7]:复位 Bit[6]:电源休眠
            8'd1  : cfg_data <= {16'h3008,8'h02}; //正常工作模式
            8'd2  : cfg_data <= {16'h3103,8'h02}; //Bit[1]:1 PLL Clock//?
            //引脚输入/输出控制 FREX/VSYNC/HREF/PCLK/D[9:6]
            8'd3  : cfg_data <= {16'h3017,8'hff};
            //引脚输入/输出控制 D[5:0]/GPIO1/GPIO0 
            8'd4  : cfg_data <= {16'h3018,8'hff};
            8'd5  : cfg_data <= {16'h3037,8'h13}; //PLL分频控制
            8'd6  : cfg_data <= {16'h3108,8'h01}; //系统根分频器
            8'd7  : cfg_data <= {16'h3630,8'h36};
            8'd8  : cfg_data <= {16'h3631,8'h0e};
            8'd9  : cfg_data <= {16'h3632,8'he2};
            8'd10 : cfg_data <= {16'h3633,8'h12};
            8'd11 : cfg_data <= {16'h3621,8'he0};
            8'd12 : cfg_data <= {16'h3704,8'ha0};
            8'd13 : cfg_data <= {16'h3703,8'h5a};
            8'd14 : cfg_data <= {16'h3715,8'h78};
            8'd15 : cfg_data <= {16'h3717,8'h01};
            8'd16 : cfg_data <= {16'h370b,8'h60};
            8'd17 : cfg_data <= {16'h3705,8'h1a};
            8'd18 : cfg_data <= {16'h3905,8'h02};
            8'd19 : cfg_data <= {16'h3906,8'h10};
            8'd20 : cfg_data <= {16'h3901,8'h0a};
            8'd21 : cfg_data <= {16'h3731,8'h12};
            8'd22 : cfg_data <= {16'h3600,8'h08}; //VCM控制,用于自动聚焦
            8'd23 : cfg_data <= {16'h3601,8'h33}; //VCM控制,用于自动聚焦
            8'd24 : cfg_data <= {16'h302d,8'h60}; //系统控制
            8'd25 : cfg_data <= {16'h3620,8'h52};
            8'd26 : cfg_data <= {16'h371b,8'h20};
            8'd27 : cfg_data <= {16'h471c,8'h50};
            8'd28 : cfg_data <= {16'h3a13,8'h43}; //AEC(自动曝光控制)
            8'd29 : cfg_data <= {16'h3a18,8'h00}; //AEC 增益上限
            8'd30 : cfg_data <= {16'h3a19,8'hf8}; //AEC 增益上限
            8'd31 : cfg_data <= {16'h3635,8'h13};
            8'd32 : cfg_data <= {16'h3636,8'h03};
            8'd33 : cfg_data <= {16'h3634,8'h40};
            8'd34 : cfg_data <= {16'h3622,8'h01};
            8'd35 : cfg_data <= {16'h3c01,8'h34};
            8'd36 : cfg_data <= {16'h3c04,8'h28};
            8'd37 : cfg_data <= {16'h3c05,8'h98};
            8'd38 : cfg_data <= {16'h3c06,8'h00}; //light meter 1 阈值[15:8]
            8'd39 : cfg_data <= {16'h3c07,8'h08}; //light meter 1 阈值[7:0]
            8'd40 : cfg_data <= {16'h3c08,8'h00}; //light meter 2 阈值[15:8]
            8'd41 : cfg_data <= {16'h3c09,8'h1c}; //light meter 2 阈值[7:0]
            8'd42 : cfg_data <= {16'h3c0a,8'h9c}; //sample number[15:8]
            8'd43 : cfg_data <= {16'h3c0b,8'h40}; //sample number[7:0]
            8'd44 : cfg_data <= {16'h3810,8'h00}; //Timing Hoffset[11:8]
            8'd45 : cfg_data <= {16'h3811,8'h10}; //Timing Hoffset[7:0]
            8'd46 : cfg_data <= {16'h3812,8'h00}; //Timing Voffset[10:8]
            8'd47 : cfg_data <= {16'h3708,8'h64};
            8'd48 : cfg_data <= {16'h4001,8'h02}; //BLC(黑电平校准)补偿起始行号
            8'd49 : cfg_data <= {16'h4005,8'h1a}; //BLC(黑电平校准)补偿始终更新
            8'd50 : cfg_data <= {16'h3000,8'h00}; //系统块复位控制
            8'd51 : cfg_data <= {16'h3004,8'hff}; //时钟使能控制
            8'd52 : cfg_data <= {16'h4300,8'h61}; //格式控制 RGB565
            8'd53 : cfg_data <= {16'h501f,8'h01}; //ISP RGB
            8'd54 : cfg_data <= {16'h440e,8'h00};
            8'd55 : cfg_data <= {16'h5000,8'ha7}; //ISP控制
            8'd56 : cfg_data <= {16'h3a0f,8'h30}; //AEC控制;stable range in high
            8'd57 : cfg_data <= {16'h3a10,8'h28}; //AEC控制;stable range in low
            8'd58 : cfg_data <= {16'h3a1b,8'h30}; //AEC控制;stable range out high
            8'd59 : cfg_data <= {16'h3a1e,8'h26}; //AEC控制;stable range out low
            8'd60 : cfg_data <= {16'h3a11,8'h60}; //AEC控制; fast zone high
            8'd61 : cfg_data <= {16'h3a1f,8'h14}; //AEC控制; fast zone low
            //LENC(镜头校正)控制 16'h5800~16'h583d
            8'd62 : cfg_data <= {16'h5800,8'h23}; 
            8'd63 : cfg_data <= {16'h5801,8'h14};
            8'd64 : cfg_data <= {16'h5802,8'h0f};
            8'd65 : cfg_data <= {16'h5803,8'h0f};
            8'd66 : cfg_data <= {16'h5804,8'h12};
            8'd67 : cfg_data <= {16'h5805,8'h26};
            8'd68 : cfg_data <= {16'h5806,8'h0c};
            8'd69 : cfg_data <= {16'h5807,8'h08};
            8'd70 : cfg_data <= {16'h5808,8'h05};
            8'd71 : cfg_data <= {16'h5809,8'h05};
            8'd72 : cfg_data <= {16'h580a,8'h08};
            8'd73 : cfg_data <= {16'h580b,8'h0d};
            8'd74 : cfg_data <= {16'h580c,8'h08};
            8'd75 : cfg_data <= {16'h580d,8'h03};
            8'd76 : cfg_data <= {16'h580e,8'h00};
            8'd77 : cfg_data <= {16'h580f,8'h00};
            8'd78 : cfg_data <= {16'h5810,8'h03};
            8'd79 : cfg_data <= {16'h5811,8'h09};
            8'd80 : cfg_data <= {16'h5812,8'h07};
            8'd81 : cfg_data <= {16'h5813,8'h03};
            8'd82 : cfg_data <= {16'h5814,8'h00};
            8'd83 : cfg_data <= {16'h5815,8'h01};
            8'd84 : cfg_data <= {16'h5816,8'h03};
            8'd85 : cfg_data <= {16'h5817,8'h08};
            8'd86 : cfg_data <= {16'h5818,8'h0d};
            8'd87 : cfg_data <= {16'h5819,8'h08};
            8'd88 : cfg_data <= {16'h581a,8'h05};
            8'd89 : cfg_data <= {16'h581b,8'h06};
            8'd90 : cfg_data <= {16'h581c,8'h08};
            8'd91 : cfg_data <= {16'h581d,8'h0e};
            8'd92 : cfg_data <= {16'h581e,8'h29};
            8'd93 : cfg_data <= {16'h581f,8'h17};
            8'd94 : cfg_data <= {16'h5820,8'h11};
            8'd95 : cfg_data <= {16'h5821,8'h11};
            8'd96 : cfg_data <= {16'h5822,8'h15};
            8'd97 : cfg_data <= {16'h5823,8'h28};
            8'd98 : cfg_data <= {16'h5824,8'h46};
            8'd99 : cfg_data <= {16'h5825,8'h26};
            8'd100: cfg_data <= {16'h5826,8'h08};
            8'd101: cfg_data <= {16'h5827,8'h26};
            8'd102: cfg_data <= {16'h5828,8'h64};
            8'd103: cfg_data <= {16'h5829,8'h26};
            8'd104: cfg_data <= {16'h582a,8'h24};
            8'd105: cfg_data <= {16'h582b,8'h22};
            8'd106: cfg_data <= {16'h582c,8'h24};
            8'd107: cfg_data <= {16'h582d,8'h24};
            8'd108: cfg_data <= {16'h582e,8'h06};
            8'd109: cfg_data <= {16'h582f,8'h22};
            8'd110: cfg_data <= {16'h5830,8'h40};
            8'd111: cfg_data <= {16'h5831,8'h42};
            8'd112: cfg_data <= {16'h5832,8'h24};
            8'd113: cfg_data <= {16'h5833,8'h26};
            8'd114: cfg_data <= {16'h5834,8'h24};
            8'd115: cfg_data <= {16'h5835,8'h22};
            8'd116: cfg_data <= {16'h5836,8'h22};
            8'd117: cfg_data <= {16'h5837,8'h26};
            8'd118: cfg_data <= {16'h5838,8'h44};
            8'd119: cfg_data <= {16'h5839,8'h24};
            8'd120: cfg_data <= {16'h583a,8'h26};
            8'd121: cfg_data <= {16'h583b,8'h28};
            8'd122: cfg_data <= {16'h583c,8'h42};
            8'd123: cfg_data <= {16'h583d,8'hce};
            //AWB(自动白平衡控制) 16'h5180~16'h519e
            8'd124: cfg_data <= {16'h5180,8'hff};
            8'd125: cfg_data <= {16'h5181,8'hf2};
            8'd126: cfg_data <= {16'h5182,8'h00};
            8'd127: cfg_data <= {16'h5183,8'h14};
            8'd128: cfg_data <= {16'h5184,8'h25};
            8'd129: cfg_data <= {16'h5185,8'h24};
            8'd130: cfg_data <= {16'h5186,8'h09};
            8'd131: cfg_data <= {16'h5187,8'h09};
            8'd132: cfg_data <= {16'h5188,8'h09};
            8'd133: cfg_data <= {16'h5189,8'h75};
            8'd134: cfg_data <= {16'h518a,8'h54};
            8'd135: cfg_data <= {16'h518b,8'he0};
            8'd136: cfg_data <= {16'h518c,8'hb2};
            8'd137: cfg_data <= {16'h518d,8'h42};
            8'd138: cfg_data <= {16'h518e,8'h3d};
            8'd139: cfg_data <= {16'h518f,8'h56};
            8'd140: cfg_data <= {16'h5190,8'h46};
            8'd141: cfg_data <= {16'h5191,8'hf8};
            8'd142: cfg_data <= {16'h5192,8'h04};
            8'd143: cfg_data <= {16'h5193,8'h70};
            8'd144: cfg_data <= {16'h5194,8'hf0};
            8'd145: cfg_data <= {16'h5195,8'hf0};
            8'd146: cfg_data <= {16'h5196,8'h03};
            8'd147: cfg_data <= {16'h5197,8'h01};
            8'd148: cfg_data <= {16'h5198,8'h04};
            8'd149: cfg_data <= {16'h5199,8'h12};
            8'd150: cfg_data <= {16'h519a,8'h04};
            8'd151: cfg_data <= {16'h519b,8'h00};
            8'd152: cfg_data <= {16'h519c,8'h06};
            8'd153: cfg_data <= {16'h519d,8'h82};
            8'd154: cfg_data <= {16'h519e,8'h38};
            //Gamma(伽马)控制 16'h5480~16'h5490
            8'd155: cfg_data <= {16'h5480,8'h01}; 
            8'd156: cfg_data <= {16'h5481,8'h08};
            8'd157: cfg_data <= {16'h5482,8'h14};
            8'd158: cfg_data <= {16'h5483,8'h28};
            8'd159: cfg_data <= {16'h5484,8'h51};
            8'd160: cfg_data <= {16'h5485,8'h65};
            8'd161: cfg_data <= {16'h5486,8'h71};
            8'd162: cfg_data <= {16'h5487,8'h7d};
            8'd163: cfg_data <= {16'h5488,8'h87};
            8'd164: cfg_data <= {16'h5489,8'h91};
            8'd165: cfg_data <= {16'h548a,8'h9a};
            8'd166: cfg_data <= {16'h548b,8'haa};
            8'd167: cfg_data <= {16'h548c,8'hb8};
            8'd168: cfg_data <= {16'h548d,8'hcd};
            8'd169: cfg_data <= {16'h548e,8'hdd};
            8'd170: cfg_data <= {16'h548f,8'hea};
            8'd171: cfg_data <= {16'h5490,8'h1d};
            //CMX(彩色矩阵控制) 16'h5381~16'h538b
            8'd172: cfg_data <= {16'h5381,8'h1e};
            8'd173: cfg_data <= {16'h5382,8'h5b};
            8'd174: cfg_data <= {16'h5383,8'h08};
            8'd175: cfg_data <= {16'h5384,8'h0a};
            8'd176: cfg_data <= {16'h5385,8'h7e};
            8'd177: cfg_data <= {16'h5386,8'h88};
            8'd178: cfg_data <= {16'h5387,8'h7c};
            8'd179: cfg_data <= {16'h5388,8'h6c};
            8'd180: cfg_data <= {16'h5389,8'h10};
            8'd181: cfg_data <= {16'h538a,8'h01};
            8'd182: cfg_data <= {16'h538b,8'h98};
            //SDE(特殊数码效果)控制 16'h5580~16'h558b
            8'd183: cfg_data <= {16'h5580,8'h06};
            8'd184: cfg_data <= {16'h5583,8'h40};
            8'd185: cfg_data <= {16'h5584,8'h10};
            8'd186: cfg_data <= {16'h5589,8'h10};
            8'd187: cfg_data <= {16'h558a,8'h00};
            8'd188: cfg_data <= {16'h558b,8'hf8};
            8'd189: cfg_data <= {16'h501d,8'h40}; //ISP MISC
            //CIP(颜色插值)控制 (16'h5300~16'h530c)
            8'd190: cfg_data <= {16'h5300,8'h08};
            8'd191: cfg_data <= {16'h5301,8'h30};
            8'd192: cfg_data <= {16'h5302,8'h10};
            8'd193: cfg_data <= {16'h5303,8'h00};
            8'd194: cfg_data <= {16'h5304,8'h08};
            8'd195: cfg_data <= {16'h5305,8'h30};
            8'd196: cfg_data <= {16'h5306,8'h08};
            8'd197: cfg_data <= {16'h5307,8'h16};
            8'd198: cfg_data <= {16'h5309,8'h08};
            8'd199: cfg_data <= {16'h530a,8'h30};
            8'd200: cfg_data <= {16'h530b,8'h04};
            8'd201: cfg_data <= {16'h530c,8'h06};
            8'd202: cfg_data <= {16'h5025,8'h00};
            //系统时钟分频 Bit[7:4]:系统时钟分频 input clock =24Mhz, PCLK = 48Mhz
            8'd203: cfg_data <= {16'h3035,8'h11}; 
            8'd204: cfg_data <= {16'h3036,8'h3c}; //PLL倍频
            8'd205: cfg_data <= {16'h3c07,8'h08};
            //时序控制 16'h3800~16'h3821
            8'd206: cfg_data <= {16'h3820,8'h46};
            8'd207: cfg_data <= {16'h3821,8'h01};
            8'd208: cfg_data <= {16'h3814,8'h31};
            8'd209: cfg_data <= {16'h3815,8'h31};
            8'd210: cfg_data <= {16'h3800,8'h00};
            8'd211: cfg_data <= {16'h3801,8'h00};
            8'd212: cfg_data <= {16'h3802,8'h00};
            8'd213: cfg_data <= {16'h3803,8'h04};
            8'd214: cfg_data <= {16'h3804,8'h0a};
            8'd215: cfg_data <= {16'h3805,8'h3f};
            8'd216: cfg_data <= {16'h3806,8'h07};
            8'd217: cfg_data <= {16'h3807,8'h9b};

            //设置输出像素个数
            //DVP 输出水平像素点数高4位
            8'd218: cfg_data <= {16'h3808,{4'd0,CMOS_H_PIXEL[11:8]}};
            //DVP 输出水平像素点数低8位
            8'd219: cfg_data <= {16'h3809,CMOS_H_PIXEL[7:0]};
            //DVP 输出垂直像素点数高3位
            8'd220: cfg_data <= {16'h380a,{5'd0,CMOS_V_PIXEL[10:8]}};
            //DVP 输出垂直像素点数低8位
            8'd221: cfg_data <= {16'h380b,CMOS_V_PIXEL[7:0]};
            //水平总像素大小高5位
            8'd222: cfg_data <= {16'h380c,{3'd0,TOTAL_H_PIXEL[12:8]}};
            //水平总像素大小低8位 
            8'd223: cfg_data <= {16'h380d,TOTAL_H_PIXEL[7:0]};
            //垂直总像素大小高5位 
            8'd224: cfg_data <= {16'h380e,{3'd0,TOTAL_V_PIXEL[12:8]}};
            //垂直总像素大小低8位     
            8'd225: cfg_data <= {16'h380f,TOTAL_V_PIXEL[7:0]};

            8'd226: cfg_data <= {16'h3813,8'h06};
            8'd227: cfg_data <= {16'h3618,8'h00};
            8'd228: cfg_data <= {16'h3612,8'h29};
            8'd229: cfg_data <= {16'h3709,8'h52};
            8'd230: cfg_data <= {16'h370c,8'h03};
            8'd231: cfg_data <= {16'h3a02,8'h17}; //60Hz max exposure
            8'd232: cfg_data <= {16'h3a03,8'h10}; //60Hz max exposure
            8'd233: cfg_data <= {16'h3a14,8'h17}; //50Hz max exposure
            8'd234: cfg_data <= {16'h3a15,8'h10}; //50Hz max exposure
            8'd235: cfg_data <= {16'h4004,8'h02}; //BLC(背光) 2 lines
            8'd236: cfg_data <= {16'h4713,8'h03}; //JPEG mode 3
            8'd237: cfg_data <= {16'h4407,8'h04}; //量化标度
            8'd238: cfg_data <= {16'h460c,8'h22};     
            8'd239: cfg_data <= {16'h4837,8'h22}; //DVP CLK divider
            8'd240: cfg_data <= {16'h3824,8'h02}; //DVP CLK divider
            8'd241: cfg_data <= {16'h5001,8'ha3}; //ISP 控制
            8'd242: cfg_data <= {16'h3b07,8'h0a}; //帧曝光模式  
            //彩条测试使能 
            8'd243: cfg_data <= {16'h503d,8'h00}; //8'h00:正常模式 8'h80:彩条显示
            //测试闪光灯功能
            8'd244: cfg_data <= {16'h3016,8'h02};
            8'd245: cfg_data <= {16'h301c,8'h02};
            8'd246: cfg_data <= {16'h3019,8'h02}; //打开闪光灯
            8'd247: cfg_data <= {16'h3019,8'h00}; //关闭闪光灯
            //只读存储器,防止在case中没有列举的情况，之前的寄存器被重复改写
            default : cfg_data <= {16'h300a,8'h00}; //器件ID高8位
        endcase
    end
end

endmodule

/* 

module  ov5640_cfg
(
    input   wire            sys_clk     ,   //系统时钟,由iic模块传入
    input   wire            sys_rst_n   ,   //系统复位,低有效
    input   wire            cfg_end     ,   //单个寄存器配置完成

    output  reg             cfg_start   ,   //单个寄存器配置触发信号
    output  wire    [23:0]  cfg_data    ,   //ID,REG_ADDR,REG_VAL
    output  reg             cfg_done        //寄存器配置完成
);


//parameter define
parameter   REG_NUM         =   8'd251      ;   //总共需要配置的寄存器个数
parameter   CNT_WAIT_MAX    =   15'd20000   ;   //寄存器配置等待计数最大值

//wire  define
wire    [23:0]  cfg_data_reg[REG_NUM-1:0]   ;   //寄存器配置数据暂存

//reg   define
reg     [14:0]  cnt_wait    ;   //寄存器配置等待计数器
reg     [7:0]   reg_num     ;   //配置寄存器个数



//cnt_wait:寄存器配置等待计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_wait    <=  15'd0;
    else    if(cnt_wait < CNT_WAIT_MAX)
        cnt_wait    <=  cnt_wait + 1'b1;

//reg_num:配置寄存器个数
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        reg_num <=  8'd0;
    else    if(cfg_end == 1'b1)
        reg_num <=  reg_num + 1'b1;

//cfg_start:单个寄存器配置触发信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cfg_start   <=  1'b0;
    else    if(cnt_wait == (CNT_WAIT_MAX - 1'b1))
        cfg_start   <=  1'b1;
    else    if((cfg_end == 1'b1) && (reg_num < REG_NUM))
        cfg_start   <=  1'b1;
    else
        cfg_start   <=  1'b0;

//cfg_done:寄存器配置完成
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cfg_done    <=  1'b0;
    else    if((reg_num == REG_NUM) && (cfg_end == 1'b1))
        cfg_done    <=  1'b1;

//cfg_data:ID,REG_ADDR,REG_VAL
assign  cfg_data = (cfg_done == 1'b1) ? 24'b0 : cfg_data_reg[reg_num];

//----------------------------------------------------
//cfg_data_reg：寄存器配置数据暂存  ID   REG_ADDR REG_VAL
assign  cfg_data_reg[000]  =       {16'h3103, 8'h11};
assign  cfg_data_reg[001]  =       {16'h3008, 8'h82};
assign  cfg_data_reg[002]  =       {16'h3008, 8'h42};
assign  cfg_data_reg[003]  =       {16'h3103, 8'h03};
assign  cfg_data_reg[004]  =       {16'h3017, 8'hff};
assign  cfg_data_reg[005]  =       {16'h3018, 8'hff};
assign  cfg_data_reg[006]  =       {16'h3034, 8'h1A};
assign  cfg_data_reg[007]  =       {16'h3037, 8'h13};
assign  cfg_data_reg[008]  =       {16'h3108, 8'h01};
assign  cfg_data_reg[009]  =       {16'h3630, 8'h36};

assign  cfg_data_reg[010]  =       {16'h3631, 8'h0e};
assign  cfg_data_reg[011]  =       {16'h3632, 8'he2};
assign  cfg_data_reg[012]  =       {16'h3633, 8'h12};
assign  cfg_data_reg[013]  =       {16'h3621, 8'he0};
assign  cfg_data_reg[014]  =       {16'h3704, 8'ha0};
assign  cfg_data_reg[015]  =       {16'h3703, 8'h5a};
assign  cfg_data_reg[016]  =       {16'h3715, 8'h78};
assign  cfg_data_reg[017]  =       {16'h3717, 8'h01};
assign  cfg_data_reg[018]  =       {16'h370b, 8'h60};
assign  cfg_data_reg[019]  =       {16'h3705, 8'h1a};

assign  cfg_data_reg[020]  =       {16'h3905, 8'h02};
assign  cfg_data_reg[021]  =       {16'h3906, 8'h10};
assign  cfg_data_reg[022]  =       {16'h3901, 8'h0a};
assign  cfg_data_reg[023]  =       {16'h3731, 8'h12};
assign  cfg_data_reg[024]  =       {16'h3600, 8'h08};
assign  cfg_data_reg[025]  =       {16'h3601, 8'h33};
assign  cfg_data_reg[026]  =       {16'h302d, 8'h60};
assign  cfg_data_reg[027]  =       {16'h3620, 8'h52};
assign  cfg_data_reg[028]  =       {16'h371b, 8'h20};
assign  cfg_data_reg[029]  =       {16'h471c, 8'h50};

assign  cfg_data_reg[030]  =       {16'h3a13, 8'h43};
assign  cfg_data_reg[031]  =       {16'h3a18, 8'h00};
assign  cfg_data_reg[032]  =       {16'h3a19, 8'hf8};
assign  cfg_data_reg[033]  =       {16'h3635, 8'h13};
assign  cfg_data_reg[034]  =       {16'h3636, 8'h03};
assign  cfg_data_reg[035]  =       {16'h3634, 8'h40};
assign  cfg_data_reg[036]  =       {16'h3622, 8'h01};
assign  cfg_data_reg[037]  =       {16'h3c01, 8'h34};
assign  cfg_data_reg[038]  =       {16'h3c04, 8'h28};
assign  cfg_data_reg[039]  =       {16'h3c05, 8'h98};

assign  cfg_data_reg[040]  =       {16'h3c06, 8'h00};
assign  cfg_data_reg[041]  =       {16'h3c07, 8'h08};
assign  cfg_data_reg[042]  =       {16'h3c08, 8'h00};
assign  cfg_data_reg[043]  =       {16'h3c09, 8'h1c};
assign  cfg_data_reg[044]  =       {16'h3c0a, 8'h9c};
assign  cfg_data_reg[045]  =       {16'h3c0b, 8'h40};
assign  cfg_data_reg[046]  =       {16'h3810, 8'h00};
assign  cfg_data_reg[047]  =       {16'h3811, 8'h10};
assign  cfg_data_reg[048]  =       {16'h3812, 8'h00};
assign  cfg_data_reg[049]  =       {16'h3708, 8'h64};

assign  cfg_data_reg[050]  =       {16'h4001, 8'h02};
assign  cfg_data_reg[051]  =       {16'h4005, 8'h1a};
assign  cfg_data_reg[052]  =       {16'h3000, 8'h00};
assign  cfg_data_reg[053]  =       {16'h3004, 8'hff};
assign  cfg_data_reg[054]  =       {16'h300e, 8'h58};
assign  cfg_data_reg[055]  =       {16'h302e, 8'h00};
assign  cfg_data_reg[056]  =       {16'h4300, 8'h61};
assign  cfg_data_reg[057]  =       {16'h501f, 8'h01};
assign  cfg_data_reg[058]  =       {16'h440e, 8'h00};
assign  cfg_data_reg[059]  =       {16'h5000, 8'ha7};

assign  cfg_data_reg[060]  =       {16'h3a0f, 8'h30};
assign  cfg_data_reg[061]  =       {16'h3a10, 8'h28};
assign  cfg_data_reg[062]  =       {16'h3a1b, 8'h30};
assign  cfg_data_reg[063]  =       {16'h3a1e, 8'h26};
assign  cfg_data_reg[064]  =       {16'h3a11, 8'h60};
assign  cfg_data_reg[065]  =       {16'h3a1f, 8'h14};
assign  cfg_data_reg[066]  =       {16'h5800, 8'h23};
assign  cfg_data_reg[067]  =       {16'h5801, 8'h14};
assign  cfg_data_reg[068]  =       {16'h5802, 8'h0f};
assign  cfg_data_reg[069]  =       {16'h5803, 8'h0f};

assign  cfg_data_reg[070]  =       {16'h5804, 8'h12};
assign  cfg_data_reg[071]  =       {16'h5805, 8'h26};
assign  cfg_data_reg[072]  =       {16'h5806, 8'h0c};
assign  cfg_data_reg[073]  =       {16'h5807, 8'h08};
assign  cfg_data_reg[074]  =       {16'h5808, 8'h05};
assign  cfg_data_reg[075]  =       {16'h5809, 8'h05};
assign  cfg_data_reg[076]  =       {16'h580a, 8'h08};
assign  cfg_data_reg[077]  =       {16'h580b, 8'h0d};
assign  cfg_data_reg[078]  =       {16'h580c, 8'h08};
assign  cfg_data_reg[079]  =       {16'h580d, 8'h03};

assign  cfg_data_reg[080]  =       {16'h580e, 8'h00};
assign  cfg_data_reg[081]  =       {16'h580f, 8'h00};
assign  cfg_data_reg[082]  =       {16'h5810, 8'h03};
assign  cfg_data_reg[083]  =       {16'h5811, 8'h09};
assign  cfg_data_reg[084]  =       {16'h5812, 8'h07};
assign  cfg_data_reg[085]  =       {16'h5813, 8'h03};
assign  cfg_data_reg[086]  =       {16'h5814, 8'h00};
assign  cfg_data_reg[087]  =       {16'h5815, 8'h01};
assign  cfg_data_reg[088]  =       {16'h5816, 8'h03};
assign  cfg_data_reg[089]  =       {16'h5817, 8'h08};

assign  cfg_data_reg[090]  =       {16'h5818, 8'h0d};
assign  cfg_data_reg[091]  =       {16'h5819, 8'h08};
assign  cfg_data_reg[092]  =       {16'h581a, 8'h05};
assign  cfg_data_reg[093]  =       {16'h581b, 8'h06};
assign  cfg_data_reg[094]  =       {16'h581c, 8'h08};
assign  cfg_data_reg[095]  =       {16'h581d, 8'h0e};
assign  cfg_data_reg[096]  =       {16'h581e, 8'h29};
assign  cfg_data_reg[097]  =       {16'h581f, 8'h17};
assign  cfg_data_reg[098]  =       {16'h5820, 8'h11};
assign  cfg_data_reg[099]  =       {16'h5821, 8'h11};

assign  cfg_data_reg[100]  =       {16'h5822, 8'h15};
assign  cfg_data_reg[101]  =       {16'h5823, 8'h28};
assign  cfg_data_reg[102]  =       {16'h5824, 8'h46};
assign  cfg_data_reg[103]  =       {16'h5825, 8'h26};
assign  cfg_data_reg[104]  =       {16'h5826, 8'h08};
assign  cfg_data_reg[105]  =       {16'h5827, 8'h26};
assign  cfg_data_reg[106]  =       {16'h5828, 8'h64};
assign  cfg_data_reg[107]  =       {16'h5829, 8'h26};
assign  cfg_data_reg[108]  =       {16'h582a, 8'h24};
assign  cfg_data_reg[109]  =       {16'h582b, 8'h22};

assign  cfg_data_reg[110]  =       {16'h582c, 8'h24};
assign  cfg_data_reg[111]  =       {16'h582d, 8'h24};
assign  cfg_data_reg[112]  =       {16'h582e, 8'h06};
assign  cfg_data_reg[113]  =       {16'h582f, 8'h22};
assign  cfg_data_reg[114]  =       {16'h5830, 8'h40};
assign  cfg_data_reg[115]  =       {16'h5831, 8'h42};
assign  cfg_data_reg[116]  =       {16'h5832, 8'h24};
assign  cfg_data_reg[117]  =       {16'h5833, 8'h26};
assign  cfg_data_reg[118]  =       {16'h5834, 8'h24};
assign  cfg_data_reg[119]  =       {16'h5835, 8'h22};

assign  cfg_data_reg[120]  =       {16'h5836, 8'h22};
assign  cfg_data_reg[121]  =       {16'h5837, 8'h26};
assign  cfg_data_reg[122]  =       {16'h5838, 8'h44};
assign  cfg_data_reg[123]  =       {16'h5839, 8'h24};
assign  cfg_data_reg[124]  =       {16'h583a, 8'h26};
assign  cfg_data_reg[125]  =       {16'h583b, 8'h28};
assign  cfg_data_reg[126]  =       {16'h583c, 8'h42};
assign  cfg_data_reg[127]  =       {16'h583d, 8'hce};
assign  cfg_data_reg[128]  =       {16'h5180, 8'hff};
assign  cfg_data_reg[129]  =       {16'h5181, 8'hf2};

assign  cfg_data_reg[130]  =       {16'h5182, 8'h00};
assign  cfg_data_reg[131]  =       {16'h5183, 8'h14};
assign  cfg_data_reg[132]  =       {16'h5184, 8'h25};
assign  cfg_data_reg[133]  =       {16'h5185, 8'h24};
assign  cfg_data_reg[134]  =       {16'h5186, 8'h09};
assign  cfg_data_reg[135]  =       {16'h5187, 8'h09};
assign  cfg_data_reg[136]  =       {16'h5188, 8'h09};
assign  cfg_data_reg[137]  =       {16'h5189, 8'h75};
assign  cfg_data_reg[138]  =       {16'h518a, 8'h54};
assign  cfg_data_reg[139]  =       {16'h518b, 8'he0};

assign  cfg_data_reg[140]  =       {16'h518c, 8'hb2};
assign  cfg_data_reg[141]  =       {16'h518d, 8'h42};
assign  cfg_data_reg[142]  =       {16'h518e, 8'h3d};
assign  cfg_data_reg[143]  =       {16'h518f, 8'h56};
assign  cfg_data_reg[144]  =       {16'h5190, 8'h46};
assign  cfg_data_reg[145]  =       {16'h5191, 8'hf8};
assign  cfg_data_reg[146]  =       {16'h5192, 8'h04};
assign  cfg_data_reg[147]  =       {16'h5193, 8'h70};
assign  cfg_data_reg[148]  =       {16'h5194, 8'hf0};
assign  cfg_data_reg[149]  =       {16'h5195, 8'hf0};

assign  cfg_data_reg[150]  =       {16'h5196, 8'h03};
assign  cfg_data_reg[151]  =       {16'h5197, 8'h01};
assign  cfg_data_reg[152]  =       {16'h5198, 8'h04};
assign  cfg_data_reg[153]  =       {16'h5199, 8'h12};
assign  cfg_data_reg[154]  =       {16'h519a, 8'h04};
assign  cfg_data_reg[155]  =       {16'h519b, 8'h00};
assign  cfg_data_reg[156]  =       {16'h519c, 8'h06};
assign  cfg_data_reg[157]  =       {16'h519d, 8'h82};
assign  cfg_data_reg[158]  =       {16'h519e, 8'h38};
assign  cfg_data_reg[159]  =       {16'h5480, 8'h01};

assign  cfg_data_reg[160]  =       {16'h5481, 8'h08};
assign  cfg_data_reg[161]  =       {16'h5482, 8'h14};
assign  cfg_data_reg[162]  =       {16'h5483, 8'h28};
assign  cfg_data_reg[163]  =       {16'h5484, 8'h51};
assign  cfg_data_reg[164]  =       {16'h5485, 8'h65};
assign  cfg_data_reg[165]  =       {16'h5486, 8'h71};
assign  cfg_data_reg[166]  =       {16'h5487, 8'h7d};
assign  cfg_data_reg[167]  =       {16'h5488, 8'h87};
assign  cfg_data_reg[168]  =       {16'h5489, 8'h91};
assign  cfg_data_reg[169]  =       {16'h548a, 8'h9a};

assign  cfg_data_reg[170]  =       {16'h548b, 8'haa};
assign  cfg_data_reg[171]  =       {16'h548c, 8'hb8};
assign  cfg_data_reg[172]  =       {16'h548d, 8'hcd};
assign  cfg_data_reg[173]  =       {16'h548e, 8'hdd};
assign  cfg_data_reg[174]  =       {16'h548f, 8'hea};
assign  cfg_data_reg[175]  =       {16'h5490, 8'h1d};
assign  cfg_data_reg[176]  =       {16'h5381, 8'h1e};
assign  cfg_data_reg[177]  =       {16'h5382, 8'h5b};
assign  cfg_data_reg[178]  =       {16'h5383, 8'h08};
assign  cfg_data_reg[179]  =       {16'h5384, 8'h0a};

assign  cfg_data_reg[180]  =       {16'h5385, 8'h7e};
assign  cfg_data_reg[181]  =       {16'h5386, 8'h88};
assign  cfg_data_reg[182]  =       {16'h5387, 8'h7c};
assign  cfg_data_reg[183]  =       {16'h5388, 8'h6c};
assign  cfg_data_reg[184]  =       {16'h5389, 8'h10};
assign  cfg_data_reg[185]  =       {16'h538a, 8'h01};
assign  cfg_data_reg[186]  =       {16'h538b, 8'h98};
assign  cfg_data_reg[187]  =       {16'h5580, 8'h06};
assign  cfg_data_reg[188]  =       {16'h5583, 8'h40};
assign  cfg_data_reg[189]  =       {16'h5584, 8'h10};

assign  cfg_data_reg[190]  =       {16'h5589, 8'h10};
assign  cfg_data_reg[191]  =       {16'h558a, 8'h00};
assign  cfg_data_reg[192]  =       {16'h558b, 8'hf8};
assign  cfg_data_reg[193]  =       {16'h501d, 8'h40};
assign  cfg_data_reg[194]  =       {16'h5300, 8'h08};
assign  cfg_data_reg[195]  =       {16'h5301, 8'h30};
assign  cfg_data_reg[196]  =       {16'h5302, 8'h10};
assign  cfg_data_reg[197]  =       {16'h5303, 8'h00};
assign  cfg_data_reg[198]  =       {16'h5304, 8'h08};
assign  cfg_data_reg[199]  =       {16'h5305, 8'h30};

assign  cfg_data_reg[200]  =       {16'h5306, 8'h08};
assign  cfg_data_reg[201]  =       {16'h5307, 8'h16};
assign  cfg_data_reg[202]  =       {16'h5309, 8'h08};
assign  cfg_data_reg[203]  =       {16'h530a, 8'h30};
assign  cfg_data_reg[204]  =       {16'h530b, 8'h04};
assign  cfg_data_reg[205]  =       {16'h530c, 8'h06};
assign  cfg_data_reg[206]  =       {16'h5025, 8'h00};
assign  cfg_data_reg[207]  =       {16'h3008, 8'h02};
assign  cfg_data_reg[208]  =       {16'h3035, 8'h11};
assign  cfg_data_reg[209]  =       {16'h3036, 8'h46};

assign  cfg_data_reg[210]  =       {16'h3c07, 8'h08};
assign  cfg_data_reg[211]  =       {16'h3820, 8'h47};
assign  cfg_data_reg[212]  =       {16'h3821, 8'h00};
assign  cfg_data_reg[213]  =       {16'h3814, 8'h31};
assign  cfg_data_reg[214]  =       {16'h3815, 8'h31};
assign  cfg_data_reg[215]  =       {16'h3800, 8'h00};
assign  cfg_data_reg[216]  =       {16'h3801, 8'h00};
assign  cfg_data_reg[217]  =       {16'h3802, 8'h00};
assign  cfg_data_reg[218]  =       {16'h3803, 8'h04};
assign  cfg_data_reg[219]  =       {16'h3804, 8'h0a};

assign  cfg_data_reg[220]  =       {16'h3805, 8'h3f};
assign  cfg_data_reg[221]  =       {16'h3806, 8'h07};
assign  cfg_data_reg[222]  =       {16'h3807, 8'h9b};
assign  cfg_data_reg[223]  =       {16'h3808, 8'h02};
assign  cfg_data_reg[224]  =       {16'h3809, 8'h80};
assign  cfg_data_reg[225]  =       {16'h380a, 8'h01};
assign  cfg_data_reg[226]  =       {16'h380b, 8'he0};
assign  cfg_data_reg[227]  =       {16'h380c, 8'h07};
assign  cfg_data_reg[228]  =       {16'h380d, 8'h68};
assign  cfg_data_reg[229]  =       {16'h380e, 8'h03};

assign  cfg_data_reg[230]  =       {16'h380f, 8'hd8};
assign  cfg_data_reg[231]  =       {16'h3813, 8'h06};
assign  cfg_data_reg[232]  =       {16'h3618, 8'h00};
assign  cfg_data_reg[233]  =       {16'h3612, 8'h29};
assign  cfg_data_reg[234]  =       {16'h3709, 8'h52};
assign  cfg_data_reg[235]  =       {16'h370c, 8'h03};
assign  cfg_data_reg[236]  =       {16'h3a02, 8'h17};
assign  cfg_data_reg[237]  =       {16'h3a03, 8'h10};
assign  cfg_data_reg[238]  =       {16'h3a14, 8'h17};
assign  cfg_data_reg[239]  =       {16'h3a15, 8'h10};

assign  cfg_data_reg[240]  =       {16'h4004, 8'h02};
assign  cfg_data_reg[241]  =       {16'h3002, 8'h1c};
assign  cfg_data_reg[242]  =       {16'h3006, 8'hc3};
assign  cfg_data_reg[243]  =       {16'h4713, 8'h03};
assign  cfg_data_reg[244]  =       {16'h4407, 8'h04};
assign  cfg_data_reg[245]  =       {16'h460b, 8'h35};
assign  cfg_data_reg[246]  =       {16'h460c, 8'h22};
assign  cfg_data_reg[247]  =       {16'h4837, 8'h22};
assign  cfg_data_reg[248]  =       {16'h3824, 8'h02};
assign  cfg_data_reg[249]  =       {16'h5001, 8'ha3};

assign  cfg_data_reg[250]  =       {16'h3503, 8'h00};



endmodule
 */