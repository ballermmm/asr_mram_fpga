`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:13:52
// Design Name: 
// Module Name: CLK_50MHZ
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CLK_50MHZ(
    input sys_clk,
    input rst_n,             // 复位信号

    output  reg clk_50M       // 50M输出时钟
 
);

reg clk_100M;
// 差分时钟缓冲器


// 产生100M时钟信号
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_100M <= 1'b0;    // 复位时将100M时钟清零
    end else begin
        clk_100M <= ~clk_100M;  // 反转产生100M时钟
    end
end

// 产生50M时钟
always @(posedge clk_100M or negedge rst_n) begin
    if (!rst_n) begin
        clk_50M <= 1'b0;     // 复位时将50M时钟清零
    end else begin
        clk_50M <= ~clk_50M; // 反转产生50M时钟
    end
end

endmodule
