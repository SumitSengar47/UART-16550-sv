`timescale 1ns/1ps

////////////////////////////////////LCR is used in TX UART to set the number of data bits, parity, and stop bits

module  uart_tx_top (
    input clk,rst,
    baud_pulse, //baud pulse input for UART transmission
    pen , //parity enable
    thre, //threshold for FIFO
    stb, //start bit
    sticky_parity, //sticky parity
    eps, //even parity select
    set_break, //set break condition
    input [7:0] din, //data input
    input [1:0] wls, //word length select
    output reg pop,sreg_empty,tx //pop signal for FIFO, sreg_empty flag meaning shift register is empty, tx output for UART transmission
);
    
typedef enum logic[1:0]{idle = 0, start = 1, send = 2, parity = 3 } state_type ;
state_type state = idle; //state variable for FSM

reg[7:0] shift_reg; //shift register to hold data for transmission
reg tx_data; //transmitted data
reg d_parity; //data parity bit
reg [2:0] bitcnt = 0; //bit counter for tracking the number of bits sent
reg [4:0] count = 5'd15;
reg parity_out; //parity bit for transmission


always @(posedge clk ,posedge rst) begin
    if(rst) begin
        state <= idle; //reset state to idle
        count <= 5'd15; //reset count for baud pulse
        bitcnt <= 0; //reset bit counter
        //////////////////////////////
        shift_reg <= 8'bxxxxxxxx; //reset shift register
        pop <= 1'b0; //reset pop signal
        sreg_empty <= 1'b0; //set shift register empty flag
        tx_data <= 1'b1; //set tx data to idle state (high)
    end

    else if(baud_pulse) begin
        case(state)
         //////////////idle state/////////////////////
         idle: begin
            if(thre == 1'b0) //csr.lsr.thre is low, meaning FIFO is not empty
             begin
                if(count != 0 ) begin
                    count <= count - 1; // decrement count for baud pulse
                    state <= idle; //stay in idle state
                end

                else begin
                    count <= 5'd15; // reset count for baud pulse
                    state <= start; //move to start state
                    bitcnt <= {1'b1,wls}; //set bit count based on word length select

                    /////////////////////////////////////

                    pop <= 1'b1; //read tx fifo , pop signal is high i.e pop operation is allowed and data can be read
                    shift_reg <= din; //store fifo data in shift reg
                    sreg_empty <= 1'b0 ; //shift register is not empty

                    ////////////////////////

                    tx_data <= 1'b0; //set tx data to low (start bit)
                end
             end
         end

        /////////////////////////start state/////////////////////
        start: begin
            ///////////////////calculate parity bit, if parity is enabled ,XOR function helps to find the parity bit if its odd or even
            case(wls)
             2'b00 : d_parity <= ^din[4:0]; //5 bits, parity is calculated on first 5 bits
             2'b01 : d_parity <= ^din[5:0]; //6 bits, parity is calculated on first 6 bits
             2'b10 : d_parity <= ^din[6:0]; //7 bits, parity is calculated on first 7 bits
             2'b11 : d_parity <= ^din[7:0]; //8 bits, parity is calculated on all 8 bits
            endcase

            if(count != 0) begin
                count <= count -1; //decrement count for baud pulse
                state <= start; //stay in start state

            end
            else begin
                count <= 5'd15; //reset count for baud pulse
                state <= send; //move to send state
                ///////////////////////////

                tx_data <= shift_reg[0]; //set tx data to the first bit of shift register
                shift_reg <= shift_reg >> 1; //shift shift register to the right
                ////////////////////////////

                pop <= 1'b0; //pop signal is low, no pop operation is allowed
            end
        end

        /////////////////////////send state/////////////////////
        send: begin
            case({sticky_parity,eps})
            2'b00: parity_out <= ~d_parity; //even parity, sticky parity is low ,not XOR
            2'b01: parity_out <= d_parity; //odd parity, sticky parity is low
            2'b10: parity_out <= 1'b1; //sticky parity ,mark/set
            2'b11: parity_out <= 1'b0; //sticky parity ,space/reset
            endcase

            if(bitcnt != 0 ) begin

                if(count != 0) begin
                    count <= count -1 ; //decrement count for baud pulse
                    state <= send; //stay in send state
                end

                else begin
                    count <= 5'd15; //reset count for baud pulse
                    bitcnt <= bitcnt - 1; //decrement bit counter
                    tx_data <= shift_reg[0]; //set tx data to the first bit of shift register
                    shift_reg <= shift_reg >> 1; //shift shift register to the right
                    state <= send; //stay in send state
                end
            end

            else begin
                ////////check for parity bit and set it accordingly////////
                if(count != 0) begin
                    count <= count - 1;
                    state <= send;
                end
                else begin
                    count <= 5'd15;
                    sreg_empty <= 1'b1; //set shift register empty flag

                    if(pen == 1'b1) begin //if parity is enabled
                        state <= parity; //move to parity state
                        count <= 5'd15; //reset count for baud pulse
                        tx_data <= parity_out;
                    end

                    else begin
                        tx_data <= 1'b1; //set tx data to idle state (high)
                        count <= (stb == 1'b0) ? 5'd15 : (wls == 2'b00) ? 5'd23 : 5'd31; //set count for baud pulse based on start bit and word length select
                        state <= idle; //move to idle state
                    end
                end
            end 
        end

        /////////////////////////parity state/////////////////////
        parity: begin
            if(count != 0) begin
                count <= count -1;
                state <= parity; //stay in parity state
            end
            else begin
                tx_data <= 1'b1;
                count <= (stb == 1'b0) ? 5'd15 : (wls == 2'b00) ? 5'd17 : 5'd31; //set count for baud pulse based on start bit and word length select
                state <= idle; //move to idle state
            end
        end

        default: ;

        endcase
    end
end

/////////////////////////////////////////////////

always @(posedge clk ,posedge rst) begin
    if(rst)
     tx <= 1'b1; 
    else 
     tx <= tx_data & ~set_break; //tx is high when tx_data is high and set_break is low, meaning no break condition

end

endmodule


/////////////////////////////////////////////////////Testbench for uart_tx_top///////////////////////////////////////////////////////////

module uart_tx_tb ;

reg clk,rst,baud_pulse,pen,thre,stb,sticky_parity,eps,set_break;
reg [7:0] din;
reg [1:0] wls;

wire pop,sreg_empty,tx;

uart_tx_top tx_dut(clk,rst,baud_pulse,pen,thre,stb,sticky_parity,eps,set_break,din,wls,pop,sreg_empty,tx);

initial begin
    rst = 0;
    clk = 0;
    baud_pulse = 0;
    pen = 1'b1;
    thre = 1'b0;
    stb = 1; //stop will be for 2-bit duration
    sticky_parity = 1'b0; // sticky parity is off
    eps = 1; //even parity select is on
    set_break = 0;
    din = 8'h13;
    wls = 2'b11; //word length select is 8 bits
end

always #5 clk = ~clk; //clock generation

initial begin
    rst = 1'b1; //reset the module
    repeat(5)@(posedge clk); //wait for 5 clock cycles
    rst = 1'b0; //release reset
end

/////////////////baud pulse generation/////////////////

integer count = 5; 

always @(posedge clk ) begin
    if(rst == 0) begin
        if(count != 0) begin
            count <= count - 1;
            baud_pulse <= 1'b0; //baud pulse is low
        end
        else begin
            count <= 5; //reset count for baud pulse
            baud_pulse <= 1'b1; //baud pulse is high
        end
    end
end

endmodule


