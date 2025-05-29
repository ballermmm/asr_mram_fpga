`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/12 18:14:24
// Design Name: 
// Module Name: mult_addertree
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


module mult_addertree #(
    parameter INPUT_CHANNEL = 224,
    parameter BANDWIDTH = 8,
    parameter OUT_BANDWIDTH = 24
)
(
    input signed [BANDWIDTH-1:0] input_data [INPUT_CHANNEL-1:0],
    input signed [BANDWIDTH-1:0] weight_data [INPUT_CHANNEL-1:0],
    input signed [BANDWIDTH-1:0] bias_data,

    output signed [OUT_BANDWIDTH-1:0] output_data
);
    
    genvar i;

    //mult
    wire signed [(BANDWIDTH<<1)-1:0] mult_temp [INPUT_CHANNEL-1:0];
    generate
        for (i = 0; i < INPUT_CHANNEL; i = i + 1) begin: GEN_MULT
            assign mult_temp[i] = input_data[i] * weight_data[i];
        end
    endgenerate

    //addertree_1
    wire signed [((BANDWIDTH<<1)+1)-1:0] addertree_1 [(INPUT_CHANNEL>>1)-1:0];
    generate
        for (i = 0; i < (INPUT_CHANNEL>>1); i = i + 1) begin
            assign addertree_1[i] = mult_temp[i<<1] + mult_temp[(i<<1)+1];
        end
    endgenerate

    //addertree_2
    wire signed [((BANDWIDTH<<1)+2)-1:0] addertree_2 [(INPUT_CHANNEL>>2)-1:0];
    generate
        for (i = 0; i < (INPUT_CHANNEL>>2); i = i + 1) begin
            assign addertree_2[i] = addertree_1[i<<1] + addertree_1[(i<<1)+1];
        end
    endgenerate

    //addertree_3
    wire signed [((BANDWIDTH<<1)+3)-1:0] addertree_3 [(INPUT_CHANNEL>>3)-1:0];
    generate
        for (i = 0; i < (INPUT_CHANNEL>>3); i = i + 1) begin
            assign addertree_3[i] = addertree_2[i<<1] + addertree_2[(i<<1)+1];
        end
    endgenerate

    //addertree_4
    wire signed [((BANDWIDTH<<1)+4)-1:0] addertree_4 [(INPUT_CHANNEL>>4)-1:0];
    generate
        for (i = 0; i < (INPUT_CHANNEL>>4); i = i + 1) begin
            assign addertree_4[i] = addertree_3[i<<1] + addertree_3[(i<<1)+1];
        end
    endgenerate

    //addertree_5
    wire signed [((BANDWIDTH<<1)+5)-1:0] addertree_5 [(INPUT_CHANNEL>>5):0];
    assign addertree_5[(INPUT_CHANNEL>>5)] = bias_data;
    generate
        for (i = 0; i < (INPUT_CHANNEL>>5); i = i + 1) begin
            assign addertree_5[i] = addertree_4[i<<1] + addertree_4[(i<<1)+1];
        end
    endgenerate

    //addertree_6
    wire signed [((BANDWIDTH<<1)+6)-1:0] addertree_6 [(INPUT_CHANNEL>>6):0];
    generate
        for (i = 0; i <= (INPUT_CHANNEL>>6); i = i + 1) begin
            assign addertree_6[i] = addertree_5[i<<1] + addertree_5[(i<<1)+1];
        end
    endgenerate

    //addertree_7
    wire signed [((BANDWIDTH<<1)+7)-1:0] addertree_7 [(INPUT_CHANNEL>>7):0];
    generate
        for (i = 0; i <= (INPUT_CHANNEL>>7); i = i + 1) begin
            assign addertree_7[i] = addertree_6[i<<1] + addertree_6[(i<<1)+1];
        end
    endgenerate

    assign output_data = addertree_7[1] + addertree_7[0];

endmodule