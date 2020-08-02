`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/19 17:35:25
// Design Name: 
// Module Name: Driver_Gyro
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


module Driver_Gyro(
    input i_clk,
    input i_rst,
    input i_en,
    input i_iic_busy,
    input [2:0]i_data_mode,
    input [7:0]i_data,
    output o_reg_mode,
    output [7:0]o_slave_addr,
    output [7:0]o_reg_addr_h,
    output [7:0]o_reg_addr_l,  
    output [7:0]o_data_w,      
    output [15:0]o_temperature_data,
    output [15:0]o_anglex_data,
    output [15:0]o_angley_data,
    output [15:0]o_anglez_data,
    output [15:0]o_magx_data,
    output [15:0]o_magy_data,
    output [15:0]o_magz_data,
    output o_iic_write,
    output o_iic_read
);
    //地址参数
    localparam DEFAULT_SLAVE_ADDRESS=8'hd6;
    
    //状态参数
    localparam ST_IDLE=3'd0;
    localparam ST_INIT=3'd1;
    localparam ST_WAIT=3'd2;
    localparam ST_TEMP=3'd3;
    localparam ST_ANGLE=3'd4;
    localparam ST_MAG=3'd5;
    
    //初始化数据
    wire [7:0]init_reg_addr_l;
    wire [7:0]init_data_w;
    wire init_ack;
    
    //读陀螺仪模块数据
    wire [7:0]read_reg_addr_l;
    wire [7:0]read_data;
    wire read_ack;
    reg [1:0]read_ack_buff=0;
    
    //读地址
    reg [7:0]read_addr=0;
    
    //使能
    reg en_gyro_init=0;
    reg en_gyro_read=0;
    
    //计数
    reg [1:0]wait_cnt=0;
    reg [2:0]send_cnt=0;
    reg [31:0]delay_cnt=0;
    
    //状态机
    reg [2:0]state_current=0;
    reg [2:0]state_next=0;
    
    //缓存
    reg en_i=0;
    reg [2:0]data_mode_i=0;
    reg [7:0]data_i=0;
    
    //输出
    reg reg_mode_o=0;
    reg [7:0]slave_addr_o=0;
    reg [7:0]reg_addr_h_o=0;
    reg [7:0]reg_addr_l_o=0;
    reg [7:0]data_w_o=0;
    reg [15:0]temperature_data_o=0;
    reg [15:0]anglex_data_o=0;
    reg [15:0]angley_data_o=0;
    reg [15:0]anglez_data_o=0;
    reg [15:0]magx_data_o=0;
    reg [15:0]magy_data_o=0;
    reg [15:0]magz_data_o=0;

    //输出连线
    assign o_reg_mode=reg_mode_o;
    assign o_slave_addr=slave_addr_o;
    assign o_reg_addr_h=reg_addr_h_o;
    assign o_reg_addr_l=reg_addr_l_o;
    assign o_data_w=data_w_o;
    assign o_temperature_data=temperature_data_o;
    assign o_anglex_data=anglex_data_o;
    assign o_angley_data=angley_data_o;
    assign o_anglez_data=anglez_data_o;
    assign o_magx_data=magx_data_o;
    assign o_magy_data=magy_data_o;
    assign o_magz_data=magz_data_o;

    //固定数据输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            reg_mode_o<=1'b0;
            slave_addr_o=8'd0;
            reg_addr_h_o<=8'd0;
        end else begin
            reg_mode_o<=1'b0;
            slave_addr_o=DEFAULT_SLAVE_ADDRESS;
            reg_addr_h_o<=8'd0;
        end
    end

    //读写数据、地址输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            reg_addr_l_o<=8'd0;
            data_w_o<=8'd0;
        end else if(state_current==ST_INIT)begin
            reg_addr_l_o<=init_reg_addr_l;
            data_w_o<=init_data_w;
        end else if(en_i==1'b1)begin
            reg_addr_l_o<=read_reg_addr_l;
            data_w_o<=8'd0;
        end else begin
            reg_addr_l_o<=8'd0;
            data_w_o<=8'd0;
        end
    end
    
    //温度数据解包输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            temperature_data_o<=16'd0;
        end else if(wait_cnt==2'd1&read_ack_buff==2'b01&send_cnt==3'd0)begin
            temperature_data_o<={temperature_data_o[15:8],read_data};
        end else if(wait_cnt==2'd1&read_ack_buff==2'b01)begin
            temperature_data_o<={read_data,temperature_data_o[7:0]};
        end else begin
            temperature_data_o<=temperature_data_o;
        end
    end
    
    //角度数据解包输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            anglex_data_o<=16'd0;
            angley_data_o<=16'd0;
            anglez_data_o<=16'd0;
        end else if(wait_cnt==2'd2&read_ack_buff==2'b01)begin
            case(send_cnt)
                3'd0:anglex_data_o<={anglex_data_o[15:8],read_data};
                3'd1:anglex_data_o<={read_data,anglex_data_o[7:0]};
                3'd2:angley_data_o<={angley_data_o[15:8],read_data};
                3'd3:angley_data_o<={read_data,angley_data_o[7:0]};
                3'd4:anglez_data_o<={anglez_data_o[15:8],read_data};
                3'd5:anglez_data_o<={read_data,anglez_data_o[7:0]};
                default:begin anglex_data_o<=anglex_data_o;angley_data_o<=angley_data_o;anglez_data_o<=anglez_data_o;end
            endcase
        end else begin
            anglex_data_o<=anglex_data_o;
            angley_data_o<=angley_data_o;
            anglez_data_o<=anglez_data_o;
        end
    end
    
    //磁力数据解包输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            magx_data_o<=16'd0;
            magy_data_o<=16'd0;
            magz_data_o<=16'd0;
        end else if(wait_cnt==2'd3&read_ack_buff==2'b01)begin
            case(send_cnt)
                3'd0:magx_data_o<={magx_data_o[15:8],read_data};
                3'd1:magx_data_o<={read_data,magx_data_o[7:0]};
                3'd2:magy_data_o<={magy_data_o[15:8],read_data};
                3'd3:magy_data_o<={read_data,magy_data_o[7:0]};
                3'd4:magz_data_o<={magz_data_o[15:8],read_data};
                3'd5:magz_data_o<={read_data,magz_data_o[7:0]};
                default:begin magx_data_o<=magx_data_o;magy_data_o<=magy_data_o;magz_data_o<=magz_data_o;end
            endcase
        end else begin
            magx_data_o<=magx_data_o;
            magy_data_o<=magy_data_o;
            magz_data_o<=magz_data_o;
        end
    end
    
    //初始化使能
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)en_gyro_init<=1'b0;
        else if(state_current==ST_INIT)en_gyro_init<=1'b1;
        else en_gyro_init<=1'b0;
    end
    
    //读数据使能
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)en_gyro_read<=1'b0;
        else if(state_next>ST_WAIT&read_ack_buff==2'b00)en_gyro_read<=1'b1;
        else en_gyro_read<=1'b0;
    end
    
    //等待计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)wait_cnt<=2'd0;
        else if(state_next==ST_WAIT&wait_cnt<2'd3)wait_cnt<=wait_cnt+1;
        else if(state_next==ST_WAIT&state_current>ST_WAIT)wait_cnt<=2'd1;
        else wait_cnt<=wait_cnt;
    end
    
    //发送计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)send_cnt<=3'd0;
        else if(read_ack_buff==2'b01)send_cnt<=send_cnt+1;
        else if(state_next==ST_WAIT)send_cnt<=3'd0;
        else send_cnt<=send_cnt;
    end
    
    //读地址分配
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            read_addr<=8'd0;
        end else if(wait_cnt==2'd1)begin
            read_addr<=8'h20+send_cnt;
        end else if(wait_cnt==2'd2)begin
            read_addr<=8'h22+send_cnt;
        end else begin
            read_addr<=8'h66+send_cnt;
        end
    end
    
    //延时
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)delay_cnt<=32'd0;
        else if(state_current==ST_IDLE&en_i==1'b1)delay_cnt<=delay_cnt+1;
        else delay_cnt<=32'd0;
    end
    
    //状态机
    always@(*)begin
        case(state_current)
            ST_IDLE:begin
                if(en_i==1'b1&delay_cnt==32'd100_000_000)state_next<=ST_INIT;
                else state_next<=ST_IDLE;
            end
            ST_INIT:begin
                if(init_ack==1'b1)state_next<=ST_WAIT;
                else state_next<=ST_INIT;
            end
            ST_WAIT:begin
                if(data_mode_i[wait_cnt-1]==1'b1&en_i==1'b1)state_next<=wait_cnt+ST_WAIT;
                else state_next<=ST_WAIT;
            end
            ST_TEMP:begin
                if(send_cnt==3'd2&en_i==1'b1)state_next<=ST_WAIT;
                else if(en_i==1'b1)state_next<=ST_TEMP;
                else state_next<=ST_WAIT;
            end
            ST_ANGLE:begin
                if(send_cnt==3'd6&en_i==1'b1)state_next<=ST_WAIT;
                else if(en_i==1'b1)state_next<=ST_ANGLE;
                else state_next<=ST_WAIT;
            end
            ST_MAG:begin
                if(send_cnt==3'd6&en_i==1'b1)state_next<=ST_WAIT;
                else if(en_i==1'b1)state_next<=ST_MAG;
                else state_next<=ST_WAIT;
            end
            default:state_next<=ST_IDLE;
        endcase
    end
    
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=3'd0;
        end else begin
            state_current<=state_next;
        end
    end

    //读取陀螺仪数据
    Gyro_Read_Data Gyro_Read_Data_0(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(en_gyro_read),
        .i_iic_busy(i_iic_busy),
        .i_read_addr(read_addr),
        .i_iic_data(data_i),
        .o_reg_addr_l(read_reg_addr_l),
        .o_read_data(read_data),
        .o_iic_read(o_iic_read),
        .o_read_ack(read_ack)
    );
    
    //初始化陀螺仪
    Gyro_Init Gyro_Init_0(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(en_gyro_init),
        .i_iic_busy(i_iic_busy),
        .o_reg_addr_l(init_reg_addr_l),
        .o_data_w(init_data_w),
        .o_iic_write(o_iic_write),
        .o_init_ack(init_ack)
    );
    
    //输入缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            en_i<=1'b0;
            data_mode_i<=3'd0;
            data_i<=8'd0;
            read_ack_buff<=2'd0;
        end else begin
            en_i<=i_en;
            data_mode_i<=i_data_mode;
            data_i<=i_data;
            read_ack_buff<={read_ack_buff[0],read_ack};
        end
    end
endmodule

//陀螺仪读取数据
module Gyro_Read_Data(
    input i_clk,
    input i_rst,
    input i_en,
    input i_iic_busy,
    input [7:0]i_read_addr,
    input [7:0]i_iic_data,
    output [7:0]o_reg_addr_l,
    output [7:0]o_read_data,
    output o_iic_read,
    output o_read_ack
);
    localparam WR_HOLD_T=4'd10;          //使能保持时间
    localparam WR_VALID=1'b1;            //使能输出有效位
    
    //状态参数
    localparam ST_IDLE=2'd0;
    localparam ST_START=2'd1;
    localparam ST_READ=2'd2;
    localparam ST_END=2'd3;
    
    //时钟
    wire clk_read;
    
    //标志
    reg flg_en=0;
    reg flg_data_ok=0;
    reg flg_iic_ok=1'b1;
    
    //状态
    reg [1:0]state_current=0;
    reg [1:0]state_next=0;
    
    //缓存
    reg [1:0]en_i=0;
    reg [1:0]iic_busy_i=0;
    reg [7:0]read_addr_i=0;
    reg [7:0]iic_data_i=0;
    reg [1:0]clk_read_buff=0;
    
    //输出
    reg [7:0]reg_addr_l_o=0;
    reg [7:0]read_data_o=0;
    reg read_ack_o=0;
    
    //输出连线
    assign o_reg_addr_l=reg_addr_l_o;
    assign o_read_data=read_data_o;
    assign o_read_ack=read_ack_o;
    
    //读时钟
    clk_division read_clock(.i_clk(i_clk),.i_rst(i_rst),.i_clk_mode(31'd10_000),.o_clk_out(clk_read));
    
    //读数据输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)read_data_o<=8'd0;
        else if(state_current==ST_END)read_data_o<=iic_data_i;
        else read_data_o<=read_data_o;
    end
    
    //读地址输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)reg_addr_l_o<=8'd0;
        else if(state_current==ST_START)reg_addr_l_o<=read_addr_i;
        else reg_addr_l_o<=reg_addr_l_o;
    end
    
    //读状态输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)read_ack_o<=1'b0;
        else if(state_current==ST_END)read_ack_o<=1'b1;
        else read_ack_o<=1'b0;
    end
    
    //状态机
    always@(*)begin
        case(state_current)
            ST_IDLE:begin
                if(flg_en==1'b1&flg_iic_ok==1'b1)state_next<=ST_START;
                else state_next<=ST_IDLE;
            end
            ST_START:begin
                if(flg_iic_ok==1'b0)state_next<=ST_READ;
                else state_next<=ST_START;
            end
            ST_READ:begin
                if(flg_iic_ok==1'b1)state_next<=ST_END;
                else state_next<=ST_READ;
            end
            ST_END:state_next<=ST_IDLE;
        endcase
    end
    
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=2'd0;
        end else if(clk_read_buff==2'b01)begin
            state_current<=state_next;
        end else begin
            state_current<=state_current;
        end
    end
    
    //IIC信号检测
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)flg_iic_ok<=1'b1;
        else if(iic_busy_i==2'b00)flg_iic_ok<=1'b1;
        else if(iic_busy_i==2'b01&state_current==ST_START)flg_iic_ok<=1'b0;
        else flg_iic_ok<=flg_iic_ok;
    end
    
    //标志信号
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)flg_data_ok<=1'b0;
        else if(state_current==ST_START)flg_data_ok<=1'b1;
        else if(state_current==ST_READ)flg_data_ok<=1'b0;
        else flg_data_ok<=flg_data_ok;
    end
    
    //信号检测
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)flg_en<=1'b0;
        else if(en_i==2'b01&state_current==ST_IDLE)flg_en<=1'b1;
        else if(state_current==ST_END)flg_en<=1'b0;
        else flg_en<=flg_en;
    end
    
    //读使能信号产生
    Trigger_Generator Trigger_Write(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(flg_data_ok),         //使能信号，上升沿有效
        .i_out_level(WR_VALID),     //控制输出电平
        .i_width(WR_HOLD_T),
        .o_trig(o_iic_read)
    );
    
    //输入缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            en_i<=2'd0;
            iic_busy_i<=2'd0;
            read_addr_i<=8'd0;
            iic_data_i<=8'd0;
            clk_read_buff<=2'd0;
        end else begin
            en_i<={en_i[0],i_en};
            iic_busy_i<={iic_busy_i[0],i_iic_busy};
            read_addr_i<=i_read_addr;
            iic_data_i<=i_iic_data;
            clk_read_buff<={clk_read_buff[0],clk_read};
        end
    end
endmodule

//陀螺仪初始化
module Gyro_Init(
    input i_clk,
    input i_rst,
    input i_en,
    input i_iic_busy,
    output [7:0]o_reg_addr_l,    //寄存器地址,低8位
    output [7:0]o_data_w,        //需要传输的数据
    output o_iic_write,
    output o_init_ack
);
    localparam WR_HOLD_T=4'd10;          //写使能保持时间
    localparam WR_VALID=1'b1;            //写使能输出有效位
    
    //标志
    reg flg_en=0;
    reg flg_data_ok=0;
    
    //计数
    reg [3:0]init_cnt=0;
    
    //缓存
    reg [1:0]en_i=0;
    reg [1:0]iic_busy_i=0;
    
    //输出
    reg [7:0]reg_addr_l_o=0;
    reg [7:0]data_w_o=0;
    reg init_ack_o=0;
    
    //输出连线
    assign o_reg_addr_l=reg_addr_l_o;
    assign o_data_w=data_w_o;
    assign o_init_ack=init_ack_o;
    
    //状态输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)init_ack_o<=1'b0;
        else if(init_cnt==4'd10)init_ack_o<=1'b1;
        else init_ack_o<=1'b0;
    end

    //输出数据
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            reg_addr_l_o<=8'd0;
            data_w_o<=8'd0;
        end
        else if(flg_en==1'b1&iic_busy_i==2'b00)begin
            case(init_cnt)
                4'd0:begin reg_addr_l_o<=8'd10;data_w_o<=8'h70;end//--turn off oled panel
                4'd1:begin reg_addr_l_o<=8'd11;data_w_o<=8'h4c;end//---set low column address
                4'd2:begin reg_addr_l_o<=8'd12;data_w_o<=8'h44;end//---set high column address
                4'd3:begin reg_addr_l_o<=8'd13;data_w_o<=8'h00;end//--set start line address  Set Mapping RAM Display Start Line (0x00~0x3F)
                4'd4:begin reg_addr_l_o<=8'd14;data_w_o<=8'h00;end//--set contrast control register
                4'd5:begin reg_addr_l_o<=8'd15;data_w_o<=8'h00;end// Set SEG Output Current Brightness
                4'd6:begin reg_addr_l_o<=8'd16;data_w_o<=8'h50;end//--Set SEG/Column Mapping   
                4'd7:begin reg_addr_l_o<=8'd17;data_w_o<=8'h85;end//Set COM/Row Scan Direction
                4'd8:begin reg_addr_l_o<=8'd18;data_w_o<=8'h38;end//--set normal display
                4'd9:begin reg_addr_l_o<=8'd19;data_w_o<=8'h38;end//--set multiplex ratio(1 to 64)
                4'd10:begin reg_addr_l_o<=8'd15;data_w_o<=8'h00;end//--1/64 duty
                default:begin reg_addr_l_o<=8'd15;data_w_o<=8'h00;end
            endcase
        end else begin
            reg_addr_l_o<=reg_addr_l_o;
            data_w_o<=data_w_o;
        end
    end
    
    //数据检测
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)flg_data_ok<=1'b0;
        else if(flg_en==1'b1&iic_busy_i==2'b00)flg_data_ok<=1'b1;
        else flg_data_ok<=1'b0;
    end
    
    //发送计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)init_cnt<=4'd0;
        else if(flg_en==1'b1&iic_busy_i==2'b10)init_cnt<=init_cnt+1;
        else if(flg_en==1'b0)init_cnt<=4'd0;
        else init_cnt<=init_cnt;
    end
    
    //信号检测
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)flg_en<=1'b0;
        else if(en_i==2'b01&init_cnt==4'd0)flg_en<=1'b1;
        else if(init_cnt==4'd11)flg_en<=1'b0;
        else flg_en<=flg_en;
    end
    
    //写使能信号产生
    Trigger_Generator Trigger_Write(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(flg_data_ok),         //使能信号，上升沿有效
        .i_out_level(WR_VALID),     //控制输出电平
        .i_width(WR_HOLD_T),
        .o_trig(o_iic_write)
    );
    
    //输入缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            en_i<=2'd0;
            iic_busy_i<=2'd0;
        end else begin
            en_i<={en_i[0],i_en};
            iic_busy_i<={iic_busy_i[0],i_iic_busy};
        end
    end
endmodule