`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:15:54
// Design Name: 
// Module Name: ecc_top
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
module ecc_top (
  DOUT,
  DIN,
  ECC_EN,
  DI,
  DO,
  ERR_BIT_ADD,
  ERR_CODE
);

  //MRAM Interface
  input [12:0] DOUT;
  output [12:0] DIN;
  
  //IO Interface
  input ECC_EN;
  input [7:0] DI;
  output [7:0] DO;
  output [3:0] ERR_BIT_ADD;
  output [1:0] ERR_CODE;


wire [12:0] DOUT;
wire [12:0] DIN;
wire ECC_EN;
wire [7:0] DI;
wire [7:0] DO;
wire [3:0] ERR_BIT_ADD;
wire [1:0] ERR_CODE;

wire [12:0] din_ecc;
wire [7:0] do_ecc;
wire db_err;
wire sb_err;

//---------------------------------------------------------
// Module Body
//---------------------------------------------------------

//assign DIN[12:0] = ECC_EN ? din_ecc[12:0] : {din_ecc[12:8],DI[7:0]};
assign DIN[12:0] = din_ecc[12:0];
assign DO[7:0]   = ECC_EN ? do_ecc[7:0] : DOUT[7:0];
assign ERR_CODE[1:0] = {db_err,sb_err};

ecc_enc u_ecc_enc(
  .d_i(DI[7:0]),      //information bit vector input
  .q_o(din_ecc[12:0]),      //encoded data word output
  .p_o()      //parity vector output
);

ecc_dec u_ecc_dec(
  //data ports
  .d_i(DOUT[12:0]),        //encoded code word input
  .q_o(do_ecc[7:0]),        //information bit vector output
  .syndrome_o(), //syndrome vector output
  //flags
  .sb_err_o(sb_err),   //single bit error detected
  .db_err_o(db_err),    //double bit error detected
  .err_addr_o(ERR_BIT_ADD[3:0])
);

endmodule
