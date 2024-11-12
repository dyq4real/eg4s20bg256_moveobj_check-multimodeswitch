module cam_syn (
    input  wire                         sys_clk                    ,
    input  wire                         sys_rst_n                  ,

    input  wire                         pre_wr_en                  ,
    input  wire                         pre_vs                     ,
    input  wire                         pre_hs                     ,
    input  wire        [  15:0]         cam_data                   ,

    output wire                         syn_wr_en                  ,
    output wire                         syn_hs                     ,
    output wire                         syn_vs                     ,
    output reg         [  15:0]         syn_data                    
);
reg                    [  22:0]         vs_r                       ;
reg                    [  22:0]         hs_r                       ;
reg                    [  22:0]         wr_en_r                    ;
reg [15:0]                              data_r [21:0]              ;
//*同步信号
assign syn_vs = vs_r[22];
assign syn_hs = hs_r[22];
assign syn_wr_en = wr_en_r[22];

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	vs_r <= 23'd0;
        hs_r <= 23'd0;
        wr_en_r <= 23'd0;
    end
    else begin
        vs_r <= {vs_r[21:0],pre_vs};
        hs_r <= {hs_r[21:0],pre_hs};
        wr_en_r <= {wr_en_r[21:0],pre_wr_en};
    end
end

integer i;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	for (i=0; i<22; ++i) begin
            data_r[i] <= 16'd0; 
        end
    end
    else begin
        data_r[0] <= cam_data;
        for (i=1; i<22; ++i) begin
            data_r[i] <= data_r[i - 1];
        end
    end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
    	syn_data <= 16'd0;
    end
    else begin
        syn_data <= data_r[21];
    end
end
endmodule //cam_syn