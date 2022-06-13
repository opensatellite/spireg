# spireg
SPIREG - SPI slave logic for register access
* Easy integration with Arduino SPI
* Support N*8 bits reg width, 1~64 registers
* Status byte can be acquired on first byte read.
* FastCmd can send command code on first byte write.
* Very low resources consumption (~100LUT, ~200FF)

# Connection
MCU <--SPI--> SPIREG <--regaccess--> User logic   
SPI: MOSI MISO SCLK NSS   
regaccess: reg_addr, reg_data_i, reg_data_o, reg_data_o_vld   
regaccess(additional): status, fastcmd, fastcmd_vld   

# Protocol   
SPI settings   
* Databits = 8, MSB First, Mode = 0 (CPOL=Low, CPHA=1edge)    
* sclk_freq <= clk / 2   

# SPI commands   
* Read data   
cmd = addr, addr = 0 ~ 63   
```
    MOSI: |addr   |0xff        |0xff         |0xff          |0xff           | ...   
    MISO: |status |d[addr][7:0]|d[addr][15:8]|d[addr+1][7:0]|d[addr+1][15:8]| ...   
```
* Write data   
cmd = 0x80+addr, addr = 0 ~ 63   
```
    MOSI: |cmd    |d[addr][7:0]|d[addr][15:8]|d[addr+1][7:0]|d[addr+1][15:8]| ...   
    MISO: |status |0x00        |0x00         |0x00          |0x00           | ...   
```
* Fast command   
cmd = 0xc0+fastcmd, fastcmd = 0 ~ 63   
```
    MOSI: |cmd    |   
    MISO: |status |   
```
* Status query   
```
    MOSI: |0x00   |   
    MISO: |status |   
```

# Arduino example code
TBD

# Simple register bank example
```
wire [3:0] reg_addr;
wire [15:0] reg_data_i, reg_data_o;
wire reg_data_o_vld;
wire [7:0] status;
wire [5:0] fastcmd;
wire fastcmd_vld;
reg [15:0] mem [0:15];

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
    .reg_data_o_vld(reg_wr),
    .status(status),
    .fastcmd(),
    .fastcmd_vld()
);

//status signals
assign status = mem[0][7:0];

//register read access
assign reg_data_i = mem[reg_addr];

integer i;
always @(posedge clk or negedge nrst)
if(!nrst) begin
    for(i = 0; i < 2**ADDR_WIDTH; i = i+1)
        mem[i] <= 0;
end else begin
    if(reg_wr) begin
    //register write access
        mem[reg_addr] <= reg_data_o;
    end
end
```

# Complete example for "fastcmd" feature
* see spireg_example.v   

#  Resources ultilization   
Device: Xilinx XC7S6   
User registers: 16*16bits   
LUT used: 112 of 3750   
FF used: 199 of 7500   
