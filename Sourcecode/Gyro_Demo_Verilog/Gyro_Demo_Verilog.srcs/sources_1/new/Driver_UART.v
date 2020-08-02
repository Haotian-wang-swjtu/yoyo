`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/23 18:36:53
// Design Name: 
// Module Name: Driver_UART
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

//This is the UART driver that contains the send and receive. 
//Where the transmission is enabled on the rising edge and the reception is enabled in the high level.
module Driver_UART(
    input i_clk,
    input i_rst,
    input i_en_rx,
    input i_en_tx,
    input i_set_baudrate,
    input [30:0]i_baudrate,
    input i_rx,
    input [7:0]i_tx_data,
    output o_tx,
    output [7:0]o_rx_data,
    output o_rx_rq,
    output o_tx_rq
    );
    //默认波特率
    parameter Default_BaudRate=9600;
    parameter CLK_Freq_MHZ='d100;
    localparam Default_Factor=CLK_Freq_MHZ*('d1000_000)/Default_BaudRate+1;
    
    //UART clock
    wire clk_UART;
    reg [30:0]clk_mode=Default_Factor;
    
    //缓存
    reg [1:0]set_baudrate_i=0;
    reg [30:0]baudrate_i=Default_BaudRate;
    
    //标志
    reg flg_set_baudrate=0;
   
    //设置波特率
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            clk_mode<=Default_Factor;
        end  
        else if(flg_set_baudrate)begin
            clk_mode<=CLK_Freq_MHZ*('d1000_000)/baudrate_i+1;
        end
        else begin
            clk_mode<=clk_mode;
        end
    end

    //分频得到UART时钟
    clk_division UART_CLK(.i_clk(i_clk),.i_rst(i_rst),.i_clk_mode(clk_mode),.o_clk_out(clk_UART));
    
    UART_Rx UART_Rx0(
        .i_clk(i_clk),              //Clock signal
        .i_clk_UART(clk_UART),      //Clock signal
        .i_rst(i_rst),              //Reset signal, low reset
        .i_en(i_en_rx),             //Enable signal, active high
        .i_rx(i_rx),                //Rx
        .o_data(o_rx_data),         //Receive data output
        .o_ack(o_rx_rq)             //Interrupt signal, whether it is received
    );

    UART_Tx UART_Tx0(
        .i_clk(i_clk),              //Clock signal
        .i_clk_UART(clk_UART),      //Clock signal
        .i_rst(i_rst),              //Reset signal, low reset
        .i_en(i_en_tx),             //Enable signal, valid on rising edge
        .i_data(i_tx_data),         //Data required to be send
        .o_tx(o_tx),                //Tx
        .o_ack(o_tx_rq)             //Interrupt signal, whether it is sent
    );
    
    //上升沿检测
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            flg_set_baudrate<=0;
        end  
        else begin
            flg_set_baudrate<=(set_baudrate_i==2'b01);
        end
    end
    //信号缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            set_baudrate_i<=0;
            baudrate_i<=Default_BaudRate;
        end  
        else begin
            set_baudrate_i<={set_baudrate_i[0],i_set_baudrate};
            baudrate_i<=i_baudrate;
        end
    end
endmodule

//UART receiver module
module UART_Rx(
    input i_clk,                            //Clock signal
    input i_clk_UART,                       //Clock signal
    input i_rst,                            //Reset signal, low reset
    input i_en,                             //Enable signal, active high
    input i_rx,                             //Rx
    output [7:0]o_data,                     //Receive data output
    output o_ack                            //Interrupt signal, whether it is received
);
    localparam ST_IDLE=2'd0;
    localparam ST_START=2'd1;
    localparam ST_END=2'd2;
    
    //状态机
    reg[1:0]state_current=0;
    reg[1:0]state_next=0;
    
    //计数
    reg[2:0]data_cnt=0;
    
    //缓存
    reg [1:0]clk_uart_buff=0;
    reg rx_i=1;
    reg en_i=0;
    
    //输出
    reg [7:0]data_o=0;
    reg ack_o=0;
    
    //输出连线
    assign o_data=data_o;
    assign o_ack=ack_o;
    
    //状态机
    always@(*)begin
        case(state_current)
            ST_IDLE:begin
                ack_o<=0;
                if(rx_i==1'b0&en_i==1'b1)state_next<=ST_START;             //If Rx is pulled low, it enters the receiving state.
                else state_next<=ST_IDLE;
            end
            ST_START:begin
                ack_o<=0;
                if(data_cnt==3'd7)state_next<=ST_END;   //If the data transfer is completed, it enters the end state, there is 1 stop bit,no check digit.
                else state_next<=ST_START; 
            end
            ST_END:begin
                state_next<=ST_IDLE;
                ack_o<=1;
            end
            default:begin
                state_next<=ST_IDLE;
                ack_o<=0;
            end
        endcase
    end
        
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=ST_IDLE;
        end else if(clk_uart_buff==2'b01)begin
            state_current<=state_next;
        end else begin
            state_current<=state_current;
        end
    end
    
    //接收数据
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            data_o<=0;
        end else if(state_current==ST_START&clk_uart_buff==2'b01)begin
            data_o<={rx_i,data_o[7:1]};
        end else begin
            data_o<=data_o;
        end
    end
    
    //接收计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            data_cnt<=0;
        end else if(state_current==ST_START&clk_uart_buff==2'b01)begin
            data_cnt<=data_cnt+1;
        end else if(clk_uart_buff==2'b01)begin
            data_cnt<=0;
        end else begin
            data_cnt<=data_cnt;
        end
    end
    
    //缓存信号
     always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            clk_uart_buff<=2'd0;
            rx_i<=1'b1;
            en_i<=1'b0;
        end else begin
            clk_uart_buff<={clk_uart_buff[0],i_clk_UART};
            rx_i<=i_rx;
            en_i<=i_en;
        end
     end
endmodule

//UART transmit module
module UART_Tx(
    input i_clk,                            //Clock signal
    input i_clk_UART,                       //Clock signal
    input i_rst,                            //Reset signal, low reset
    input i_en,                             //Enable signal, valid on rising edge
    input[7:0]i_data,                       //Data required to be send
    output o_tx,                            //Tx
    output o_ack                            //Interrupt signal, whether it is sent
);
    //UART status parameter
    localparam ST_IDLE=2'd0;
    localparam ST_START=2'd1;
    localparam ST_SEND=2'd2;
    localparam ST_END=2'd3;
    
    //状态
    reg [1:0]state_current=0;
    reg [1:0]state_next=0;

    //计数
    reg [2:0]data_cnt=0;
    
    //缓存
    reg [1:0]clk_uart_buff=0;
    reg en_i=0;
    reg [7:0]data_i=0;
    reg [7:0]send_buffer=0;

    //输出
    reg tx_o=1;
    reg ack_o=0;
    
    //输出连线
    assign o_tx=tx_o;
    assign o_ack=ack_o;
    
    //状态机
    always@(*)begin
        case(state_current)
            ST_IDLE:begin
                ack_o<=0;
                if(en_i)state_next<=ST_START;//如果接收完毕,则进入发送状态
                else state_next<=ST_IDLE;
            end
            ST_START:begin
                ack_o<=0;
                state_next<=ST_SEND;
            end
            ST_SEND:begin
                ack_o<=0;
                if(data_cnt==7)state_next<=ST_END;     //如果数据传输完毕,则进入结尾状态,无校验位,1位停止位
                else state_next<=ST_SEND;
            end
            ST_END:begin
                ack_o<=1;
                state_next<=ST_IDLE; 
            end
        endcase
    end
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=ST_IDLE;
        end else if(clk_uart_buff==2'b01)begin
            state_current<=state_next;
        end else begin
            state_current<=state_current;
        end
    end
    //传输计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            data_cnt<=0;
        end else if(state_current==ST_SEND&clk_uart_buff==2'b01)begin
            data_cnt<=data_cnt+1;
        end else if(clk_uart_buff==2'b01)begin
            data_cnt<=0;
        end else begin
            data_cnt<=data_cnt;
        end
    end
    //数据赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            send_buffer<=0;
        end else if(state_current==ST_START&clk_uart_buff==2'b01)begin
            send_buffer<=data_i;
        end else if(state_current==ST_SEND&clk_uart_buff==2'b01)begin
            send_buffer<={1'b0,send_buffer[7:1]};
        end else if(clk_uart_buff==2'b01)begin
            send_buffer<=0;
        end else begin
            send_buffer<=send_buffer;
        end
    end
    //Tx信号产生
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            tx_o<=1;
        end else if(state_current==ST_START&clk_uart_buff==2'b01)begin
            tx_o<=0;
        end else if(state_current==ST_SEND&clk_uart_buff==2'b01)begin
            tx_o<=send_buffer[0];
        end else if(clk_uart_buff==2'b01)begin
            tx_o<=1;
        end else begin
            tx_o<=tx_o;
        end
    end
    //缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            clk_uart_buff<=2'd0;
            en_i<=1'b0;
            data_i<=1'b0;
        end else begin
            clk_uart_buff<={clk_uart_buff[0],i_clk_UART};
            en_i<=i_en;
            data_i<=i_data;
        end    
    end
endmodule