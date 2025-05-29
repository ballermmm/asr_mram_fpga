`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/11 19:21:42
// Design Name: 
// Module Name: state_ctrl
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

module state_ctrl
#(
    parameter   CYCLE_Tw_i    =   6'd20,  //��ʼ��ʱw�׶ε�Taews Twrite Twena
    parameter   CYCLE_Taews   =   6'd4,   //
    parameter   CYCLE_Twrite  =   6'd3,   //
    parameter   CYCLE_Twena   =   6'd2,   //
    parameter   CYCLE_Tpre    =   6'd2,   //
    parameter   CYCLE_Tread   =   6'd4,   //
    parameter   CYCLE_Trona   =   6'd3,   // CYCLE_Trona > 2
    parameter   CYCLE_MUX     =   16'd1000,   //
    parameter   MUX_EN        =   1'd0,
    parameter   data_into_enc = 8'b11111111,    //DI
    parameter   MRAM_addr_minus_one = 15'd16383
)
(
    input wire  CLK,    //�ⲿ�����񣩲�����50MHz
    input wire  CLK_200,
    input wire  key_down,
    input wire  key_down2,
    input wire  Rst_n,
    input wire  [3:0] ERR_BIT_ADD,
    input wire  [1:0] ERR_CODE,
    input wire  [7:0] DO,//DO��ECC on/offʱ������dec��MRAM���ֱ�Я�������?/����ǰ����Ϣ
    input wire  Tx_Done,
    input wire  rd_trigger,

    output reg  MUX_EN_WIRE,
    output reg  [7:0] DI,   //����д���ݣ�����ECC
//    output reg  [13:0] A,
    output reg  W_CLK,
    output reg  R_CLK,
    output reg  EN,
    output reg  WR,
    output reg  [3:0]state, // ״̬��״̬����
    output reg  [15:0]counter,
    output wire [7:0]data_byte,
    output reg  send_en,
    output wire [13:0]usedw,
    output wire [13:0]data_to_fifo,
    output wire [13:0]  fifo_out,
    output reg  rdreq,
    output reg  wrreq,
    output wire CLK_FIFO
);
    parameter   STATE_idle          = 4'd0;
    parameter   STATE_Taews_i       = 4'd1;//��ʼ������MARMд��data_into_enc�ķ�
    parameter   STATE_Twrite_i      = 4'd2;//��ʼ������MARMд��data_into_enc�ķ�
    parameter   STATE_Twena_i       = 4'd3;//��ʼ������MARMд��data_into_enc�ķ�
    parameter   STATE_after_Wbar    = 4'd4;
    parameter   STATE_Taews         = 4'd5;
    parameter   STATE_Twrite        = 4'd6;
    parameter   STATE_Twena         = 4'd7;
    parameter   STATE_read_init     = 4'd8;
    parameter   STATE_Tpre          = 4'd9;
    parameter   STATE_Tread         = 4'd10;
    parameter   STATE_Trona         = 4'd11;
    parameter   STATE_uart_init     = 4'd12;
    parameter   STATE_uart_tx       = 4'd13;
    parameter   STATE_MUX_ALL       = 4'd14;
    parameter   STATE_MUX_ONE       = 4'd15;
//  inner reg
    reg         uart_send_ecc_bit;
    reg         R_CLK_delay;
    reg         send_en_early;
    reg         CLK_FIFO_w;
    reg         rdreq_init;
    reg         uart_2rd;
    
    reg         [0:255] w1 =256'b0010011110100011110100000101010010011111000001110011010101101010100011001100111000111110000010000000100011100000110101111101011111000001111011100111110100100110110101100000100110001011011011110011101000001111010101111000101000001100000011010001111100111100;
    reg         [0:255] w0 =256'b1011111011000011100100000101100000000100110110010100111110110101000110100010100001011110110010000100101001101011010000101010011010010001101010001000111101110000110111001101010100001011011100111001011001001110100111110000111011101111101101010000100011111001;
     //weight  
//  inner wire
    //wire        CLK_FIFO;
    wire        empty;
    wire        Tx_All_Done;
   
   wire         [9:0]index_d0;
   wire         [9:0]index_d1;
    assign      data_to_fifo = // 
    //{4'b1111, 2'b00, 8'b00000000};
    {ERR_BIT_ADD, ERR_CODE, DO};

    assign      data_byte = //
    //(uart_send_ecc_bit ? 8'b10101010 : fifo_out[7:0]);
    (uart_send_ecc_bit ? {fifo_out[13:10], 2'b00, fifo_out[9:8]} : fifo_out[7:0]);
    
    assign      CLK_FIFO = WR ? CLK_FIFO_w : CLK;
    assign      Tx_All_Done = Tx_Done & uart_send_ecc_bit & empty;
//    assign      index_d0=(A<<1);
//    assign      index_d1=(A<<1)+1;
///////////////////////////////////////////////////////////////
//fifo    fifo_inst (
//    .clock ( CLK_FIFO ),
//    .data ( data_to_fifo ),
//    .rdreq ( rdreq ),
//    .sclr ( !Rst_n ),
//    .wrreq ( wrreq ),
//    .almost_empty(),
//    .empty ( empty ),
//    .full (  ),
//    .q ( fifo_out ),
//    .usedw ( usedw )
//    );
//fifo_generator_0 your_instance_name (
//  .clk(CLK_FIFO),                  // input wire clk
//  .srst(!Rst_n),                // input wire srst
//  .din(data_to_fifo ),                  // input wire [7 : 0] din
//  .wr_en(wrreq),              // input wire wr_en
//  .rd_en(rdreq),              // input wire rd_en
//  .dout( fifo_out ),                // output wire [7 : 0] dout
//  .full(),                // output wire full
//  .data_count(usedw), 
//  .empty(empty),              // output wire empty
//  .wr_rst_busy(),  // output wire wr_rst_busy
//  .rd_rst_busy()  // output wire rd_rst_busy
//);

/////////////////////////////////////////////////////////state
    always @ (posedge CLK_200 or negedge Rst_n) 
        if (!Rst_n) state <= STATE_idle;
        else begin
        case (state)
//wait for key_down
            STATE_idle:
                  if(rd_trigger)                  state <= STATE_Tpre;
//                if(key_down & MUX_EN)           state <= STATE_MUX_ALL;
//                else if(key_down & (!MUX_EN))   state <= STATE_Taews_i;//STATE_read_init;//STATE_Taews;//
//                else if(key_down2)              state <= STATE_MUX_ONE;
                else state <= state;
//            STATE_Taews_i:
//                if(counter < CYCLE_Tw_i - 1'b1) state <= state;
//                else state <= STATE_Twrite_i;
//            STATE_Twrite_i:
//                if(counter < CYCLE_Tw_i - 1'b1) state <= state;
//                else state <= STATE_Twena_i;
//            STATE_Twena_i:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_Tw_i - 1'b1 == counter)) //Write next A
//                    state <= STATE_Taews_i;
//                else if ((MRAM_addr_minus_one == A) & (CYCLE_Tw_i - 1'b1 == counter))//All write finished
//                    state <= STATE_after_Wbar;
//                else state <= state;    //hold on
//            STATE_after_Wbar:
//                state <= STATE_Taews;
//wait for key_down
               // if(key_down) state <= STATE_Taews;
               // else state <= state;
//            STATE_Taews:
//                if(counter < CYCLE_Taews - 1'b1) state <= state;
//                else state <= STATE_Twrite;
//            STATE_Twrite:
//                if(counter < CYCLE_Twrite - 1'b1) state <= state;
//                else state <= STATE_Twena;
//            STATE_Twena:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_Twena - 1'b1 == counter)) //Write next A
//                    state <= STATE_Taews;
//                else if ((MRAM_addr_minus_one == A) & (CYCLE_Twena - 1'b1 == counter))//All write finished
//                    state <= STATE_read_init;
//                else state <= state;    //hold on
//            STATE_read_init:
//                state <= STATE_Tpre;
//wait for key_down
                //if(key_down) state <= STATE_Tpre;
                //else state <= state;
            STATE_Tpre:
                if(counter < CYCLE_Tpre - 1'b1) state <= state;
                else state <= STATE_Tread;
            STATE_Tread:
                if(counter < CYCLE_Tread - 1'b1) state <= state;
                else state <= STATE_Trona;
            STATE_Trona:
                  if  (CYCLE_Trona - 1'b1 == counter)
                        state <= STATE_idle;
                  else state <= state;    //hold on
//                if ((MRAM_addr_minus_one == A) & (CYCLE_Trona - 1'b1 == counter))//All read finished
//                    state <= STATE_uart_init;
//                else if ((MRAM_addr_minus_one > A) & (CYCLE_Trona - 1'b1 == counter)) //Read next A
//                    state <= STATE_Tpre;

//            STATE_uart_init:
//                state <= STATE_uart_tx;
//            STATE_uart_tx:
////jump back to read again
//                //if (Tx_All_Done & uart_2rd) state <= STATE_idle;
//                //else if (Tx_All_Done & (!uart_2rd)) state <= STATE_read_init;
//                if (Tx_All_Done) state <= STATE_idle;
//                else state <= state;
//            STATE_MUX_ALL:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_MUX - 1'b1 == counter)) //Write next A
//                    state <= state;
//                else if ((MRAM_addr_minus_one == A) & (CYCLE_MUX - 1'b1 == counter))//All write finished
//                    state <= STATE_idle;
//                else state <= state;    //hold on
//            STATE_MUX_ONE:
//                if(key_down) state <= STATE_idle;
//                else state <= state;
            default:
                state <= STATE_idle;
        endcase
    end

///////////////////////////////////////////////////////////////counter
    always @ ( posedge CLK_200)
        case (state)
            STATE_Taews_i:  counter <= ((counter < CYCLE_Tw_i  - 1'b1)?(counter +1'b1):(0));
            STATE_Twrite_i: counter <= ((counter < CYCLE_Tw_i  - 1'b1)?(counter +1'b1):(0));
            STATE_Twena_i:  counter <= ((counter < CYCLE_Tw_i  - 1'b1)?(counter +1'b1):(0));
            STATE_Taews:    counter <= ((counter < CYCLE_Taews - 1'b1)?(counter +1'b1):(0));
            STATE_Twrite:   counter <= ((counter < CYCLE_Twrite- 1'b1)?(counter +1'b1):(0));
            STATE_Twena:    counter <= ((counter < CYCLE_Twena - 1'b1)?(counter +1'b1):(0));
            STATE_Tpre:     counter <= ((counter < CYCLE_Tpre  - 1'b1)?(counter +1'b1):(0));
            STATE_Tread:    counter <= ((counter < CYCLE_Tread - 1'b1)?(counter +1'b1):(0));
            STATE_Trona:    counter <= ((counter < CYCLE_Trona - 1'b1)?(counter +1'b1):(0));
            STATE_MUX_ALL:  counter <= ((counter < CYCLE_MUX   - 1'b1)?(counter +1'b1):(0));
            default:
                counter <= 0;
        endcase

/////////////////////////////////////////////////////////////////A
//    always @ ( posedge CLK_200)
//        case (state)
//            STATE_Taews_i, STATE_Twrite_i, STATE_Taews, STATE_Twrite, STATE_Tpre, STATE_Tread:
//                ;
//            STATE_Twena_i:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_Tw_i - 1'b1 == counter))       A <= A + 1'b1;
//            STATE_Twena:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_Twena - 1'b1 == counter))       A <= A + 1'b1;
//            STATE_Trona:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_Trona - 1'b1 == counter))       A <= A + 1'b1;
//            STATE_MUX_ALL:
//                if ((MRAM_addr_minus_one > A) & (CYCLE_MUX - 1'b1 == counter))       A <= A + 1'b1;
//            STATE_MUX_ONE:
//								A <= 14'd1950;
//						default:
//                A <= 0;
//        endcase

///////////////////////////////////////////////////////////////EN
    always @ ( posedge CLK_200)
        case (state)
            STATE_Taews_i, STATE_Twrite_i, STATE_Taews, STATE_Twrite, STATE_Tpre, STATE_Tread, STATE_Trona, STATE_uart_init, STATE_MUX_ONE:
                EN <= 1'b1;
//            STATE_Twena_i:
//                EN <= ((CYCLE_Tw_i-1'b1 == counter)&&(MRAM_addr_minus_one == A)) ? 0 : 1'b1;
//            STATE_Twena:
//                EN <= ((CYCLE_Twena-1'b1 == counter)&&(MRAM_addr_minus_one == A)) ? 0 : 1'b1;
            default:
                EN <= 0;
        endcase

///////////////////////////////////////////////////////////////WR
    always @ ( posedge CLK_200)
//        case (state)
//            STATE_idle, STATE_read_init, STATE_Tpre, STATE_Tread, STATE_Trona, STATE_MUX_ALL, STATE_MUX_ONE:
//                WR <= 1'b1;
//            default:
                WR <= 1'b1;//1'b1;//
//        endcase
   
///////////////////////////////////////////////////////////////W_CLK
    always @ ( posedge CLK_200)
//        case (state)
//            STATE_Twrite_i, STATE_Twrite, STATE_read_init, STATE_Tpre, STATE_Tread, STATE_Trona:
                W_CLK <= 1'b1;
//            default:
//                W_CLK <= 0;
//        endcase

///////////////////////////////////////////////////////////////R_CLK
    always @ ( posedge CLK_200)
        case (state)
            STATE_Tread:
                R_CLK <= 1'b1;
            default:
                R_CLK <= 0;
        endcase

///////////////////////////////////////////////////////////////DI - 8b data to enc
    always @ ( posedge CLK_200)
        case (state)
//            STATE_Taews_i, STATE_Twrite_i, STATE_Twena_i:
//                DI <= {w1[A],w0[A]}; //~A[7:0];//{8{A[0]}}; ////8'b1111_1110;//8'h01;//~{7'd0, {A[0]}  };//{~{7{A[0]}}, {1{A[0]}}};  // ~data_into_enc; //��ʼ��ʱ��д�밴λȡ��������
//            STATE_Taews, STATE_Twrite, STATE_Twena:
//                DI <={w1[A],w0[A]}; //~{8{A[0]}};    // w[A];//;//8'b1111_1110;//8'h01;//{7'd0, {A[0]}  };//{{5{A[0]}}, ~{3{A[0]}}};//data_into_enc; // A[7:0]; //
            default:
                DI <= 0;
        endcase

///////////////////////////////////////////////////////////////CLK_FIFO_w
    always@(posedge CLK_200)
        if(STATE_Trona == state & CYCLE_Trona-2'd2 == counter)
        //if(STATE_Tpre == state & CYCLE_Tpre-2'd2 == counter)
            CLK_FIFO_w <= 1'b1;
        else
            CLK_FIFO_w <= 0;

///////////////////////////////////////////////////////////////wrreq
//always @ ( posedge CLK_200)
//    case(state)
//        STATE_read_init, STATE_Tpre, STATE_Tread:
//            wrreq <= 1'b1;
//        STATE_Trona:
//            if(MRAM_addr_minus_one == A & counter > CYCLE_Trona - 2'd2) wrreq <= 0;
//            else wrreq <= 1'b1;
//        default:
//            wrreq <= 0;
//    endcase

///////////////////////////////////////////////////////////////rdreq_init
    always @ ( posedge CLK)
        if (STATE_uart_tx == state) rdreq_init <= 1'b1;
        else rdreq_init <= 0;
///////////////////////////////////////////////////////////////rdreq
    always @ ( posedge CLK)
        //1st rdreq
        if (STATE_uart_tx == state && (~rdreq_init))
            rdreq <= 1'b1;
        //following rdreq
        else if(STATE_uart_tx == state && Tx_Done && uart_send_ecc_bit && !empty)
            rdreq <= 1'b1;
        else rdreq <= 0;

///////////////////////////////////////////////////////////////send_en_early
    always@(posedge CLK)
        if((STATE_uart_tx == state && rdreq)|(Tx_Done & (~uart_send_ecc_bit)))
            send_en_early <= 1;
        else send_en_early <= 0;

///////////////////////////////////////////////////////////////send_en
    always@(posedge CLK)
        send_en <= send_en_early;

///////////////////////////////////////////////////////////////uart_send_ecc_bit
    always @ ( posedge CLK)
        case (state)
            STATE_uart_tx:
                if(Tx_Done) uart_send_ecc_bit = !uart_send_ecc_bit;
            default:
                uart_send_ecc_bit <= 0;
        endcase

///////////////////////////////////////////////////////////////uart_2rd
    always @ ( posedge CLK)
            case (state)
                    STATE_read_init, STATE_Tpre, STATE_Tread, STATE_Trona, STATE_uart_init, STATE_uart_tx:
                            if(Tx_All_Done) uart_2rd <= ~uart_2rd;
                            else uart_2rd <= uart_2rd;
                    default:
                            uart_2rd <= 0;
            endcase

///////////////////////////////////////////////////////////////MUX_EN_WIRE
    always @ ( posedge CLK)
            case (state)
                    STATE_idle:
                        MUX_EN_WIRE <= 1;
                    default:
                        MUX_EN_WIRE <= 0;
            endcase
            
 ///////////////////////////////////////////////////////////////w
//    always @ ( posedge EN)  
//        begin
//            w[0]<=2'b01;
//            w[1]<=2'b00;
//            w[2]<=2'b11;
//            w[3]<=2'b01;
//            w[4]<=2'b01;
//            w[5]<=2'b11;
//            w[6]<=2'b11;
//            w[7]<=2'b10;
//            w[8]<=2'b11;
//            w[9]<=2'b01;
//            w[10]<=2'b10;
//            w[11]<=2'b00;
//            w[12]<=2'b00;
//            w[13]<=2'b00;
//            w[14]<=2'b11;
//            w[15]<=2'b11;
//            w[16]<=2'b11;
//            w[17]<=2'b10;
//            w[18]<=2'b00;
//            w[19]<=2'b11;
//            w[20]<=2'b00;
//            w[21]<=2'b00;
//            w[22]<=2'b00;
//            w[23]<=2'b00;
//            w[24]<=2'b00;
//            w[25]<=2'b11;
//            w[26]<=2'b00;
//            w[27]<=2'b11;
//            w[28]<=2'b01;
//            w[29]<=2'b10;
//            w[30]<=2'b00;
//            w[31]<=2'b00;
//            w[32]<=2'b10;
//            w[33]<=2'b00;
//            w[34]<=2'b00;
//            w[35]<=2'b10;
//            w[36]<=2'b10;
//            w[37]<=2'b11;
//            w[38]<=2'b10;
//            w[39]<=2'b10;
//            w[40]<=2'b01;
//            w[41]<=2'b01;
//            w[42]<=2'b00;
//            w[43]<=2'b01;
//            w[44]<=2'b01;
//            w[45]<=2'b10;
//            w[46]<=2'b10;
//            w[47]<=2'b11;
//            w[48]<=2'b00;
//            w[49]<=2'b01;
//            w[50]<=2'b10;
//            w[51]<=2'b10;
//            w[52]<=2'b01;
//            w[53]<=2'b11;
//            w[54]<=2'b01;
//            w[55]<=2'b11;
//            w[56]<=2'b01;
//            w[57]<=2'b10;
//            w[58]<=2'b11;
//            w[59]<=2'b01;
//            w[60]<=2'b10;
//            w[61]<=2'b01;
//            w[62]<=2'b10;
//            w[63]<=2'b01;
//            w[64]<=2'b10;
//            w[65]<=2'b00;
//            w[66]<=2'b00;
//            w[67]<=2'b01;
//            w[68]<=2'b11;
//            w[69]<=2'b10;
//            w[70]<=2'b01;
//            w[71]<=2'b00;
//            w[72]<=2'b10;
//            w[73]<=2'b10;
//            w[74]<=2'b01;
//            w[75]<=2'b00;
//            w[76]<=2'b11;
//            w[77]<=2'b10;
//            w[78]<=2'b10;
//            w[79]<=2'b00;
//            w[80]<=2'b00;
//            w[81]<=2'b01;
//            w[82]<=2'b10;
//            w[83]<=2'b11;
//            w[84]<=2'b11;
//            w[85]<=2'b11;
//            w[86]<=2'b11;
//            w[87]<=2'b00;
//            w[88]<=2'b01;
//            w[89]<=2'b01;
//            w[90]<=2'b00;
//            w[91]<=2'b00;
//            w[92]<=2'b11;
//            w[93]<=2'b00;
//            w[94]<=2'b00;
//            w[95]<=2'b00;
//            w[96]<=2'b00;
//            w[97]<=2'b01;
//            w[98]<=2'b00;
//            w[99]<=2'b00;
//            w[100]<=2'b11;
//            w[101]<=2'b00;
//            w[102]<=2'b01;
//            w[103]<=2'b00;
//            w[104]<=2'b10;
//            w[105]<=2'b11;
//            w[106]<=2'b11;
//            w[107]<=2'b00;
//            w[108]<=2'b01;
//            w[109]<=2'b00;
//            w[110]<=2'b01;
//            w[111]<=2'b01;
//            w[112]<=2'b10;
//            w[113]<=2'b11;
//            w[114]<=2'b00;
//            w[115]<=2'b10;
//            w[116]<=2'b00;
//            w[117]<=2'b10;
//            w[118]<=2'b11;
//            w[119]<=2'b10;
//            w[120]<=2'b11;
//            w[121]<=2'b10;
//            w[122]<=2'b01;
//            w[123]<=2'b10;
//            w[124]<=2'b00;
//            w[125]<=2'b11;
//            w[126]<=2'b11;
//            w[127]<=2'b10;
//            w[128]<=2'b11;
//            w[129]<=2'b10;
//            w[130]<=2'b00;
//            w[131]<=2'b01;
//            w[132]<=2'b00;
//            w[133]<=2'b00;
//            w[134]<=2'b00;
//            w[135]<=2'b11;
//            w[136]<=2'b11;
//            w[137]<=2'b10;
//            w[138]<=2'b11;
//            w[139]<=2'b00;
//            w[140]<=2'b11;
//            w[141]<=2'b10;
//            w[142]<=2'b10;
//            w[143]<=2'b00;
//            w[144]<=2'b01;
//            w[145]<=2'b10;
//            w[146]<=2'b10;
//            w[147]<=2'b10;
//            w[148]<=2'b11;
//            w[149]<=2'b11;
//            w[150]<=2'b01;
//            w[151]<=2'b11;
//            w[152]<=2'b00;
//            w[153]<=2'b01;
//            w[154]<=2'b11;
//            w[155]<=2'b01;
//            w[156]<=2'b00;
//            w[157]<=2'b10;
//            w[158]<=2'b10;
//            w[159]<=2'b00;
//            w[160]<=2'b11;
//            w[161]<=2'b11;
//            w[162]<=2'b00;
//            w[163]<=2'b11;
//            w[164]<=2'b01;
//            w[165]<=2'b11;
//            w[166]<=2'b10;
//            w[167]<=2'b00;
//            w[168]<=2'b01;
//            w[169]<=2'b01;
//            w[170]<=2'b00;
//            w[171]<=2'b01;
//            w[172]<=2'b10;
//            w[173]<=2'b01;
//            w[174]<=2'b00;
//            w[175]<=2'b11;
//            w[176]<=2'b10;
//            w[177]<=2'b00;
//            w[178]<=2'b00;
//            w[179]<=2'b00;
//            w[180]<=2'b11;
//            w[181]<=2'b00;
//            w[182]<=2'b11;
//            w[183]<=2'b11;
//            w[184]<=2'b00;
//            w[185]<=2'b11;
//            w[186]<=2'b11;
//            w[187]<=2'b01;
//            w[188]<=2'b10;
//            w[189]<=2'b10;
//            w[190]<=2'b11;
//            w[191]<=2'b11;
//           /* w[192]<=2'b01;
//            w[193]<=2'b00;
//            w[194]<=2'b10;
//            w[195]<=2'b11;
//            w[196]<=2'b10;
//            w[197]<=2'b01;
//            w[198]<=2'b11;
//            w[199]<=2'b00;
//            w[200]<=2'b00;
//            w[201]<=2'b01;
//            w[202]<=2'b00;
//            w[203]<=2'b00;
//            w[204]<=2'b11;
//            w[205]<=2'b11;
//            w[206]<=2'b11;
//            w[207]<=2'b10;
//            w[208]<=2'b01;
//            w[209]<=2'b10;
//            w[210]<=2'b00;
//            w[211]<=2'b11;
//            w[212]<=2'b01;
//            w[213]<=2'b11;
//            w[214]<=2'b11;
//            w[215]<=2'b11;
//            w[216]<=2'b10;
//            w[217]<=2'b00;
//            w[218]<=2'b00;
//            w[219]<=2'b00;
//            w[220]<=2'b11;
//            w[221]<=2'b01;
//            w[222]<=2'b11;
//            w[223]<=2'b00;
//            w[224]<=2'b01;
//            w[225]<=2'b01;
//            w[226]<=2'b01;
//            w[227]<=2'b00;
//            w[228]<=2'b11;
//            w[229]<=2'b11;
//            w[230]<=2'b01;
//            w[231]<=2'b01;
//            w[232]<=2'b01;
//            w[233]<=2'b00;
//            w[234]<=2'b01;
//            w[235]<=2'b01;
//            w[236]<=2'b10;
//            w[237]<=2'b11;
//            w[238]<=2'b00;
//            w[239]<=2'b11;
//            w[240]<=2'b00;
//            w[241]<=2'b00;
//            w[242]<=2'b00;
//            w[243]<=2'b10;
//            w[244]<=2'b11;
//            w[245]<=2'b10;
//            w[246]<=2'b10;
//            w[247]<=2'b10;
//            w[248]<=2'b01;
//            w[249]<=2'b01;
//            w[250]<=2'b11;
//            w[251]<=2'b11;
//            w[252]<=2'b11;
//            w[253]<=2'b10;
//            w[254]<=2'b00;
//            w[255]<=2'b01;*/
//        end
   
   
   
endmodule
