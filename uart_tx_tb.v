module uart_tx_tb;
reg clock,reset;
reg fifo_full;
wire b_tick;
wire [7:0] data;
wire [7:0] LSR;
reg tx_start;
wire tx_done_tick;
wire tx;
reg clear_flags;
localparam BAUD_RATE=9600;
localparam BIT_TIME = (1000000000/BAUD_RATE);

localparam CLK = 50000000;
localparam CLK_TIME = (1000000000/CLK);

always #(CLK_TIME/2) clock = ~clock;



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




reg [7:0] to_send;
initial begin
     reset = 1'b0;
     clock = 1'b0;
     fifo_full=1'b0;
     clear_flags =1'b0;
     #40 reset = 1'b1;
     #(2*CLK_TIME) reset = 1'b0;

     $dumpfile("Uart_tx.vcd");
     $dumpvars(0,uart_tx_tb);

    #(10*CLK_TIME)
     repeat (10) begin
        to_send = {$random} % 256;
        @(posedge clock);
        tx_start <= 1'b1;
        @(posedge clock);
        tx_start <= 1'b0;
        while (~tx_done_tick) begin
            @(posedge clock);
        end
        while (~LSR[0]) begin
            @(posedge clock);
        end
        clear_flags <= 1'b1;
        @(posedge clock);
        clear_flags <=1'b0;
        check_byte(to_send);
     end
    $display ("Non errenious Test result");
    $display(" PASSED: %d",passed);
    $display(" FAILED : %d",failed);
    
    $finish;
end


baud_tick_gen U0(.clock(clock),.reset(reset),.baud_tick(b_tick));
uart_rx U1(.clock(clock),.reset(reset),.b_tick(b_tick),.rx(tx),.fifo_full(fifo_full),.data_out(data),.LSR(LSR),.clear_flags(clear_flags));
uart_tx U2(.clock(clock),.reset(reset),.b_tick(b_tick),.tx(tx),.data_in(to_send),.tx_start(tx_start),.tx_done_tick(tx_done_tick));


endmodule