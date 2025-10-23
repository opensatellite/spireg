`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/11 01:52:59
// Design Name: 
// Module Name: spireg
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


module spireg #(
    parameter ADDR_W = 6,   //1~6
    parameter REG_W = 16    //8, 16, 24, 32, ..., 64
) (
    input clk,
    input nrst,
    input mosi,
    output miso,
    input sclk,
    input nss,
    output [ADDR_W-1:0] reg_addr,
    input [REG_W-1:0] reg_data_i,
    output [REG_W-1:0] reg_data_o,
    output reg reg_data_o_vld,
    input [7:0] status,
    output [5:0] fastcmd,
    output reg fastcmd_vld
);

(* ASYNC_REG = "TRUE" *) reg mosi1, mosi2;
(* ASYNC_REG = "TRUE" *) reg sclk1, sclk2, sclk3;
(* ASYNC_REG = "TRUE" *) reg nss1, nss2, nss3;

reg [REG_W-2:0] mosi_sr;
wire [REG_W-1:0] isr; 
reg [REG_W-1:0] osr;
reg [7:0] cmd;  //00_xxxxxx = read, 10_xxxxxx = write, 11_xxxxxx = fastcmd
reg cmd_vld;

wire [5:0] new_reg_addr;
wire [REG_W-1:0] reg_data_i_be;
reg [REG_W-1:0] reg_data_o_be; 

reg [$clog2(REG_W)-1:0] cnt; 
reg [1:0] state;

wire sclk_samp, sclk_upd, sel, desel, nss_val;

assign isr = {mosi_sr, mosi2};
assign miso = osr[REG_W-1];
assign reg_addr = cmd[ADDR_W-1:0];
assign new_reg_addr = reg_addr + 1;
assign fastcmd = cmd[5:0];

generate 
genvar i;
for(i = 0; i < REG_W / 8; i = i + 1) begin
    integer j = REG_W / 8 - 1 - i;
    assign reg_data_i_be[(i*8)+:8] = reg_data_i[(j*8)+:8];
    assign reg_data_o[(i*8)+:8] = reg_data_o_be[(j*8)+:8];
end
endgenerate

localparam cmd_reg_rd = 2'b00;
localparam cmd_reg_wr = 2'b10;
localparam cmd_fastcmd = 2'b11;

always @(posedge clk)
if(!nrst) begin
    mosi_sr <= 0;
    osr <= 0;
    cmd <= 0;
    cmd_vld <= 0; 
    reg_data_o_be <= 0;
    reg_data_o_vld <= 0;
    fastcmd_vld <= 0;
    cnt <= 0;
    state <= 2'd0;
end else begin
    if(reg_data_o_vld) begin
        reg_data_o_vld <= 0;
        //read or write is done, increase addr
        cmd <= {cmd[7:6], new_reg_addr};
    end
    if(fastcmd_vld) fastcmd_vld <= 0;
    case(state)
    2'd0: if(nss_val) begin     //wait for deselect
            state <= 2'd1;
        end          
    2'd1: if(!nss_val) begin    //idle state
            cmd_vld <= 0;
            cnt <= 0;    
            osr <= {status, {(REG_W-8){1'b0}}};
            state <= 2'd2;
        end
    2'd2: if(nss_val) begin  //samp input
            state <= 2'd1;
        end else if(sclk_samp) begin
            if(!cmd_vld && (cnt == 4'd7)) begin
                //receive cmd
                cmd <= isr;
                if(isr[7:6] == cmd_fastcmd) begin
                    //output fastcmd
                    if(!fastcmd_vld) fastcmd_vld <= 1;
                    //do not receive more data, go wait state
                    state <= 2'd0;
                end else begin
                    //go update state
                    state <= 2'd3;
                end
            end else if(cmd_vld && (cnt == (REG_W-1))) begin
                //cmd_reg_wr
                if(cmd[7:6] == cmd_reg_wr) begin
                    //transfer isr to reg
                    reg_data_o_be <= isr;
                    if(!reg_data_o_vld) reg_data_o_vld <= 1;
                end
                //go update state
                state <= 2'd3;
            end else begin
                //shifting input to sr
                mosi_sr <= isr[REG_W-2:0];
                state <= 2'd3;
            end
        end
    2'd3: if(nss_val) begin  //update output
            state <= 2'd1;
        end else if(sclk_upd) begin
            if((!cmd_vld && (cnt == 4'd7)) ||
               (cmd_vld && (cnt == (REG_W-1)))) begin
                //cmd is valid after 8bits received
                if(!cmd_vld) cmd_vld <= 1;
                //cmd_reg_wr: data already transferred
                if(cmd[7:6] == cmd_reg_rd) begin
                    //cmd_reg_rd: transfer data and increase addr
                    osr <= reg_data_i_be;
                    cmd <= {cmd[7:6], new_reg_addr};
                end else begin
                    //otherwise, transfer zero back to host
                    osr <= {REG_W{1'b0}};
                end
                //reset bit counter
                cnt <= 0;
                //go sample state
                state <= 2'd2;
            end else begin
                //shifting sr to output
                osr <= {osr[REG_W-2:0], 1'b0};
                cnt <= cnt + 1;
                state <= 2'd2; 
            end
        end
    endcase 
end

assign sclk_samp = sclk2 && (!sclk3);   //rising edge
assign sclk_upd = (!sclk2) && sclk3;    //falling edge
assign nss_val = nss2;

always @(posedge clk)
if(!nrst) begin
    mosi1 <= 0;
    mosi2 <= 0;
    sclk1 <= 0;
    sclk2 <= 0;
    sclk3 <= 0;
    nss1 <= 0;
    nss2 <= 0;
end else begin
    mosi1 <= mosi;
    mosi2 <= mosi1;
    sclk1 <= sclk;
    sclk2 <= sclk1;
    sclk3 <= sclk2;
    nss1 <= nss;
    nss2 <= nss1;
end

endmodule
