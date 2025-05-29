`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:12:42
// Design Name: 
// Module Name: key_filter
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


module key_filter(
			Clk,      //50Mʱ������
			Rst_n,    //ģ�鸴λ
			key_in,   //��������
			key_flag, //������־�ź�
			key_state //����״̬�ź�
		);

	input Clk;
	input Rst_n;
	input key_in;
	
	output reg key_flag;
	output reg key_state;
	
	localparam
		IDLE		= 4'b0001,
		FILTER0		= 4'b0010,
		DOWN		= 4'b0100,
		FILTER1 	= 4'b1000;
		
	reg [3:0]state;
	reg [19:0]cnt;
	reg en_cnt;	//ʹ�ܼ����Ĵ���
	
//���ⲿ������첽�źŽ���ͬ������
	reg key_in_sa,key_in_sb;
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		key_in_sa <= 1'b0;
		key_in_sb <= 1'b0;
	end
	else begin
		key_in_sa <= key_in;
		key_in_sb <= key_in_sa;	
	end
	
	reg key_tmpa,key_tmpb;
	wire pedge,nedge;
	reg cnt_full;//��������־�ź�
	
//ʹ��D�������洢��������ʱ��������ʱ�ⲿ�����źţ��Ѿ�ͬ����ϵͳʱ�����У��ĵ�ƽ״̬
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		key_tmpa <= 1'b0;
		key_tmpb <= 1'b0;
	end
	else begin
		key_tmpa <= key_in_sb;
		key_tmpb <= key_tmpa;	
	end

//�����������ź�	
	assign nedge = !key_tmpa & key_tmpb;
	assign pedge = key_tmpa & (!key_tmpb);
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		en_cnt <= 1'b0;
		state <= IDLE;
		key_flag <= 1'b0;
		key_state <= 1'b1;
	end
	else begin
		case(state)
			IDLE :
				begin
					key_flag <= 1'b0;
					if(nedge)begin
						state <= FILTER0;
						en_cnt <= 1'b1;
					end
					else
						state <= IDLE;
				end
					
			FILTER0:
				if(cnt_full)begin
					key_flag <= 1'b1;
					key_state <= 1'b0;
					en_cnt <= 1'b0;
					state <= DOWN;
				end
				else if(pedge)begin
					state <= IDLE;
					en_cnt <= 1'b0;
				end
				else
					state <= FILTER0;
					
			DOWN:
				begin
					key_flag <= 1'b0;
					if(pedge)begin
						state <= FILTER1;
						en_cnt <= 1'b1;
					end
					else
						state <= DOWN;
				end
			
			FILTER1:
				if(cnt_full)begin
					key_flag <= 1'b1;
					key_state <= 1'b1;
					state <= IDLE;
					en_cnt <= 1'b0;
				end
				else if(nedge)begin
					en_cnt <= 1'b0;
					state <= DOWN;
				end
				else
					state <= FILTER1;
			
			default:
				begin 
					state <= IDLE; 
					en_cnt <= 1'b0;		
					key_flag <= 1'b0;
					key_state <= 1'b1;
				end
				
		endcase	
	end
	

	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		cnt <= 20'd0;
	else if(en_cnt)
		cnt <= cnt + 1'b1;
	else
		cnt <= 20'd0;
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		cnt_full <= 1'b0;
	//else if(cnt == 20'd9)//for debug
	else if(cnt == 20'd999_999)
		cnt_full <= 1'b1;
	else
		cnt_full <= 1'b0;	
endmodule
