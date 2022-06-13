`timescale 1ns / 1ps

/*
SPI settings
    * Databits = 8, MSB First, Mode = 0 (CPOL=Low, CPHA=1edge)
    * sclk_freq <= clk / 2

SPI commands
Read data:    cmd = addr, addr = 0~63
    MOSI: |addr   |0xff        |0xff         |0xff          |0xff           | ...
    MISO: |status |d[addr][7:0]|d[addr][15:8]|d[addr+1][7:0]|d[addr+1][15:8]| ...
Write data :  cmd = 0x80+addr, addr = 0~63
    MOSI: |cmd    |d[addr][7:0]|d[addr][15:8]|d[addr+1][7:0]|d[addr+1][15:8]| ...
    MISO: |status |0x00        |0x00         |0x00          |0x00           |
Fast command: cmd = 0xc0+fastcmd, fastcmd = 0~63
    MOSI: |cmd    |
    MISO: |status |
Status query:
    MOSI: |0x00   |
    MISO: |status |

In this example:
*  total 64 registers available, each 16bits wide
*  status = reg[0][7:0]
*  fastcmd can change reg[0] directly

FastCmd definations:
    x = 0,  reg[0][ 0] <= 0
    x = 1,  reg[0][ 0] <= 1
    x = 2,  reg[0][ 1] <= 0
    x = 3,  reg[0][ 1] <= 1
    ...
    x = 28, reg[0][14] <= 0
    x = 29, reg[0][14] <= 1
    x = 30, reg[0][15] <= 0
    x = 31, reg[0][15] <= 1
*/

module spireg_example(
    input clk,
    input nrst,
    input mosi,
    output miso,
    input sclk,
    input nss
);

localparam integer ADDR_WIDTH = 3;  //1-6
localparam integer REG_WIDTH = 16;  //8, 16, 24, 32, 40, 48, 56, 64

wire [ADDR_WIDTH-1:0] reg_addr;
wire [REG_WIDTH-1:0] reg_data_i, reg_data_o;
wire reg_data_o_vld;
wire [7:0] status;
wire [5:0] fastcmd;
wire fastcmd_vld;
reg [REG_WIDTH-1:0] mem [0:(2**ADDR_WIDTH-1)];

spireg #(
    .REG_W(REG_WIDTH)
) spireg_inst(
    .clk(clk),
    .nrst(nrst),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .nss(nss),
    .reg_addr(reg_addr),
    .reg_data_i(reg_data_i),
    .reg_data_o(reg_data_o),
    .reg_data_o_vld(reg_data_o_vld),
    .status(status),
    .fastcmd(fastcmd),
    .fastcmd_vld(fastcmd_vld)
);

//register read access
assign reg_data_i = mem[reg_addr];

//status signals
assign status = mem[0][7:0];

//register write and fastcmd access
integer i;
always @(posedge clk or negedge nrst)
if(!nrst) begin
    for(i = 0; i < 2**ADDR_WIDTH; i = i+1)
        mem[i] <= 0;
end else begin
    //fastcmd operation
    if(fastcmd_vld) begin
        case(fastcmd)
            6'd0:  mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00000001};
            6'd1:  mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00000001};
            6'd2:  mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00000010};
            6'd3:  mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00000010};
            6'd4:  mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00000100};
            6'd5:  mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00000100};
            6'd6:  mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00001000};
            6'd7:  mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00001000};
            6'd8:  mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00010000};
            6'd9:  mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00010000};
            6'd10: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00100000};
            6'd11: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_00100000};
            6'd12: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_01000000};
            6'd13: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_01000000};
            6'd14: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_10000000};
            6'd15: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000000_10000000};
            6'd16: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000001_00000000};
            6'd17: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000001_00000000};
            6'd18: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000010_00000000};
            6'd19: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000010_00000000};
            6'd20: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00000100_00000000};
            6'd21: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00000100_00000000};
            6'd22: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00001000_00000000};
            6'd23: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00001000_00000000};
            6'd24: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00010000_00000000};
            6'd25: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00010000_00000000};
            6'd26: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b00100000_00000000};
            6'd27: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b00100000_00000000};
            6'd28: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b01000000_00000000};
            6'd29: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b01000000_00000000};
            6'd30: mem[0] <= mem[0] &~ {{(REG_WIDTH - 16){1'b0}}, 16'b10000000_00000000};
            6'd31: mem[0] <= mem[0] |  {{(REG_WIDTH - 16){1'b0}}, 16'b10000000_00000000};
        endcase
    end else if(reg_data_o_vld) begin
    //register write access
        mem[reg_addr] <= reg_data_o;
    end
end


endmodule
