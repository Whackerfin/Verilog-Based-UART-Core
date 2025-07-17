module baud_tick_gen(
    input clock,
    input reset,
    output baud_tick
);
localparam BAUD_RATE=9600;
localparam MASTER_CLK=50000000;
//divisor = Clock/(16xBaud rate) for 16 times oversampling
localparam BIT_DIVISOR=325;
reg [8:0] baud_counter;
assign baud_tick = (baud_counter==BIT_DIVISOR);

always @(posedge clock)
begin
    if (reset)
        baud_counter<=9'b0;
    else
        if (baud_counter==BIT_DIVISOR)
            baud_counter<=9'b0;
        else
            baud_counter<=baud_counter+9'b1;
end
endmodule
