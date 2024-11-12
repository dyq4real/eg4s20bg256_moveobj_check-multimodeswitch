module mul_obj_check #(
    parameter H_PIXEL  = 11'd800,
    parameter V_PIXEL  = 10'd600,
    parameter MIN_DISC = 10'd50
) 
(
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,

    input  wire                         pre_hs                     ,
    input  wire                         pre_vs                     ,
    input  wire                         pre_wr_en                  ,
    input  wire                         pre_1bit                   ,

    output wire                         mul_hs                     ,
    output wire                         mul_vs                     ,
    output wire                         mul_wr_en                  ,
    //ymax为[41:32],xmax[31:21],ymin[20:11],xmin[10:0]
    output logic [42:0]                 pos_data_out    [15:0]//boundary data
    
);
  reg [42:0] pos_data [15:0];
  reg vs_r;
  reg vs_fall,vs_rise;
  reg [10:0] cnt_x,cnt_x_r;
  reg [ 9:0] cnt_y,cnt_y_r;

  wire field_valid;
//*vs_fall vs_rise---------------------————————————————————————
always_ff @(posedge sys_clk or negedge sys_rst_n) begin 
    if(sys_rst_n == 1'b0) begin
        vs_r <= 1'b0;
    end
    else begin
        vs_r <= pre_vs;
    end
end
always_ff @(posedge sys_clk or negedge sys_rst_n) begin : fall
    if(sys_rst_n == 1'b0) begin
    	vs_fall <= 1'b0;
        vs_rise <= 1'b0;
    end
    else if (!pre_vs && vs_r) begin
        vs_fall <= 1'b1;
    end
    else if (!vs_r && pre_vs) begin
        vs_rise <= 1'b1;
    end
    else begin
        vs_fall <= 1'b0;
        vs_rise <= 1'b0;
    end
end
//*******___________________________________________________

//*数据打拍
reg wr_en_r,pre_1bit_r;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	wr_en_r <= 1'b0;
        pre_1bit_r <= 1'b0;
    end
    else begin
        wr_en_r <= pre_wr_en;
        pre_1bit_r <= pre_1bit;
    end
end
assign field_valid = ((cnt_x > 20 && cnt_x < (H_PIXEL - 20))&& (cnt_y > 15 && cnt_y < (V_PIXEL - 15))) ? 1'b1 : 1'b0;
//*——————————————————————————————————————————————————————————

//*进行像素计数——————————————————————————————————————————————
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
    	cnt_x <= 11'd0;
    end
    else if(pre_wr_en)begin
        if(cnt_x < (H_PIXEL - 1)) begin
            cnt_x <= cnt_x + 1'b1;
        end
        else begin
            cnt_x <= 11'd0;
        end
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
    	cnt_y <= 10'd0;
    end
    else if ((cnt_x == H_PIXEL - 1) && pre_wr_en) begin
        if (cnt_y < V_PIXEL - 1) begin
            cnt_y <= cnt_y + 1'b1;
        end
        else begin
            cnt_y <= 10'd0;
        end
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	cnt_x_r <= 11'd0;
        cnt_y_r <= 10'd0;
    end
    else begin
        cnt_x_r <= cnt_x;
        cnt_y_r <= cnt_y;
    end
end

//*——————————————————————————————————————————————————————————
  //*检测 定义上下左右范围,用于邻域检测
  wire        target_flag [15:0];
  wire [10:0] target_right[15:0];
  wire [10:0] target_left [15:0];
  wire [ 9:0] target_up   [15:0];
  wire [ 9:0] target_down [15:0];
  //*像素边界，寄存输出边框数据的边界信息
  wire [10:0] pixel_right[15:0];
  wire [10:0] pixel_left [15:0];
  wire [ 9:0] pixel_up   [15:0];
  wire [ 9:0] pixel_down [15:0];
      //ymax为[41:32],xmax[31:21],ymin[20:11],xmin[10:0]
  genvar i;
generate for ( i=0; i<16; i = i + 1) begin :sd
    assign target_flag[i]  = pos_data[i][42];
    assign target_down[i]  = pixel_down[i]  < (V_PIXEL - MIN_DISC)  ? (pixel_down[i] + MIN_DISC)    : (V_PIXEL);
    assign target_right[i] = pixel_right[i] < (H_PIXEL - MIN_DISC)  ? (pixel_right[i] + MIN_DISC)   : H_PIXEL;
    assign target_up[i]    = pixel_up[i]    > (MIN_DISC)            ? (pixel_up[i] - MIN_DISC)      : 10'd0;
    assign target_left[i]  = pixel_left[i]  > (MIN_DISC)            ? (pixel_left[i] - MIN_DISC)    : 11'd0;

    assign pixel_down[i] = pos_data[i][41:32];
    assign pixel_right[i]= pos_data[i][31:21];
    assign pixel_up[i]   = pos_data[i][20:11];
    assign pixel_left[i] = pos_data[i][10:0];
end 
endgenerate

//*——————————————————————————————————————————————————————————————————
      //ymax为[41:32],xmax[31:21],ymin[20:11],xmin[10:0]
      /*
      ?情况分类：
      ?1.出现新目标
      ?2.出现目标但是为之前已出现的邻域之内(归为老目标)
      */
reg [ 3:0]  tar_cnt;
reg [15:0] tar_flag;//*用来标志是否为新目标
integer j,k;
//*帧差检测函数
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	for (j =0; j<16; ++j) begin
           // pos_data[j] <= {1'b0,V_PIXEL,H_PIXEL,10'd0,11'd0};
           pos_data[j] <= 43'd0;
        end
        tar_flag <= 16'd0;
        tar_cnt  <= 4'd0;
    end
    //*在每帧开始复位pos_data
    else if(vs_fall) begin
        for (j =0; j<16; ++j) begin //*16个并行
            pos_data[j] <= 43'd0;
        end
        tar_flag <= 16'd0;
        tar_cnt  <= 4'd0;
    end
    else begin
    //*——————————————————————————————————————————————————————————————————————
        //*检测到帧差像素，进入判断（第一个clk）
        if(pre_wr_en && (!pre_1bit) && field_valid)begin
        for (j = 0;j < 16;++j) begin
            //*数组中没有目标，flag=0，所以定为新目标
            if((!target_flag[j]) && (tar_flag != 16'hffff)) begin
                tar_flag[j] <= 1'b1;
            end
            else begin
            if(((cnt_x < target_left[j]) || (cnt_x > target_right[j]) || (cnt_y < target_up[j]) || (cnt_y > target_down[j]))
            && (tar_flag != 16'hffff)) begin
                tar_flag[j] <= 1'b1;//*在边界外，判定为新目标
            end
            else begin
                tar_flag[j] <= 1'b0;//*以上均不满足，为之前目标
            end 
            end
        end
    end
        else begin
            tar_flag <= 16'd0;//*未检测到运动目标
        end
    //*————————————————————————————————————————————————————————————————————————————
          //ymax为[41:32],xmax[31:21],ymin[20:11],xmin[10:0]
    //*延后上一个if一个clk
        if (wr_en_r && (!pre_1bit_r)&& field_valid) begin
            if (tar_flag == 16'hffff) begin //*16个vector都认定为新目标
            tar_cnt <= tar_cnt + 1'b1;
            pos_data[tar_cnt] <= {1'b1,cnt_y_r,cnt_x_r,cnt_y_r,cnt_x_r};
            tar_flag <= 16'd0;
        end
        //*未检测到运动目标或者不是新目标不进入判断
            else if(tar_flag > 16'd0) begin
            for (k = 0;k < 16;++k ) begin
                if(tar_flag[k] == 1'b0) begin //*认为在自己邻域内部
                    pos_data[k][42] <= 1'b1;
                    if(cnt_x_r < pos_data[k][10:0]) begin
                        pos_data[k][10:0] <= cnt_x_r;//*xmin：left
                    end
                    else if(cnt_x_r > pos_data[k][31:21]) begin
                        pos_data[k][31:21] <= cnt_x_r;//*xmax:right
                    end
                    else if (cnt_y_r > pos_data[k][41:32]) begin
                        pos_data[k][41:32] <= cnt_y_r;//*ymax:down
                    end
                    else if (cnt_y_r < pos_data[k][20:11]) begin
                        pos_data[k][20:11] <= cnt_y_r;//*ymin:up
                    end
                end
            end
            tar_flag <= 16'd0;
        end
        end
    end
end

//*寄存输出信号在一帧结束的时候
integer l;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        for (l = 0;l<16 ;++l ) begin
            pos_data_out[l] <= 43'd0;
        end	
    end
    else if(vs_rise) begin
        for (l = 0;l<16 ;++l ) begin
            pos_data_out[l] <= pos_data[l];
        end
    end
    else begin
        for (l = 0;l<16 ;++l ) begin
            pos_data_out[l] <= pos_data_out[l];
        end
    end
end


//*同步信号hs vs wr_en
reg [2:0] vs_reg;
reg [2:0] hs_reg;
reg [2:0] wr_en_reg;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	vs_reg <= 3'd0;
        hs_reg <= 3'd0;
        wr_en_reg <= 3'd0;
    end
    else begin
        vs_reg <= {vs_reg[1],vs_reg[0],pre_vs};
        hs_reg <= {hs_reg[1],hs_reg[0],pre_hs};
        wr_en_reg <= {wr_en_reg[1],wr_en_reg[0],pre_wr_en};
    end
end
assign mul_hs = hs_reg[2];
assign mul_vs = vs_reg[2];
assign mul_wr_en = wr_en_reg[2];
endmodule
