`timescale 1ns/1ps

module uart_top
#(
    parameter clk_freq =  1000000, // 1 MHz
    parameter baud_rate = 9600 // 9600 bps

)
(
    input clk,rst,
    input rx,            //rtx->reciever
    input [7:0] dintx,  //input for transmitter module
    input newd,         //new data available pin 
    output tx,          //utx->transmitter
    output [7:0] doutrx, //output of rx module
    output donetx,       //done pin of tx
    output donerx       //done pin of rx to verify the sucessful transmission
);

uarttx
#(clk_freq , baud_rate)
utx
(clk,rst,newd,dintx,tx,donetx);

uartrx
#(clk_freq , baud_rate)
rtx
(clk,rst,rx,donerx,doutrx);

endmodule

//////////////////////////////////////////////////////////////////////////

//first decalaring the transmitter module of the UART
//it will take the clock, reset, new data available pin, data to transmit
//and will give the transmitted data and done pin as output 

module uarttx
#(parameter clk_freq = 1000000, // 1 MHz
  parameter baud_rate = 9600 // 9600 bps;
)
(
    input clk, rst,
    input newd,          // new data available pin
    input [7:0] tx_data,  // data to transmit
    output reg tx,          // Reg type to store the transmitted data
    output reg donetx       // done pin
);

    localparam clkcount = (clk_freq / baud_rate); //it is a local parameter to calculate the clock count for the baud rate

    integer count = 0; // counter to count the clock cycles
    integer counts = 0; // counter to count the bits transmitted

    reg uclk = 0; // clock for the transmitter module

    enum bit[1:0]{idle= 2'b00, start = 2'b01, transfer = 2'b10, done = 2'b11} state; // state machine for the transmitter

    ////uart clock generation
    always @(posedge clk) begin
        if(count< clkcount/2)
         count <= count + 1;
        else begin
          count <= 0;    //reset the count
          uclk <= ~uclk; // toggle the clock
        end       
    end

    reg[7:0] din;
    
    ////Reset decoder
    always@(posedge uclk)begin
      if(rst)begin
        state <= idle ; // reset the state machine to idle
      end
      else begin
        case(state)
            idle :
             begin
               counts <= 0; // reset the countstate
               tx <= 1'b1;  //start bit high to indicate idle state ,no transmission
               donetx <= 1'b0; // reset the done pin
               
               if(newd)
               begin
                 state <= transfer; // go to transfer state
                 din <= tx_data; // load the data to be transmit in din register
                 tx <= 1'b0; // start bit low to indicate start of transmission
               end
               else
                 state <= idle; // stay in idle state
             end

            transfer :
            begin
              if(counts <= 7) // check if all bits are transmitted
               begin
                 counts <= counts + 1; // increment the count
                 tx <= din[counts]; // transmit the data bit at each clock cycle tx<=din[0] transmit the first bit and so on
                 state <= transfer; // stay in transfer state
               end
              else
               begin
                 counts <= 0; // reset the count
                 tx <= 1'b1; // stop bit high to indicate end of transmission
                 state <= idle;
                 donetx <= 1'b1; // set the done pin to indicate transmission is done
               end
            end

            default : state <= idle; // default case to reset the state machine
        endcase
      end
    end
endmodule


/////////////////////////////////////////////////////////////////////
// Now declaring the receiver(rx) module of the UART
// it will take the clock, reset, received data pin, and will give the received data and done pin as output

module uartrx
#(
    parameter clk_freq = 1000000, // 1 MHz
    parameter baud_rate = 9600 // 9600 bps
)
(
    input clk,rst,
    input rx,           // received data pin
    output reg done, // done pin to indicate successful reception
    output reg [7:0] rxdata // received data output
);
    localparam clkcount = (clk_freq / baud_rate); // local parameter to calculate the clock count for the baud rate

    integer count = 0;
    integer counts = 0; // counter to count the bits received

    reg uclk = 0; // clock for the receiver module

    enum bit[1:0]{idle = 2'b00 ,start = 2'b01} state ; // state machine for the receiver

    ////uart clock generation
    always @(posedge clk)
     begin
       if(count < clkcount/2)
        count <= count + 1;
       else begin
         count <= 0;
         uclk <= ~uclk; 
       end
     end


    always @(posedge uclk)
     begin
       if(rst) begin
         rxdata <= 8'h00; // reset the received data
         done <= 1'b0; // reset the done pin
         counts <= 0; // reset the count
       end

       else begin
         case(state)

         idle : 
         begin
           rxdata <= 8'h00;
           done <= 1'b0; 
           counts <= 0; 
         
         if(rx == 1'b0)
          state <= start; // if the received data is low, go to start state
         else
          state <= idle; // stay in idle state if the received data is high
         
         end

         start : 
          begin
            if(count <= 7)
             begin
               counts <= counts + 1;
               rxdata <= {rx, rxdata[7:1]}; // shift the received data to the left and store the new bit

             end
            else begin
              counts <= 0;
              done <= 1'b1;
              state <= idle;

            end
          end

          default : state <= idle; // default case to reset the state machine

         endcase

       end
     end

endmodule
