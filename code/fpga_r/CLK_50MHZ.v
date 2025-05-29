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
    input rst_n,             // ��λ�ź�

    output  reg clk_50M       // 50M���ʱ��
 
);

reg clk_100M;
// ���ʱ�ӻ�����


// ����100Mʱ���ź�
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_100M <= 1'b0;    // ��λʱ��100Mʱ������
    end else begin
        clk_100M <= ~clk_100M;  // ��ת����100Mʱ��
    end
end

// ����50Mʱ��
always @(posedge clk_100M or negedge rst_n) begin
    if (!rst_n) begin
        clk_50M <= 1'b0;     // ��λʱ��50Mʱ������
    end else begin
        clk_50M <= ~clk_50M; // ��ת����50Mʱ��
    end
end

endmodule
