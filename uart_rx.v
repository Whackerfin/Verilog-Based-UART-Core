module uart_rx(
    input b_tick,
    input clock,
    input reset,
    input rx,  
    input fifo_full,
    input clear_flags,
    output wire [7:0] data_out,
    output wire [7:0] LSR
);

reg rx_done,buffer_overrun,parity_error,framing_error;
reg rx_done_next,buffer_overrun_next,parity_error_next,framing_error_next;
assign LSR[0] = rx_done;
assign LSR[1] = buffer_overrun;
assign LSR[2] = parity_error;
assign LSR[3] = framing_error;
assign LSR[7:4] = {4{1'b0}};


always @(posedge clock) begin
 if (reset || clear_flags) begin
    rx_done <= 1'b0;
    buffer_overrun <= 1'b0;
    parity_error <= 1'b0;
    framing_error <=1'b0;
 end
 else begin
    rx_done <= rx_done_next;
    buffer_overrun <= buffer_overrun_next;
    parity_error <= parity_error_next;
    framing_error <= framing_error_next;
 end
end


localparam [2:0] idle = 3'b000;
localparam [2:0] start =3'b001;
localparam [2:0] data = 3'b010;
localparam [2:0] parity = 3'b011;
localparam [2:0] stop = 3'b100;

parameter SB = 2; //Number of stop bits
parameter PB = 0; //Even parity is 0
parameter DB = 8; //Number of data bits 

reg [2:0] state,next_state;
reg [3:0] cnt,next_cnt;
reg       s_reg,s_next;
reg [2:0] n_reg,n_next;
reg [7:0] d_reg,d_next;

assign data_out = d_reg;

//Synchronizing input receive
reg sync_rx;
reg i_rx;

always @(posedge clock) begin
    sync_rx<=rx;
    i_rx<=sync_rx;
end


//FSMD state registers and data
always @(posedge clock) begin
    if (reset) begin
        state<= idle;
        s_reg<=0;
        n_reg<=0;
        cnt<=0;
        d_reg <=0;
    end
    else begin
        state<=next_state;
        s_reg<=s_next;
        n_reg<=n_next;
        cnt<=next_cnt;
        d_reg <= d_next;
    end
end   

//Next state logic
always @(*) begin
    next_state = state;
    d_next = d_reg;
    s_next = s_reg;
    n_next = n_reg;
    next_cnt = cnt;
    rx_done_next = rx_done;
    buffer_overrun_next =buffer_overrun;
    parity_error_next =parity_error;
    framing_error_next =framing_error;

    case (state)
        idle:
            if (~i_rx) begin
                next_state = start;
                next_cnt = 0;
                d_next = 8'd0;
            end
        start: begin
            if (b_tick) begin
                next_cnt = cnt + 4'd1;
                if (cnt == 2 || cnt == 4 || cnt == 6) begin
                    if (i_rx) begin
                        next_state = idle;
                    end
                end
                else if (cnt==8) begin
                    if (i_rx) begin
                        next_state = idle;
                    end
                    else begin
                        next_state = data;
                        next_cnt = 4'd0;
                        n_next = 3'd0;
                    end
                end  
            end
        end
        data : begin
            if (b_tick) begin
                if (cnt == 15) begin
                    next_cnt = 4'd0;
                    d_next = {i_rx , d_reg[7:1]};  //Each time right shift it in
                    if (n_reg == 7) begin
                        next_state = parity;
                    end
                    else begin
                        n_next = n_reg +3'd1;
                    end
                end
                else begin 
                    next_cnt = cnt + 4'd1;
                end
            end
        end
        parity : begin
            if (b_tick) begin
                if (cnt == 15) begin
                        s_next = 2'd0;
                        next_cnt = 4'd0;
                        next_state =stop;
                    if (~PB) begin //Even parity
                        if (i_rx != ^{d_reg}) begin
                            parity_error_next = 1'b1;
                        end
                    end
                    else begin // Odd parity
                        if (i_rx != ~^{d_reg}) begin
                            parity_error_next = 1'b1;
                        end
                    end
                end
                else begin
                    next_cnt = cnt +4'd1;
                end
            end
        end
        stop: begin
            if (b_tick) begin
                if (cnt == 15) begin
                    if (~i_rx) begin
                        framing_error_next = 1'b1;
                    end
                    if (s_reg == SB-1) begin
                        if (fifo_full) begin
                            buffer_overrun_next = 1'b1;
                        end
                        rx_done_next = 1'b1;
                        next_state = idle;
                    end
                    else begin
                        s_next = s_reg + 2'd1;
                        next_cnt = 4'd0;
                    end
                end
                else begin
                    next_cnt = cnt +4'd1;
                end
            end
        end
        default: begin
            next_state = idle;
        end 

    endcase
end
endmodule