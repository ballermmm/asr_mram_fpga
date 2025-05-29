//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:11:04
// Design Name: 
// Module Name: fpga_mram
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


module fpga_mram
#(    
    parameter   debug_mode    =     1'b0,
    parameter   ECC_EN        =     1'b0,
    parameter   MUX_EN        =     1'b0,
    parameter   DATA_BYTES    =   15'd1799,//15'd16383,// 8'd511, //8'd127,//255,// 2'd3,       //15'd16383,    //          
    parameter   data_into_enc =     8'b00001111
) 
(

      input       CLK_200,//clk_mram_200M    clk
      input       rd_trigger,//en
      input  [7:0] out_from_mram,//reg in
//      input      [13:0] addr,//addr
 //     inout       [7:0] DQ,//
      
//    input       sys_clk_p,         // ����ź���?
//    input       sys_clk_n,         // ����źŸ�?
//    input       Rst_n,
//    input       key_in,
//    input       key_in2,

    
//    output wire [13:0] A,//addr
    output wire W_CLK,  
    output wire R_CLK,
    output wire EN,
    output wire WR,
//    output wire Rs232_Tx,
    output dir,
    output OE_D,
    output OE_OUT,
    output TURNOVER,
    output OUTSEL,
    output reg [7:0] output_nn, //reg_out  douta
    output wire CLK_FIFO
);
    wire [12:0] DOUT;
    wire [12:0] DIN;
//    wire A15;       
    wire MUX_EN_WIRE;
    wire [3:0] state;
    wire Tx_Done;
    wire [7:0]data_byte;
    wire [7:0] DO;
    wire [13:0]data_to_fifo;
    wire [13:0]  fifo_out;
    wire [13:0]  usedw;
    wire send_en;
    wire rdreq;
    wire wrreq;     
    wire  key_down;


//  inner wire
    
    wire        key_flag;
    wire        key_state;
    
    wire        key_flag2;
    wire        key_state2;
    wire        key_down2;
    wire        [7:0] DI;
    wire        [3:0] ERR_BIT_ADD;
    wire        [1:0] ERR_CODE;
    wire        Tx_All_Done;
  //  wire        CLK_200;
    wire        CLK;
 //   wire        key_in2_inv;
    reg         Rst_n=1'b1;
    
    wire        [15:0] counter;
		
assign key_down = key_flag & !key_state;
assign key_down2 = key_flag2 & !key_state2;
//assign key_in2_inv = !key_in2;
//assign A15 = 0;

assign dir = ~WR;//0;//
//assign DQ[12:0] = (1'b1 == dir) ? DIN[12:0] : 13'bzzz_zzzzz_zzzzz;
//assign DOUT[12:0] = DQ[12:0];

assign TURNOVER = 1'b1;
assign OUTSEL = 1'b0;

assign OE_D = WR;
assign OE_OUT = dir;

//assign  A [7:0]= addr[7:0];
///////////////////////////////////////////////////////////////

// ���ʱ�ӻ�����?
//IBUFDS IBUFDS_inst (
//    .O (CLK_200),            // ���������?
//    .I (sys_clk_p),          // ����ź�������?
//    .IB (sys_clk_n)          // ����źŸ�����?
//);

key_filter key_filter1(
    .Clk(CLK),
    .Rst_n(Rst_n),
    .key_in(key_in),
    .key_flag(key_flag),
    .key_state(key_state)
);
key_filter key_filter2(
    .Clk(CLK),
    .Rst_n(Rst_n),
    .key_in(key_in2_inv),      //����ȡ������ΪPCB��һ��key����ʱ��ƽΪ��
    .key_flag(key_flag2),
    .key_state(key_state2)
);

///*
//pll_200MHz	pll_200MHz_inst (
//	.inclk0 ( CLK ),
//	.c0 ( CLK_200 )
//	);
////

CLK_50MHZ  CLK_ALL(
  .sys_clk  (CLK_200),
  .rst_n    (Rst_n),
  .clk_50M  (CLK)
 );
 

state_ctrl #( 
    .CYCLE_Tw_i  (50),
    .CYCLE_Taews (50),
    .CYCLE_Twrite(50),
    .CYCLE_Twena (50),
    .CYCLE_Tpre  (50),
    .CYCLE_Tread (50),
    .CYCLE_Trona (50),
    .CYCLE_MUX   (10000),
    .MUX_EN      (MUX_EN),
    .data_into_enc(data_into_enc),
    .MRAM_addr_minus_one  (DATA_BYTES) //����MRAM����ֻ��4b�����ڷ���debug
  )
state_ctrl_inst (
    .CLK(CLK),
    .CLK_200(CLK_200), //���໷������200MHz
    .key_down(key_down),
    .key_down2(key_down2),
    .Rst_n(Rst_n),
    .ERR_BIT_ADD(ERR_BIT_ADD),
    .ERR_CODE(ERR_CODE),
    .DO(DO),
    .Tx_Done(Tx_Done),
    .rd_trigger(rd_trigger),

    .MUX_EN_WIRE(MUX_EN_WIRE),
    .DI(DI),
//    .A(A),
    .W_CLK(W_CLK),
    .R_CLK(R_CLK),
    .EN(EN),
    .WR(WR),
    .state(state),
    .counter(counter),
    .data_byte(data_byte),
    .send_en(send_en),
    .usedw(usedw),
    .data_to_fifo(data_to_fifo),
    .fifo_out(fifo_out),
    .rdreq(rdreq),
    .wrreq(wrreq),
    .CLK_FIFO(CLK_FIFO)
);


ecc_top my_ecc_inst(
    .DOUT(DOUT[12:0]),
    .DIN(DIN[12:0]),
    .ECC_EN(ECC_EN),
    .DI(DI[7:0]),
    .DO(DO[7:0]),
    .ERR_BIT_ADD(ERR_BIT_ADD[3:0]),
    .ERR_CODE(ERR_CODE[1:0])
    );

uart_byte_tx uart_byte_tx(
    .debug_mode(debug_mode),
    .Clk(CLK),
    .Rst_n(Rst_n),
    .data_byte(data_byte),
    .send_en(send_en),
    .baud_set(3'd4),
    
    .Rs232_Tx(Rs232_Tx),
    .Tx_Done(Tx_Done),
    .uart_state()
);

///////////////////////////////////////////////////////////////output_nn
    always@(negedge CLK_FIFO)
       output_nn<=out_from_mram;

//ila_0 your_instance_name (
//	.clk(CLK_200), // input wire clk


//	.probe0(rdreq), // input wire [0:0]  probe0  
//	.probe1(CLK), // input wire [0:0]  probe1 
//	.probe2(A), // input wire [2:0]  probe2 
//	.probe3(counter), // input wire [2:0]  probe3 
//	.probe4(DQ), // input wire [7:0]  probe4
//	.probe5(dir), // input wire [0:0]  probe5 
//	.probe6(WR), // input wire [0:0]  probe6 
//	.probe7(EN), // input wire [0:0]  probe7 
//	.probe8(Rs232_Tx), // input wire [0:0]  probe8 
//	.probe9(usedw), // input wire [0:0]  probe9
//	.probe10(Wdreq), // input wire [0:0]  probe10 
//	.probe11(OE_D), // input wire [3:0]  probe11 
//	.probe12(OE_OUT), // input wire [3:0]  probe12 
//	.probe13(probe13), // input wire [3:0]  probe13 
//	.probe14(probe14) // input wire [3:0]  probe14
//);
endmodule
