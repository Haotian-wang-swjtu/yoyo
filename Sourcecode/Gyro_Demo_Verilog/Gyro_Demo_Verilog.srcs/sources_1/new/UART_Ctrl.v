`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/28 15:01:24
// Design Name: 
// Module Name: UART_Ctrl
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


module UART_Ctrl(
    input i_clk,
    input i_rst,
    input [30:0]i_baudrate,
    input i_rx,
    input [15:0]i_temperature_data,
    input [15:0]i_anglex_data,
    input [15:0]i_angley_data,
    input [15:0]i_anglez_data,
    input [15:0]i_magx_data,
    input [15:0]i_magy_data,
    input [15:0]i_magz_data,
    output o_tx,
    output [7:0]o_rx_data,
    output o_rx_rq
    );
    localparam ST_IDLE=2'd0;
    localparam ST_START=2'd1;
    localparam ST_END=2'd2;
    
    //时钟信号
    wire clk_package;
    
    //数据信号
    wire en_tx;
    wire [7:0]tx_data;
    wire tx_rq;
    wire ack_package;
    
    //需要发送的数据
    reg [7:0]data_0=0;
    reg [7:0]data_1=0;
    reg [7:0]data_2=0;
    reg [7:0]data_3=0;
    reg [7:0]data_4=0;
    reg [7:0]data_5=0;
    
    //状态信号
    reg package_ok=0;
    
    //使能信号
    reg en_package=0;
    
    //计数
    reg [7:0]num_cnt=0;
    
    //状态
    reg [1:0]state_current=0;
    reg [1:0]state_next=0;
    
    //缓存
    reg [1:0]package_buff=0;
    reg [15:0]temperature_data_i=0;
    reg [15:0]anglex_data_i=0;
    reg [15:0]angley_data_i=0;
    reg [15:0]anglez_data_i=0;
    reg [15:0]magx_data_i=0;
    reg [15:0]magy_data_i=0;
    reg [15:0]magz_data_i=0;
    
    //打包时钟
    clk_division UART_Package_CLK(.i_clk(i_clk),.i_rst(i_rst),.i_clk_mode(31'd10000),.o_clk_out(clk_package));
    
    //状态机
    always@(*)begin
        case(state_current)
            ST_IDLE:begin
                if(package_ok==1'b1)state_next<=ST_START;
                else state_next<=ST_IDLE;
            end
            ST_START:state_next<=ST_END;
            ST_END:begin
                if(en_package==1'b0)state_next<=ST_IDLE;
                else state_next<=ST_END;
            end
            default:state_next<=ST_IDLE;
        endcase
    end
    
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=0;
        end
        else begin
            state_current<=state_next;
        end
    end
    
    //打包信号,时钟可自己调节,数据也可修改
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            en_package<=0;
            num_cnt<=0;
        end else if(state_current==ST_START&num_cnt<8'd2&package_buff==2'b01)begin
            en_package<=1;
            num_cnt<=num_cnt+1;
        end else if(state_current==ST_START&package_buff==2'b01)begin
            en_package<=1;
            num_cnt<=8'd0;
        end else if(package_buff==2'b01)begin
            en_package<=0;
            num_cnt<=num_cnt;
        end else begin
            en_package<=en_package;
            num_cnt<=num_cnt;
        end
    end

    //打包发送数据分配
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            data_0<=8'd0;data_1<=8'd0;
            data_2<=8'd0;data_3<=8'd0;
            data_4<=8'd0;data_5<=8'd0;
        end else if(package_buff==2'b01&num_cnt==8'd0)begin
            {data_0,data_1}<=temperature_data_i;
            data_2<=8'd0;data_3<=8'd0;
            data_4<=8'd0;data_5<=8'd0;
        end else if(package_buff==2'b01&num_cnt==8'd1)begin
            {data_0,data_1}<=anglex_data_i;
            {data_2,data_3}<=angley_data_i;
            {data_4,data_5}<=anglez_data_i;
        end else if(package_buff==2'b01&num_cnt==8'd1)begin
            {data_0,data_1}<=magx_data_i;
            {data_2,data_3}<=magy_data_i;
            {data_4,data_5}<=magz_data_i;
        end else begin
            data_0<=data_0;data_1<=data_1;
            data_2<=data_2;data_3<=data_3;
            data_4<=data_4;data_5<=data_5;
        end
    end
    
    //缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            package_ok<=1'b0;
            package_buff<=2'd0;
        end else begin
            package_ok<=ack_package;
            package_buff<={package_buff[0],clk_package};
        end
    end
    
    //实例化UART
    Driver_UART UART0(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en_rx(1'b1),
        .i_en_tx(en_tx),
        .i_set_baudrate(1'b1),
        .i_baudrate(i_baudrate),
        .i_rx(i_rx),
        .i_tx_data(tx_data),
        .o_tx(o_tx),
        .o_rx_data(o_rx_data),
        .o_rx_rq(o_rx_rq),
        .o_tx_rq(tx_rq)
        );
        
    //打包数据
    UART_Package UART_Package0(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(en_package),
        .i_tx_rq(tx_rq),
        .i_data_num(3'd6),
        .i_head(8'h55),
        .i_num(num_cnt),
        .i_data_1(data_0),
        .i_data_2(data_1),
        .i_data_3(data_2),
        .i_data_4(data_3),
        .i_data_5(data_4),
        .i_data_6(data_5),
        .i_data_7(8'd0),
        .i_data_8(8'd0),
        .i_end(8'haa),
        .o_tx_data(tx_data),
        .o_tx_en(en_tx),
        .o_ack(ack_package)
    );
    
    //输入缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            temperature_data_i<=16'd0;
            anglex_data_i<=16'd0;
            angley_data_i<=16'd0;
            anglez_data_i<=16'd0;
            magx_data_i<=16'd0;
            magy_data_i<=16'd0;
            magz_data_i<=16'd0;
        end else begin
            temperature_data_i<=i_temperature_data;
            anglex_data_i<=i_anglex_data;
            angley_data_i<=i_angley_data;
            anglez_data_i<=i_anglez_data;
            magx_data_i<=i_magx_data;
            magy_data_i<=i_magy_data;
            magz_data_i<=i_magz_data;
        end
    end
endmodule

//发送打包
module UART_Package(
    input i_clk,
    input i_rst,
    input i_en,
    input i_tx_rq,
    input [2:0]i_data_num,
    input [7:0]i_head,
    input [7:0]i_num,
    input [7:0]i_data_1,
    input [7:0]i_data_2,
    input [7:0]i_data_3,
    input [7:0]i_data_4,
    input [7:0]i_data_5,
    input [7:0]i_data_6,
    input [7:0]i_data_7,
    input [7:0]i_data_8,
    input [7:0]i_end,
    output [7:0]o_tx_data,
    output o_tx_en,
    output o_ack
);
    localparam ST_IDLE=3'd0;
    localparam ST_HEAD=3'd1;
    localparam ST_NUM=3'd2;
    localparam ST_START=3'd3;
    localparam ST_END=3'd4;
    
    //时钟
    wire clk_package;
    
    //状态
    reg [2:0]state_current=0;
    reg [2:0]state_next=0;
    
    //缓存
    reg [1:0]en_i=0;
    reg [2:0]data_num_i=0;
    reg [7:0]head_i=0;
    reg [7:0]num_i=0;
    reg [63:0]data_i=0;
    reg [7:0]end_i=0;
    reg [1:0]tx_rq_i=0;
    
    //计数
    reg [2:0]tx_wr_cnt=0;
    reg [63:0]tx_wr_data=0;
    
    //输出
    reg [7:0]tx_data_o=0;
    reg tx_en_o=0;
    reg ack_o=0;
    
    //输出连线
    assign o_tx_data=tx_data_o;
    assign o_tx_en=tx_en_o;
    assign o_ack=ack_o;
    
    //状态机
    always@(*)begin
        case(state_current)
            ST_IDLE:begin
                if(en_i==2'b01)begin
                    state_next<=ST_HEAD;
                end
                else begin
                    state_next<=ST_IDLE;
                end
            end
            ST_HEAD:begin
                if(tx_rq_i==2'b01)state_next<=ST_NUM;
                else state_next<=ST_HEAD;
            end
            ST_NUM:begin
                if(tx_rq_i==2'b01)state_next<=ST_START;
                else state_next<=ST_NUM;
            end
            ST_START:begin
                if(tx_wr_cnt==data_num_i-1&tx_rq_i==2'b01)begin
                    state_next<=ST_END;
                end
                else begin
                    state_next<=ST_START;
                end
            end
            ST_END:begin
                if(tx_rq_i==2'b01)state_next<=ST_IDLE;
                else state_next<=ST_END;
            end
            default:begin
                state_next<=ST_IDLE;
            end
        endcase
    end
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=ST_IDLE;
        end
        else begin
            state_current<=state_next;
        end
    end
    //Tx写使能
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            tx_en_o<=0;
        end
        else if(state_current==ST_IDLE)begin
            tx_en_o<=0;
        end
        else begin
            tx_en_o<=1;
        end
    end
    //数据处理
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            tx_data_o<=0;
        end
        else begin
            case(state_current)
                ST_HEAD:tx_data_o<=head_i;
                ST_NUM:tx_data_o<=num_i;
                ST_START:tx_data_o<=tx_wr_data[7:0];
                ST_END:tx_data_o<=end_i;
                default:tx_data_o<=0;
            endcase
        end
    end
    //写计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            tx_wr_cnt<=0;
            tx_wr_data<=0;
        end
        else if(state_current==ST_START&tx_rq_i==2'b01)begin
            tx_wr_cnt<=tx_wr_cnt+1;
            tx_wr_data<=(tx_wr_data>>8);
        end
        else if(state_current==ST_IDLE)begin
            tx_wr_cnt<=0;
            tx_wr_data<=data_i;
        end
    end
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            ack_o<=0;
        end
        else if(state_current==ST_IDLE)begin
            ack_o<=1;
        end
        else begin
            ack_o<=0;
        end
    end
    //缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            en_i<=0;
            data_num_i<=0;
            head_i<=0;
            num_i<=0;
            data_i<=0;
            end_i<=0;
            tx_rq_i<=0;
        end
        else begin
            en_i<={en_i[0],i_en};
            data_num_i<=i_data_num;
            head_i<=i_head;
            num_i<=i_num;
            data_i[7:0]<=i_data_1;
            data_i[15:8]<=i_data_2;
            data_i[23:16]<=i_data_3;
            data_i[31:24]<=i_data_4;
            data_i[39:32]<=i_data_5;
            data_i[47:40]<=i_data_6;
            data_i[55:48]<=i_data_7;
            data_i[63:56]<=i_data_8;
            end_i<=i_end;
            tx_rq_i<={tx_rq_i[0],i_tx_rq};
        end
    end
endmodule