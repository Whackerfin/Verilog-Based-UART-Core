`include "baud_tick_gen.v"
`include "uart_rx.v"
`include "fifo.v"
`include "fifo8.v"
`include "uart_tx.v"
module uart(
input clock,reset,
output tx,
input  rx,
output rx_empty,
input rd_uart,
output [7:0] data_out,
output [7:0] data_LSR,
output tx_full,
input wr_uart,
input [7:0] data_in
);

wire b_tick;
wire fifo_full;
wire [7:0] data_r;
wire [7:0] LSR;
reg clear_flags;

reg rx_wr_en;
reg rx_wr_flag;
wire [7:0] tx_data;
reg tx_start;
reg tx_fifo_read;
wire tx_done_tick;
wire tx_empty;
reg tx_started_flag;
reg tx_fifo_flag;

baud_tick_gen U0(.clock(clock),.reset(reset),.baud_tick(b_tick));
uart_rx U1(.clock(clock),.reset(reset),.b_tick(b_tick),.rx(rx),.fifo_full(fifo_full),.data_out(data_r),.LSR(LSR),.clear_flags(clear_flags));
fifo U2(.clock(clock),.reset(reset),.empty(rx_empty),.full(fifo_full),.wr_en(rx_wr_en),.rd_en(rd_uart),.data_in({data_r,LSR}),.data_out({data_out,data_LSR}));
uart_tx U3(.clock(clock),.reset(reset),.b_tick(b_tick),.tx(tx),.data_in(tx_data),.tx_start(tx_start),.tx_done_tick(tx_done_tick));
fifo8 U4(.clock(clock),.reset(reset),.empty(tx_empty),.full(tx_full),.wr_en(wr_uart),.rd_en(tx_fifo_read),.data_in(data_in),.data_out(tx_data));

always @(posedge clock) begin
    if (reset) begin
        rx_wr_en <= 1'b0;
        clear_flags <=1'b0;
        rx_wr_flag <= 1'b0;
    end else begin 
    if(LSR[0]) begin
        if (!fifo_full && !rx_wr_flag) begin
            rx_wr_en <= 1'b1;
            rx_wr_flag <= 1'b1;
        end else begin
            rx_wr_en <=1'b0;
            clear_flags <=1'b1;
        end

    end else begin
        clear_flags <= 1'b0;
        rx_wr_flag <=1'b0;
        rx_wr_en <=1'b0;
    end
    end
end



always @(posedge clock) begin
    if(reset) begin
        tx_start <= 1'b0;
        tx_started_flag <=1'b0;
        tx_fifo_read <= 1'b0;
        tx_fifo_flag <= 1'b0;
    end else begin 
        if(tx_done_tick) begin
            tx_start <= 1'b0;
            tx_started_flag <=1'b0;
            tx_fifo_flag <= 1'b0;
        end

        else if (!tx_empty && !tx_fifo_flag && !tx_started_flag) begin
            tx_fifo_read <= 1'b1;
            tx_fifo_flag <= 1'b1;
        end 
        
        else if (tx_fifo_flag && !tx_started_flag) begin
            tx_start <= 1'b1;
            tx_started_flag <= 1'b1;
            tx_fifo_read <= 1'b0;
        end 
        
        else if (tx_started_flag) begin
            tx_start <= 1'b0;
        end
    end
end

endmodule