module image_select(
	input 					clk,
    input 					rst_n,
  	input		[3:0]		mode,

	
    
    input		[15:0]		original_image,
    input       ov5640_wr_en,

    input		[7:0]		img_Y_r,
    input    ycbcr_wr_en,
    
   input		[15:0]		binary_img,
   input    binary_img_en,
    
    
    input		[7:0]		img_Y,
    input    median_wr_En,
    
    input		[15:0]		post_sobel,
    input		post3_frame_clken,
    
    input		[15:0]		erosion_rgb565,
    input    erosion_wr_en2,
    
    input		[15:0]		dilation_data,
    input    dilation_wr_en,
    input	[15:0]	fusion_rgb565,
    input	fusion_wr_en,
    
    output	 reg[15:0]		show_data ,
    output   reg       post_en   
 );
wire	[15:0]	origin_y = {img_Y_r[7:3],img_Y_r[7:2],img_Y_r[7:3]};
wire		[15:0]	median_y = {img_Y[7:3],img_Y[7:2],img_Y[7:3]};
//parameter   ROW_CNT = 800;
//parameter   COL_CNT = 600;      //800lie  600行
//reg     [11:0]  cnt_x;
//reg     [11:0]  cnt_y;

//wire   flag ;//开始本帧数据
//assign flag = (cnt_x == 0 && cnt_y == 0)? 1'b1:1'b0;

//wire	display_number_area =	(cnt_x >= 0 && cnt_x <=  800) && (cnt_y >= 0 && cnt_y <= 600); //64
////行计数 
//always @(posedge clk or negedge rst_n)begin  
//    if(rst_n == 1'b0)begin
//        cnt_x <= 0;
//    end
//    else if(Sobel_Erosion_Dilation_clk && cnt_x == ROW_CNT - 1)
//        cnt_x <= 0;
//    else if(Sobel_Erosion_Dilation_clk)begin
//        cnt_x <= cnt_x + 1'b1;
//    end
//    else 
//        cnt_x <= cnt_x;
//end

//assign  row_flag = (Sobel_Erosion_Dilation_clk && cnt_x == ROW_CNT - 1'b1)? 1'b1:1'b0;

////cnt_y
//always @(posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)begin
//        cnt_y <= 0;
//    end
//    else if(row_flag  &&  cnt_y == COL_CNT - 1'b1)
//        cnt_y <= 0;
//    else if(row_flag)begin
//        cnt_y <= cnt_y + 1'b1;
//    end
//    else 
//        cnt_y <= cnt_y;
//end

	

always @ (ycbcr_wr_en or median_wr_En or post3_frame_clken or erosion_wr_en2 or dilation_wr_en or fusion_wr_en) begin
    	case(mode)
        	4'd0:begin
            	show_data <= original_image;
                post_en <= ov5640_wr_en;
            end	
            4'd1:begin
            	show_data <= origin_y;
                post_en <= ycbcr_wr_en;
            end	
            4'd2:begin
            	show_data <= median_y;
                post_en <= median_wr_En;
            end	
            4'd6:begin
            	show_data <= post_sobel;
                post_en <= post3_frame_clken; 
            end 
            4'd4:begin
            	show_data <= erosion_rgb565;
                post_en <= erosion_wr_en2;
            end	
    		4'd5:begin
            	show_data <= dilation_data;
                post_en <= dilation_wr_en;
               
            end
            4'd7:begin
            	show_data <= fusion_rgb565;
                post_en <= fusion_wr_en;
            end
              4'd3:begin
            	show_data <= binary_img;
                post_en <= binary_img_en;
            end

        endcase
end

endmodule
