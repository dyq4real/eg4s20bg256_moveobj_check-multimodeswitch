module boundary_fusion #(
    parameter H_PIXEL = 'D1024,
    parameter V_PIXEL = 'D768
) 
(
    input wire sys_clk,
    input wire sys_rst_n,

    input wire pre_wr_en,
    input wire pre_hs,
    input wire pre_vs,
    input wire [42:0] pos_data[15:0],
    input wire [15:0] cam_data,

    output reg [15:0] fusion_rgb565,
    output reg  fusion_hs,
    output reg  fusion_vs,
    output reg  fusion_wr_en,
    output reg [7:0] fusion_r,
    output reg [7:0] fusion_g,
    output reg [7:0] fusion_b,
    output wire [23:0] fusion_rgb888,

    output reg  [7:0] obj_num
);
  wire [7:0] cam_r = {cam_data[15:11], cam_data[15:13]};
  wire [7:0] cam_g = {cam_data[10:5] , cam_data[10:9] };
  wire [7:0] cam_b = {cam_data[4:0]  , cam_data[4:2]  };
(*keep = 1*)  reg [10:0] cnt_x;
(*keep = 1*)  reg [10:0] cnt_y;
//ymax为[41:32],xmax[31:21],ymin[20:11],xmin[10:0]
(*keep = 1*)  wire [10:0] boundary_left [15:0];
(*keep = 1*)  wire [10:0] boundary_right [15:0];
(*keep = 1*)  wire [9:0] boundary_up [15:0];
(*keep = 1*)  wire [9:0] boundary_down [15:0];
(*keep = 1*)  wire boundary_flag[15:0];

genvar j;
generate 
    for (j = 0;j<16 ;++j ) begin : shift
        assign boundary_down[j]  = pos_data[j][41:32];
        assign boundary_right[j] = pos_data[j][31:21];
        assign boundary_up[j]    = pos_data[j][20:11];
        assign boundary_left[j]  = pos_data[j][10:0];
        assign boundary_flag[j]  = pos_data[j][42];
    end
endgenerate

//*行场计数
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	cnt_x <= 11'd0;
        cnt_y <= 11'd0;
    end
    else if(pre_wr_en) begin
        if (cnt_x < H_PIXEL - 1) begin
            cnt_x <= cnt_x + 1'b1;
            cnt_y <= cnt_y;
        end
        else if (cnt_x == H_PIXEL - 1)begin
            cnt_x <= 11'd0;
            if (cnt_y < V_PIXEL - 1) begin
                cnt_y <= cnt_y + 1'b1;
            end
            else begin
                cnt_y <= 11'd0;
            end
        end
    end
end
//*————————————————————————————————————————
wire filed_valid;
assign filed_valid = (((H_PIXEL - 20)>cnt_x && cnt_x>20) && ((V_PIXEL-15)>cnt_y && cnt_y>20)) ? 1'b1 : 1'b0;
wire [15:0] add_flag1_r,add_flag2_r;
reg [15:0] add_flag1,add_flag2;

genvar i;
generate for ( i=0 ;i<16 ;++i ) begin 
//*左右边框检测
    assign add_flag1_r[i] = (boundary_flag[i] && filed_valid && 
     (((cnt_x == boundary_right[i]) || (cnt_x == boundary_left[i]))
        && ((cnt_y <= boundary_down[i]) && (cnt_y >= boundary_up[i])))) ? 1'b1 : 1'b0;
//*检测上下边框
    assign add_flag2_r[i] = (boundary_flag[i] && filed_valid && 
    (((cnt_x <= boundary_right[i]) && (cnt_x >= boundary_left[i]))
        && ((cnt_y == boundary_down[i]) || (cnt_y == boundary_up[i])))) ? 1'b1 : 1'b0;
end
endgenerate
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	add_flag1 <= 16'd0;
        add_flag2 <= 16'd0;
    end
    else begin
        add_flag1 <= add_flag1_r;
        add_flag2 <= add_flag2_r;
    end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	fusion_r <= 8'd0;
        fusion_g <= 8'd0;
        fusion_b <= 8'd0;
    end
    //ymax为[41:32],xmax[31:21],ymin[20:11],xmin[10:0]
    else begin
            if ((add_flag1!=16'h0000) || (add_flag2!=16'h0000)) begin
                    fusion_r <= 8'd255;
                    fusion_g <= 8'd0;
                    fusion_b <= 8'd0;
            end
            else begin
                fusion_r <= cam_r;
                fusion_g <= cam_g;
                fusion_b <= cam_b;
            end
    end
end

//*延迟一拍同步信号
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	fusion_hs <= 1'b0;
        fusion_vs <= 1'b0;
        fusion_wr_en <= 1'b0;
    end
    else begin
        fusion_hs <= pre_hs;
        fusion_vs <= pre_vs;
        fusion_wr_en <= pre_wr_en;
    end
end

//*组合逻辑输出两种rgb格式
assign fusion_rgb565 = {fusion_r[7:3],fusion_g[7:2],fusion_b[7:3]};
assign fusion_rgb888 = {fusion_r,fusion_g,fusion_b};
reg [3:0] obj_num_reg1,obj_num_reg2,obj_num_reg3,obj_num_reg4;
reg [3:0] cnt_wait;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	obj_num_reg1 <= 4'd0;
        obj_num_reg2 <= 4'd0;
        obj_num_reg3 <= 4'd0;
        obj_num_reg4  <= 4'd0;
    end
    else begin
        obj_num_reg1 <= boundary_flag[0]+boundary_flag[1]+boundary_flag[2]+boundary_flag[3];
        obj_num_reg2 <= boundary_flag[4]+boundary_flag[5]+boundary_flag[6]+boundary_flag[7];
        obj_num_reg3 <= boundary_flag[8]+boundary_flag[9]+boundary_flag[10]+boundary_flag[11];
        obj_num_reg4 <= boundary_flag[12]+boundary_flag[13]+boundary_flag[14]+boundary_flag[15];
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	obj_num <= 8'd0;
    end
    else if (( obj_num_reg1 + obj_num_reg2 + obj_num_reg3 + obj_num_reg4) == 0 && cnt_wait!= 4'd2) begin
        obj_num <= obj_num;
    end
    else begin
        obj_num <= obj_num_reg1 + obj_num_reg2 + obj_num_reg3 + obj_num_reg4;
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	cnt_wait <= 4'd0;
    end
    else if (cnt_wait == 4'd2) begin
        cnt_wait <= 4'd0;
    end
    else begin
        cnt_wait <= cnt_wait + 1'b1;
    end
end
endmodule
