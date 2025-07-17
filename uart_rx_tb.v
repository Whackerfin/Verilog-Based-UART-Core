`timescale 1ns/1ps
module uart_rx_tb;

reg clock,reset,rx;
reg fifo_full;
wire b_tick;
wire [7:0] data;
wire [7:0] LSR;

localparam BAUD_RATE=9600;
localparam BIT_TIME = (1000000000/BAUD_RATE);

localparam CLK = 50000000;
localparam CLK_TIME = (1000000000/CLK);

always #(CLK_TIME/2) clock = ~clock;

task send_byte;
    input [7:0] to_send;
    integer i;
    begin
        #BIT_TIME rx = 1'b0; // Start Bit
        for (i=0;i<8;i=i+1) begin
            #BIT_TIME rx = to_send[i]; //Data bits
        end
        #BIT_TIME rx = ^to_send; //Parity bit
        #BIT_TIME rx = 1'b1;  //Two stop bits
        #BIT_TIME rx = 1'b1; 
    end
endtask

integer passed=0;
integer failed=0;

task check_byte;
    input [7:0] to_check;
    begin
        if (data == to_check) begin
            passed=passed+1;
            $display("%d/%d/%d [PASSED] Expected %b Recieved %b",passed,failed,passed+failed,to_check,data);
            $display("LSR register: Data available %b | Overrun error: %b | Incorrect Parity: %b | No Framing Error: %b",LSR[0],LSR[1],LSR[2],LSR[3]);            
        end
        else begin
            failed = failed+1;
            $display("%d/%d/%d [FAILED] Expected %b Recieved %b",passed,failed,passed+failed,to_check,data);
            $display("LSR register: Data available %b | Overrun error: %b | Incorrect Parity: %b | No Framing Error: %b",LSR[0],LSR[1],LSR[2],LSR[3]);            
        end
    end
endtask

task send_err_byte;
    input [7:0] to_send;
    input [1:0] code;
    integer i;
    begin
    case (code)
        2'd0:begin //Start Bit glitching
            #(BIT_TIME/3) rx = 1'b0;
            #(BIT_TIME/4) rx = 1'b1;
            #(BIT_TIME/2) rx = 1'b0;
            #(BIT_TIME/3) rx = 1'b1;
            send_byte(to_send);
        end
        2'd1:begin // Parity Bit error
        begin
            #BIT_TIME rx = 1'b0; 
            for (i=0;i<8;i=i+1) begin
                #BIT_TIME rx = to_send[i]; 
            end
            #BIT_TIME rx = ~^to_send;
            #BIT_TIME rx = 1'b1;  
            #BIT_TIME rx = 1'b1; 
        end
        end
        2'd2:begin //Stop Bit error
        begin
            #BIT_TIME rx = 1'b0;
            for (i=0;i<8;i=i+1) begin
                #BIT_TIME rx = to_send[i]; 
            end
            #BIT_TIME rx = ^to_send; 
            #BIT_TIME rx = 1'b0;
        end        
        end
    endcase
    end
endtask


reg [7:0] to_send;
reg [1:0] err_code;
initial begin
     reset = 1'b0;
     clock = 1'b0;
     rx = 1'b1;
     fifo_full=1'b0;
     #40 reset = 1'b1;
     #(2*CLK_TIME) reset = 1'b0;

     $dumpfile("Uart_rx.vcd");
     $dumpvars(0,uart_rx_tb);

    #(10*CLK_TIME)
     repeat (10) begin
        to_send = {$random} % 256;
        send_byte(to_send);
        check_byte(to_send);
     end
    $display ("Non errenious Test result");
    $display(" PASSED: %d",passed);
    $display(" FAILED : %d",failed);
    
    #(10*CLK_TIME)
    passed=0;
    failed=0;
     repeat (10) begin
        to_send = {$random} % 256;
        err_code = {$random} % 3;
        send_err_byte(to_send,err_code);
        check_byte(to_send);
        if (err_code==2'd0) $display("No Error expected : start bit glitching");
        else if (err_code == 2'd1) $display("Error expected: parity bit error");
        else $display("Error expected : stop bit error");
     end
    $display ("Errenious Test result");
    $display(" PASSED: %d",passed);
    $display(" FAILED : %d",failed);

    $display("Finished simulation at time %g",$time);
    $finish;
end


baud_tick_gen U0(.clock(clock),.reset(reset),.baud_tick(b_tick));
uart_rx U1(.clock(clock),.reset(reset),.b_tick(b_tick),.rx(rx),.fifo_full(fifo_full),.data_out(data),.LSR(LSR));


endmodule