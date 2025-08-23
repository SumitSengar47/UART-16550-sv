//This is part of the FIFO design
//push_in and pop_in are the control signals for pushing and popping data
//dout is the output data, din is the input data
//empty and full are status signals, overrun and underrun indicate errors
//overun occurs when trying to push data into a full FIFO
//underrun occurs when trying to pop data from an empty FIFO
//threshold is used to trigger an event when the FIFO reaches a certain level
//thre_trigger is the output signal that indicates the threshold has been reached

module fifo_top (
 input rst,clk,en,push_in,pop_in,
 input [7:0] din,
 output [7:0] dout,
 output empty,full,overrun,underrun,
 input [3:0] threshold,
 output thre_trigger
);

//memory for FIFO
reg [7:0] mem[16]; //8-bit data, 16 entries
//read and write pointers
reg [3:0] waddr=0; //write address to locate where to write data in the FIFO

logic push,pop; //control signals for push and pop operations

//////////////Empty Flag Logic/////////////////////
reg empty_t;
always @(posedge clk,posedge rst) begin
    if(rst) begin
        empty_t <= 1'b0; //reset empty flag
    end
    else begin
        case({push,pop})
         2'b01: empty_t <= (~|(waddr) | ~en); //pop operation, check if FIFO is empty
         2'b10: empty_t <= 1'b0; //push operation, check if FIFO is not empty ,empty is 0 meaning not empty ,push can be performed
         default:;
        endcase
    end
end

//////////////Full Flag Logic/////////////////////
reg full_t;
always @(posedge clk,posedge rst) begin
    if(rst) begin
        full_t <= 1'b0; //rset full flag ,means not full
    end
    else begin
        case({push,pop})
         2'b10: full_t <= (&(waddr) | ~en); //push operation, check if FIFO is full 
         2'b01: full_t <= 1'b0; //pop operation, check if FIFO is not full ,full is 0 meaning not full ,pop can be performed
         default:;
        endcase
    end
end

//////////////////////////////////////

assign push = push_in & ~full_t; //allow push if not full ,when push_in is high and full_t is low
assign pop = pop_in & ~empty_t; //allow pop if not empty ,when pop_in is high and empty_t is low

/////////////////////read fifo --> always first element in FIFO is read first
assign dout = mem[0]; //output the first element in FIFO

///////////////////Write pointer update logic
always @(posedge clk , posedge rst) begin
    if(rst) begin
        waddr <= 4'h0; //reset write address to 0
    end
    else begin
        case({push,pop})
         
         2'b10:
          begin
            if(waddr != 4'hf && full_t==1'b0)
             waddr <= waddr +1 ; //increment write address if not full
            else
             waddr <= waddr ; //keep the same address if full          
          end

          2'b01:
           begin
            if(waddr != 0 && empty_t==1'b0)
             waddr <= waddr -1; //decrement write address if not empty
            else 
             waddr <= waddr; //keep the same address if empty
           end

          default: ;
        endcase
    end
end

/////Memory update logic
always @(posedge clk,posedge rst)
begin
    case ({push,pop})
        2'b00:;

        2'b01: begin //pop operation
         for(int i=0;i<14;i++)
          begin
            mem[i] <= mem[i+1]; //shift data left to remove the first element ,occupy the first element with the second element
          end    
            mem[15] <= 8'h00; //clear the last element
        end

        2'b10: begin //push operation
            mem[waddr] <= din; //write data to the current write address
        end

        2'b11: begin //both push and pop operation
         for(int i=0; i<14; i++)
          begin
            mem[i] <= mem[i+1]; 
          end
           mem[15] <= 8'h00 ; //clear the last element
           mem[waddr-1] <= din; //write data to the previous write address
            
        end
        
        default: ;
    endcase
end

///no read for on empty fifo

//////////////Underrun Logic/////////////////////
reg underrun_t;
always @(posedge clk,posedge rst) begin
    if(rst) 
     underrun_t <= 1'b0; //reset underrun flag
    else if(pop_in == 1'b1 && empty_t == 1'b1)
     underrun_t <= 1'b1; //set underrun flag if pop is attempted on an empty FIFO
    else 
     underrun_t <= 1'b0; //clear underrun flag otherwise
end

//////////////Overrun Logic/////////////////////
reg overrun_t;
always @(posedge clk ,posedge rst) begin
    if(rst)
     underrun_t <= 1'b0; //reset overrun flag
    else if(push_in == 1'b1 && full_t == 1'b1)
     overrun_t <= 1'b1; //set overrun flag if push is attempted on a full FIFO
    else 
     overrun_t <= 1'b0; //clear overrun flag otherwise
end

///////Threshold Trigger Logic//////////////////////
reg thre_t;
always@(posedge clk,posedge rst) begin
    if(rst)  begin
        thre_t <= 1'b0; // reset threshold trigger
    end
    else if(push ^ pop ) ///1 ^ 1 = 0 
     begin
        thre_t <= (waddr >= threshold) ? 1'b1 : 1'b0; //set threshold trigger if write address is greater than or equal to threshold
     end
end

/////////////////////////
assign empty = empty_t; //output empty flag
assign full = full_t; //output full flag
assign overrun = overrun_t; //output overrun flag
assign underrun = underrun_t; //output underrun flag
assign thre_trigger = thre_t; //output threshold trigger

endmodule


/////////////////////////////////////////////////Teshbench for FIFO Top Module//////////////////////////////////////////////////////////////////////////////
module fifo_tb ;

reg rst,clk,en,push_in,pop_in;
reg [7:0] din;
wire [7:0] dout;
wire empty,full,overrun,underrun;
reg [3:0] threshold;
wire thre_trigger;

initial begin
    rst = 0;
    clk = 0;
    en = 0;
    din = 0;
end
    
fifo_top dut_fifo(rst, clk, en, push_in, pop_in, din, dout, empty, full, overrun, underrun, threshold, thre_trigger);

always #5 clk = ~clk; //clock generation

initial begin
    
    rst = 1'b1;
    repeat(5)@(posedge clk);

    for(int i = 0; i<20 ; i++) begin
        rst = 1'b0; //release reset
        push_in = 1'b1; //enable push operation
        din = $urandom() ; //generate random data
        pop_in = 1'b0; //disable pop operation
        en = 1'b1; //enable FIFO
        threshold = 4'ha; // set threshold to a->10 ie for 10 blocks
        @(posedge clk);
    end

    ///////////////Read data from FIFO//////////

    for(int i = 0; i<20 ; i++) begin
        rst = 1'b0; //release reset
        push_in = 1'b0; //disable push operation
        din = 0; //no data to push
        pop_in = 1'b1; //enable pop operation
        en = 1'b1; //enable FIFO
        threshold = 4'ha; 
        @(posedge clk);
    end


end

endmodule
