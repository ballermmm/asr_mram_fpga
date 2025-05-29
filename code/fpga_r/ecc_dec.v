`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:17:05
// Design Name: 
// Module Name: ecc_dec
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


module ecc_dec(
  //data ports
  d_i,        //encoded code word input
  q_o,        //information bit vector output
  syndrome_o, //syndrome vector output
  //flags
  sb_err_o,   //single bit error detected
  db_err_o,    //double bit error detected
  err_addr_o
);

  //data ports
  input   [12:0] d_i;        //encoded code word input
  output  [7:0] q_o;        //information bit vector output
  output  [4:0] syndrome_o; //syndrome vector output
  //flags
  output          sb_err_o;   //single bit error detected
  output          db_err_o;   //double bit error detected
  output [3:0] err_addr_o;

//---------------------------------------------------------
// Variables 
//---------------------------------------------------------
wire          parity;      //full codeword parity check
wire  [3  :0] syndrome;    //bit error indication/location
reg   [12  :0] cw_fixed;    //corrected code word
 
wire  [4  :0] syndrome_o; 
wire  [12  :0] d;
wire  [7:0] q_o;
wire          sb_err_o;
wire          db_err_o;
reg   [3:0] err_addr_o;

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
//Step 1: Locate Parity bit
assign d[12:0] = {d_i[12],d_i[7:4],d_i[11],d_i[3:1],d_i[10],d_i[0],d_i[9:8]};

//Step 2: Calculate code word parity
//assign parity = ^d[12:0];
assign syndrome_o[4] = ^d[12:0];

//Step 3: Calculate syndrome
assign syndrome_o[0] = d[0] ^ d[2] ^ d[4] ^ d[6] ^ d[8] ^ d[10];
assign syndrome_o[1] = d[1] ^ d[2] ^ d[5] ^ d[6] ^ d[9] ^ d[10];
assign syndrome_o[2] = d[3] ^ d[4] ^ d[5] ^ d[6] ^ d[11];
assign syndrome_o[3] = d[7] ^ d[8] ^ d[9] ^ d[10] ^ d[11];
  
//Step 5: Correct erroneous bit (if any)
always @(*) 
begin
  cw_fixed[12:0] = d[12:0];
  case (syndrome_o[4:0])
    5'h10 : cw_fixed[12] = ~d[12];
    5'h11 : cw_fixed[0] = ~d[0];
	5'h12 : cw_fixed[1] = ~d[1];
	5'h13 : cw_fixed[2] = ~d[2];
	5'h14 : cw_fixed[3] = ~d[3];
	5'h15 : cw_fixed[4] = ~d[4];
	5'h16 : cw_fixed[5] = ~d[5];
	5'h17 : cw_fixed[6] = ~d[6];
	5'h18 : cw_fixed[7] = ~d[7];
	5'h19 : cw_fixed[8] = ~d[8];
	5'h1a : cw_fixed[9] = ~d[9];
	5'h1b : cw_fixed[10] = ~d[10];
	5'h1c : cw_fixed[11] = ~d[11];
	default : cw_fixed[12:0] = d[12:0];
  endcase
end

//Step 6: Extract information bits vector
//assign q = extract_q(cw_fixed);

assign q_o[7:0] = {cw_fixed[11:8],cw_fixed[6:4],cw_fixed[2]};

//Step 7: Generate status flags
//assign sb_err_o =  syndrome_o[4] & |syndrome_o[3:0];
assign sb_err_o =  syndrome_o[4];
assign db_err_o = ~syndrome_o[4] & |syndrome_o[3:0];

always @(*) 
begin
  err_addr_o[3:0] = 4'hf;
  case (syndrome_o[4:0])
    5'h10 : err_addr_o[3:0] = 4'hc;
    5'h11 : err_addr_o[3:0] = 4'h8;
	5'h12 : err_addr_o[3:0] = 4'h9;
	5'h13 : err_addr_o[3:0] = 4'h0;
	5'h14 : err_addr_o[3:0] = 4'ha;
	5'h15 : err_addr_o[3:0] = 4'h1;
	5'h16 : err_addr_o[3:0] = 4'h2;
	5'h17 : err_addr_o[3:0] = 4'h3;
	5'h18 : err_addr_o[3:0] = 4'hb;
	5'h19 : err_addr_o[3:0] = 4'h4;
	5'h1a : err_addr_o[3:0] = 4'h5;
	5'h1b : err_addr_o[3:0] = 4'h6;
	5'h1c : err_addr_o[3:0] = 4'h7;
	default : err_addr_o[3:0] = 4'hf;
  endcase
end

endmodule


