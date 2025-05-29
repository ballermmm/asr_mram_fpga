`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/12 18:13:47
// Design Name: 
// Module Name: input_buffer
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


module input_buffer #(
    parameter INPUT_CHANNEL = 224,
    parameter BANDWIDTH = 8,
    parameter OUT_BANDWIDTH = 24,
    parameter WEIGHT_CHANNEL = 8
) 
(
    input clk,
    input rstn,
    input nen,

    input signed [BANDWIDTH-1:0] input_data [INPUT_CHANNEL-1:0],
    input signed [BANDWIDTH-1:0] weight_data [WEIGHT_CHANNEL-1:0][INPUT_CHANNEL-1:0],
    input signed [BANDWIDTH-1:0] bias_data [WEIGHT_CHANNEL-1:0],
    
    output reg signed [OUT_BANDWIDTH-1:0] output_data [WEIGHT_CHANNEL-1:0]
);
    
    reg [2:0] cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt <= 0;
        end else if (!nen) begin
            cnt <= cnt + 1;
        end
    end

    wire signed [OUT_BANDWIDTH-1:0] output_temp;
    mult_addertree #(
        .INPUT_CHANNEL(INPUT_CHANNEL),
        .BANDWIDTH(BANDWIDTH),
        .OUT_BANDWIDTH(OUT_BANDWIDTH)
    ) mult_addertree_inst (
        .input_data(input_data),
        .weight_data(weight_data[cnt]),
        .bias_data(bias_data[cnt]),

        .output_data(output_temp)
    );

    always @(posedge clk) begin
        if (!nen) begin
            output_data[cnt] <= output_temp;
        end
    end

endmodule