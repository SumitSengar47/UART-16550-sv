module all_mod(
input clk, rst, wr, rd,
input rx,
input [2:0] addr,
input [7:0] din,
output tx,
output [7:0] dout
    );
 
 csr_t       csr;
 
 wire baud_pulse, pen, thre, stb; 
 
 wire tx_fifo_pop;
 wire [7:0] tx_fifo_out;
 wire tx_fifo_push;
 
 wire r_oe, r_pe, r_fe, r_bi;
 wire rx_fifo_push, rx_fifo_pop;
 
 /////////////UART Registers
regs_uart uart_regs_inst (
    .clk (clk),
    .rst (rst),
    .wr_i (wr),
    .rd_i (rd),
    
    .rx_fifo_empty_i (),
    .rx_oe (),
    .rx_pe (r_pe),
    .rx_fe (r_fe),
    .rx_bi (r_bi),
    
    .addr_i (addr),
    .din_i (din),
    .tx_push_o (tx_fifo_push),
    .rx_pop_o (rx_fifo_pop),
    .baud_out (baud_pulse),
    .tx_rst (tx_rst),
    .rx_rst (rx_rst),
    .rx_fifo_threshold (rx_fifo_threshold),
    .dout_o (dout),
    .csr_o (csr),
    .rx_fifo_in(rx_fifo_out)
);
 
 //////////////TX logic
uart_tx_top uart_tx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .pen (csr.lcr.pen),
    .thre (1'b0),
    .stb (csr.lcr.stb),
    .sticky_parity (csr.lcr.stick_parity),
    .eps (csr.lcr.eps),
    .set_break (csr.lcr.set_break),
    .din (tx_fifo_out),
    .wls (csr.lcr.wls),
    .pop (tx_fifo_pop),
    .sreg_empty (), ///sreg empty ier
    .tx (tx)
);

///////////////// TX FIFO
fifo_top tx_fifo_inst (
    .rst (rst),
    .clk (clk),
    .en (csr.fcr.ena),
    .push_in (tx_fifo_push),
    .pop_in (tx_fifo_pop),
    .din (din),
    .dout (tx_fifo_out),
    .empty (), /// fifo empty ier
    .full (),
    .overrun (),
    .underrun (),
    .threshold (4'h0),
    .thre_trigger ()
);

 /////////////RX LOGIC
 
 uart_rx_top uart_rx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .rx (rx),
    .sticky_parity (csr.lcr.stick_parity),
    .eps (csr.lcr.eps),
    .pen (csr.lcr.pen),
    .wls (csr.lcr.wls),
    .push (rx_fifo_push),
    .pe (r_pe),
    .fe (r_fe),
    .bi (r_bi),
    .dout(rx_out)
);


////////////// RX FIFO

fifo_top rx_fifo_inst (
    .rst (rst),
    .clk (clk),
    .en (csr.fcr.ena),
    .push_in (rx_fifo_push),
    .pop_in (rx_fifo_pop),
    .din (rx_out),
    .dout (rx_fifo_out),
    .empty (), /// fifo empty ier
    .full (),
    .overrun (),
    .underrun (),
    .threshold (rx_fifo_threshold),
    .thre_trigger ()
);


endmodule

/////////////////////////////////////////////////Test Bench//////////////////////


module all_mod_tb;

reg clk, rst, wr, rd;
reg rx;
reg [2:0] addr;
reg [7:0] din;

wire tx;
wire [7:0] dout;

all_mod dut (clk, rst, wr, rd,rx,addr, din, tx, dout);

 
initial begin
rst = 0;
clk = 0;
wr = 0;
rd = 0;
addr = 0;
din = 0;
rx = 1;
end

always #5 clk = ~clk;

initial begin
rst = 1'b1;
repeat(5)@(posedge clk);
rst = 0;

////// dlab = 1;
@(negedge clk);
wr   = 1;
addr = 3'h3;
din  = 8'b1000_0000;

///// lsb latch = 08
@(negedge clk);
addr = 3'h0;
din  = 8'b0000_1000;

////// msb latch = 01
@(negedge clk);
addr = 3'h1;
din  = 8'b0000_0001;

///// dlab = 0, wls = 00(5-bits), stb = 1 (single bit dur), pen = 1, eps =0(odd), sp = 0
@(negedge clk);
addr = 3'h3;
din  = 8'b0000_1100;
//// push f0 in fifo (thr, dlab = 0)
@(negedge clk);
addr = 3'h0;
din  = 8'b1111_0000;///10000 -> parity = 0, 
//remove wr
@(negedge clk);
wr = 0;
@(posedge dut.uart_tx_inst.sreg_empty);
repeat(48) @(posedge dut.uart_tx_inst.baud_pulse);
$stop;
end

endmodule
