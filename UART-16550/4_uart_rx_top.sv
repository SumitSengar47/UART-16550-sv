//this file is part of the UART RX module
//it is used to receive data from the UART TX module

`timescale 1ns/1ps

module uart_rx_top (
    input clk,rst,baud_pulse,rx,sticky_parity,eps,
    input pen, //parity enable
    input [1:0] wls, //word length select   
    output reg push, //push data to FIFO
    output reg pe, //parity error
    output reg fe, //framing error
    output reg bi, //break interrupt
);
    
    typedef enum logic[2:0]{ idle=0,start=1,read=2,parity=3,stop=4 } state_type; 

    state_type state = idle; // current state

    //Detect falling edge of rx signal ,in simple words it means that the start bit is detected
    reg rx_reg = 1'b1; //initially rx is high
    wire fall_edge;

    always @(posedge clk ) begin
        rx_reg <= rx; //store the current value of rx
    end

    assign fall_edge = rx_reg ;

    /////////////////////////////////////
    reg[2:0] bitcnt;
    reg[3:0] count = 0; //counter for baud rate
    reg[7:0] dout = 0; //data output register
    reg pe_reg; // parity error register

    always @(posedge clk ,posedge rst) begin
        if(rst) begin
            state <= idle;
            push <= 1'b0;
            pe <= 1'b0;
            fe <= 1'b0;
            bi <= 1'b0;
            bitcnt <= 8'h00;
        end

        else begin
            push <= 1'b0; //default push is low

            if(baud_pulse) begin
                case(state)
                    //////////////IDLE STATE////////////////
                    idle: begin
                        if(!fall_edge) begin
                            state <= start;
                            count <= 5'd15; //reset counter to 15
                        end
                        else begin
                            state <= idle;
                        end
                    end

                    //////////////START STATE////////////////
                    start: begin
                        count <= count - 1; //decrement counter

                        if(count == 5'd7) begin //it will detect the start bit after 8 clock cycles
                            if(rx == 1'b1) begin
                                state <= idle;
                                count <= 5'd15; //reset counter to 15
                            end
                            else begin
                                state <= start;
                            end
                        end

                        else if(count == 0) begin
                            state <= read; //read the data from rx
                            count <= 5'd15; //reset counter to 15
                            bitcnt <= {1'b1,wls}; //set bit count according to wls
                        end
                    end

                    //////////////READ STATE : Read byte from rx pin////////////////
                    read: begin
                        count <= count -1; //decrement counter

                        if(count == 5'd7) begin
                            case(wls)
                            2'b00: dout <= {3'b000,rx,dout[4:1]};
                            2'b01: dout <= {2'b00,rx,dout[5:1]};
                            2'b10: dout <= {1'b0,rx,dout[6:1]};
                            2'b11: dout <= {rx,dout[7:1]};
                            endcase

                            state <= read; //stay in read state
                        end

                        else if(count == 0) begin
                            if(bitcnt == 0) begin
                                case({sticky_parity,eps})
                                 2'b00:pe_reg <= ~^{rx,dout}; //odd parity -> pe:no. of 1's even
                                 2'b01:pe_reg <= ^{rx,dout}; //even parity -> pe:no. of 1's odd
                                 2'b10:pe_reg <= ~rx; //parity should be 1
                                 2'b11:pe_reg <= rx; //parity should be 0
                                endcase

                                if(pen == 1'b1) begin
                                    state <= parity; //go to parity state
                                    count <= 5'd15; //reset counter to 15
                                end
                                else begin
                                    state <= stop; //go to stop state
                                    count <= 5'd15; //reset counter to 15
                                end
                            end //bitcnt reaches 0

                            else begin
                                bitcnt <= bitcnt - 1; //decrement bit count
                                state <= read; //stay in read state
                                count <= 5'd15; //reset counter to 15
                            end
                        end
                    end

                    //////////////PARITY STATE : Check parity and Detect Parity Error   ////////////
                    parity: begin
                        count <= count -1;

                        if(count == 5'd7) begin
                            pe <= pe_reg; //set parity error flag
                            state <= parity; //stay in parity state
                        end
                        else if(count == 0) begin
                            state <= stop: //go to stop state
                            count <= 5'd15; //reset counter to 15
                        end
                    end

                    //////////////STOP STATE : Check stop bit and Detect Framing Error   ////////////
                    stop: begin
                        count <= count -1;

                        if(count == 5'd7) begin
                            fe <= ~rx; //set framing error flag
                            push <= 1'b1; //push data to FIFO
                            state <= stop; //stay in stop state
                        end
                        else if(count == 0) begin
                            state <= idle; //go to idle state
                            count <= 5'd15; //reset counter to 15
                        end
                    end

                    default:;
                endcase
            end
        end
    end

endmodule

////////////////////////////////////////////////////////// Testbench for UART RX Module ///////////////////////////////////////////////////////
module uart_rx_tb; 

reg clk,rst,baud_pulse,rx,pen,eps,sticky_parity;
reg [1:0] wls;
wire push,pe,fe,bi;

uart_rx_top rx_dut(clk,rst,baud_pulse,rx,sticky_parity,eps,pen,wls,push,pe,fe,bi);

initial begin
    clk = 0;
    rst = 0;
    baud_pulse = 0;
    rx = 1;
    sticky_parity = 0;
    eps = 0;
    pen = 1'b1;
    wls = 2'b11; //8 data bits
end

always #5 clk = ~clk; //clock period of 10ns

reg [7:0] rx_reg = 8'h45; //data to be received

initial begin
    rst = 1'b1; //reset the DUT
    repeat(5)@(posedge clk);
    //start the DUT
    rst = 1'b0;
    rx = 1'b0; //start bit
    repeat(16)@(posedge baud_pulse); //wait for 16 baud pulses

    //send 8 bytes of data
    for(int i = 0; i<8 ;i++) begin
        rx = rx_reg[i]; //write data to rx
        repeat(16)@(posedge baud_pulse); //wait for 16 baud pulses
    end

    //Generate parity bit
    rx = ~^(rx_reg); //parity bit for odd parity

    repeat(16)@(posedge baud_pulse); //wait for 16 baud pulses

    //generate stop bit
    rx = 1'b1; //stop bit
    repeat(16)@(posedge baud_pulse); //wait for 16 baud pulses
end

// Monitor the outputs
integer count = 5;

always @(posedge clk ) begin
    if(rst == 0) begin
        if(count != 0) begin
            count <= count - 1;
            baud_pulse <= 1'b0;
        end
        else begin
            count <= 5;
            baud_pulse <= 1'b1; //generate baud pulse every 5 clock cycles
        end
    end
end

endmodule
