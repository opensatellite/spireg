`timescale 1ns / 1ps

module spireg_tb();

reg clk, nrst;
reg [63:0] txd, rxd;
reg sclk, nss;
wire mosi;
wire miso;
integer mosi_bsel; 

integer ntest;

assign mosi = txd[mosi_bsel];

spireg_example #(
    .ADDR_W(6),
    .REG_W(16)
) spireg_example_inst (
    .clk(clk),
    .nrst(nrst),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .nss(nss)
);

task run_clks(input integer n);
integer i;
for(i = 0; i < n; i = i+1) begin
    #1 clk = 1;
    #1 clk = 0;
end
endtask

task run_spi(input integer bits, input integer dly);
integer i;
begin
    sclk = 0;
    nss = 0;
    mosi_bsel = bits - 1;
    run_clks(dly);
    for(i = 0; i < bits; i = i+1) begin
        //sample input
        rxd = {rxd[62:0], miso};
        //send rising edge
        sclk = 1;
        run_clks(dly);
        //change output
        txd = {txd[62:0], 1'b0};
        //send falling edge
        sclk = 0;
        run_clks(dly);
    end
    nss = 1;
    run_clks(dly);
end
endtask

task dump_rxd(input integer bits);
integer i;
if(bits > 8) begin
    $write("status: %b, bytes: ", rxd[(bits-8)+:8]);
    for(i = bits/8-2; i >= 0; i = i - 1) begin
        $write("%h", rxd[(i*8)+:8]);
    end
    $write("\n");
end else if(bits == 8) begin
    $display("status: %b", rxd[7:0]);
end   
endtask

initial begin
    clk = 0;
    nrst = 0;
    sclk = 0;
    nss = 0;
    txd = 0;
    rxd = 0;
    mosi_bsel = 0;
    ntest = 0;
 
    run_clks(4);
    nrst = 1;
    run_clks(32);
    nss = 1;
    run_clks(32);
     
    //run test - read reg
    ntest = 1;
    rxd = 0;
    txd = 24'h00_ffff;       //read reg[0]
    run_spi(24, 8);
    dump_rxd(24);            //status: 00000000, bytes: 0000
    
    //run test - fastcmd
    ntest = 2;
    rxd = 0;
    txd = 8'hc1;
    run_spi(8, 8);
        
    //run test - read reg
    ntest = 3;
    rxd = 0;
    txd = 24'h00_ffff;       //read reg[0]
    run_spi(24, 8);
    dump_rxd(24);            //status: 00000001, bytes: 0100
    
    //run test - fastcmd2
    ntest = 4;
    rxd = 0;
    txd = 8'hc0;
    ntest = 2;
    run_spi(8, 8);
    
    //run test - write reg
    ntest = 5;
    rxd = 0;
    txd = 24'h8a_1010;       //write reg[10]
    run_spi(24, 8);
    
    ntest = 6;
    rxd = 0;
    txd = 8'hbf;             //write reg[63] and drop
    run_spi(8, 8);
    
    ntest = 7;
    rxd = 0;
    txd = 40'h82_0202_0303;  //write reg[2,3]
    run_spi(40, 8);
    
    ntest = 8;
    rxd = 0;
    txd = 40'hbf_3f3f_dddd;  //write reg[63,0]
    run_spi(40, 8);
    
    //run test - read reg
    ntest = 9;
    rxd = 0;
    txd = 24'h00_ffff;       //read reg[0]
    run_spi(24, 8);
    dump_rxd(24);            //status: 11011101, bytes: dddd
    
    ntest = 10;
    rxd = 0;
    txd = 40'h02_ffff_ffff;  //read reg[2,3]
    run_spi(40, 8);
    dump_rxd(40);            //status: 11011101, bytes: 02020303
    
    ntest = 11;
    rxd = 0;
    txd = 40'h3f_0000_0000;  //read reg[63,0]
    run_spi(40, 8);
    dump_rxd(40);            //status: 11011101, bytes: 3f3fdddd
       
    $stop;
end

endmodule
