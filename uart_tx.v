module uart_tx(
    input b_tick,
          clock,
          reset,
          tx_start,
    input [7:0] data_in,
    output wire tx_done_tick,
    output wire tx
);


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
reg       d_reg,d_next;
reg       tx_done,tx_done_next;  
reg [7:0] data_stored,data_stored_next;
assign tx = d_reg;
assign tx_done_tick = tx_done;



always @(posedge clock) begin
    if (reset) begin
        state <= idle;
        cnt <= 4'b0;
        s_reg <= 1'b0;
        n_reg <= 3'b0;
        d_reg <=1'b1;  //In idle state it should be high
        tx_done <=1'b0;
        data_stored <= 8'd0;
    end else begin
        state <= next_state;
        cnt <= next_cnt;
        s_reg <= s_next;
        n_reg <= n_next;
        d_reg <= d_next;
        tx_done <= tx_done_next;
        data_stored <= data_stored_next;
    end
end


always @(*) begin
    next_state = state;
    next_cnt = cnt;
    s_next = s_reg;
    n_next = n_reg;
    d_next = d_reg;
    tx_done_next = 1'b0;
    data_stored_next = data_stored;
    case (state)
        idle: begin
            if (tx_start) begin
                next_cnt = 4'b0;
                next_state = start;
                n_next = 3'b0;
                d_next = 1'b0;
                data_stored_next = data_in;
            end
        end
        start: begin
            if (b_tick) begin
                if (cnt == 15) begin
                    next_cnt = 4'd0;
                    next_state = data;
                    n_next=3'd0;
                    d_next = data_stored[0];
                end else begin
                    next_cnt = cnt + 4'd1;
                end
            end
        end
        data: begin
            if (b_tick) begin
                if (cnt==15) begin
                    if (n_reg==DB-1) begin
                        next_state = parity;
                        next_cnt = 4'd0;
                        d_next = (PB) ? ~^data_stored : ^data_stored;
                    end else begin
                        n_next = n_reg +3'd1;
                        d_next = data_stored[n_reg+3'd1];
                        next_cnt =4'd0;
                    end
                end else begin
                    next_cnt = cnt+4'd1;
                end
            end
        end
        parity: begin 
            if (b_tick) begin
                if(cnt==15) begin
                    next_state = stop;
                    next_cnt = 4'd0;
                    s_next = 1'd0;
                    d_next = 1'b1;
                end else begin
                    next_cnt = cnt +4'd1;
                end
            end
        end
        stop: begin
            if (b_tick) begin
                if(cnt==15) begin
                    if(s_reg == SB-1) begin
                        tx_done_next = 1'b1;
                        next_state = idle;
                        d_next = 1'b1;
                    end else begin
                        s_next = s_reg + 1'b1;
                        next_cnt =4'd0;
                    end
                end else begin
                    next_cnt = cnt +4'd1;
                end
            end
        end
    endcase
end
endmodule