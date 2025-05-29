`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:16:35
// Design Name: 
// Module Name: ecc_enc
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
module ecc_enc (
  d_i,      //information bit vector input
  q_o,      //encoded data word output
  p_o      //parity vector output
);

  input  [7:0] d_i;      //information bit vector input
  output [12:0] q_o;      //encoded data word output
  output [4:0] p_o;      //parity vector output

wire [7:0] d_i;      //information bit vector input
wire [12:0] q_o;      //encoded data word output
wire [4:0] p_o;      //parity vector output

//---------------------------------------------------------
// Module Body
//---------------------------------------------------------

/*
  Below diagram indicates the locations of the parity and data bits
  in the final 'p' vector.
  It also shows what databits each parity bit operates on
    1  2  3  4  5  6  7  8  9 10 11 12 
   p1 p2 d1 p4 d2 d3 d4 p8 d5 d6 d7 d8 
p1  x     x     x     x     x     x     
p2     x  x        x  x        x  x    
p4           x  x  x  x              x 
p8                       x  x  x  x  x 
*/

assign p_o[0] = d_i[0] ^ d_i[1] ^ d_i[3] ^ d_i[4] ^ d_i[6];
assign p_o[1] = d_i[0] ^ d_i[2] ^ d_i[3] ^ d_i[5] ^ d_i[6];
assign p_o[2] = d_i[1] ^ d_i[2] ^ d_i[3] ^ d_i[7];
assign p_o[3] = d_i[4] ^ d_i[5] ^ d_i[6] ^ d_i[7];
assign p_o[4] = (^p_o[3:0]) ^ (^d_i[7:0]);

assign q_o[12:0] = {p_o[4:0],d_i[7:0]};


endmodule
