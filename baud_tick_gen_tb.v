`timescale  1ns/1ps
module baud_tick_gen_tb;
wire baud_tick;
reg clock;
reg reset;

baud_tick_gen U0(.clock(clock),.reset(reset),.baud_tick(baud_tick));

initial begin
    $dumpfile("baud_tick_gen.vcd");
    $dumpvars(0,baud_tick_gen_tb);
    clock <= 1'b0;
    reset <=1'b1;
#20 reset<=1'b0;
#7000 reset<=1'b1;
#20 reset<=1'b0;
#100 $finish;
end

always 
    #10 clock <= ~clock;

endmodule



