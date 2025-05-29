`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:18:50
// Design Name: 
// Module Name: uart_byte_tx
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


module uart_byte_tx(
	debug_mode,
	Clk,       //50Mʱ������
	Rst_n,     //ģ�鸴λ
	data_byte, //������8bit����
	send_en,   //����ʹ��
	baud_set,  //����������
	
	Rs232_Tx,  //Rs232����ź�
	Tx_Done,   //һ�η���������ɱ�־
	uart_state //��������״̬
);
	input debug_mode;
	input Clk;
	input Rst_n;
	input [7:0]data_byte;
	input send_en;
	input [2:0]baud_set;
	
	output reg Rs232_Tx;
	output reg Tx_Done;
	output reg uart_state;
	
	reg bps_clk;	//������ʱ��
	
	reg [15:0]div_cnt;//��Ƶ������
	
	reg [15:0]bps_DR;//��Ƶ�������ֵ
	
	reg [3:0]bps_cnt;//������ʱ�Ӽ�����
	
	reg [7:0]r_data_byte;
	
	localparam START_BIT = 1'b0;
	localparam STOP_BIT = 1'b1;
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		uart_state <= 1'b0;
	else if(send_en)
		uart_state <= 1'b1;
	else if(bps_cnt == 4'd11)
		uart_state <= 1'b0;
	else
		uart_state <= uart_state;
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		r_data_byte <= 8'd0;
	else if(send_en)
		r_data_byte <= data_byte;
	else
		r_data_byte <= r_data_byte;
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		bps_DR <= 16'd5207;
	else begin
		case(baud_set)
			0:bps_DR <= 16'd5207;	//9600
			1:bps_DR <= 16'd2603;
			2:bps_DR <= 16'd1301;
			3:bps_DR <= 16'd867;
			4:bps_DR <= debug_mode ? 16'd5 : 16'd433;	//115200
			default:bps_DR <= 16'd5207;			
		endcase
	end	
	
	//counter
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		div_cnt <= 16'd0;
	else if(uart_state)begin
		if(div_cnt == bps_DR)
			div_cnt <= 16'd0;
		else
			div_cnt <= div_cnt + 1'b1;
	end
	else
		div_cnt <= 16'd0;
	
	// bps_clk gen
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		bps_clk <= 1'b0;
	else if(div_cnt == 16'd1)
		bps_clk <= 1'b1;
	else
		bps_clk <= 1'b0;
	
	//bps counter
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)	
		bps_cnt <= 4'd0;
	else if(bps_cnt == 4'd11)
		bps_cnt <= 4'd0;
	else if(bps_clk)
		bps_cnt <= bps_cnt + 1'b1;
	else
		bps_cnt <= bps_cnt;
		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Tx_Done <= 1'b0;
	else if(bps_cnt == 4'd11)
		Tx_Done <= 1'b1;
	else
		Tx_Done <= 1'b0;
		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Rs232_Tx <= 1'b1;
	else begin
		case(bps_cnt)
			0:Rs232_Tx <= 1'b1;
			1:Rs232_Tx <= START_BIT;
			2:Rs232_Tx <= r_data_byte[0];
			3:Rs232_Tx <= r_data_byte[1];
			4:Rs232_Tx <= r_data_byte[2];
			5:Rs232_Tx <= r_data_byte[3];
			6:Rs232_Tx <= r_data_byte[4];
			7:Rs232_Tx <= r_data_byte[5];
			8:Rs232_Tx <= r_data_byte[6];
			9:Rs232_Tx <= r_data_byte[7];
			10:Rs232_Tx <= STOP_BIT;
			default:Rs232_Tx <= 1'b1;
		endcase
	end	

endmodule

