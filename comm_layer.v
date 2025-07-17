`include "uart.v"
module comm_layer(
    input clock,reset,
    input rx,
    output tx,
);

reg [5:0] addr,addr_next;

//Basic Commands SF: 0xAA EF:0xED 
localparam [7:0] SFD = 8'hAA; //Start frame delimiter
localparam [7:0] EFD = 8'hED; //End frame delimiter
localparam [7:0] ERR = 8'hEE; //Error code
localparam [7:0] WTM = 8'hF4; //Write to memory
localparam [7:0] 



localparam [2:0] idle = 3'b000;
localparam [2:0] cmd = 3'b001;
localparam [2:0] data = 3'b010;
localparam [2:0] stop = 3'b011;
localparam [2:0] transmit = 3'b100;

reg [2:0] state,next_state;
wire rx_empty;
wire tx_full;
reg rd_uart,rd_next,wr_uart,wr_next;
reg [7:0] data_trans,data_trans_next;
wire [7:0] data_rec;
wire [7:0] data_LSR;

reg [7:0] command,command_next;
reg [7:0] frame_data,frame_data_next;
reg [7:0] error,error_next;


uart U0 (
    .clock(clock),
    .reset(reset),
    .tx(tx),
    .rx(rx),
    .rx_empty(rx_empty),
    .rd_uart(rd_uart),
    .data_out(data_rec),
    .data_LSR(data_LSR),
    .tx_full(tx_full),
    .wr_uart(wr_uart),
    .data_in(data_trans)
);


always @(posedge clock) begin
    if(reset) begin
        addr <= 6'd0;
        state <= idle;
        rd_uart <= 1'b0;
        wr_uart <= 1'b0;
        data_trans <= 8'b0;
        command <= 8'b0;
        frame_data <= 8'b0;
        error <= 8'b0;
    end else begin
        addr <= addr_next;
        rd_uart <= rd_next;
        state <= next_state;
        wr_uart <= wr_next;
        data_trans <= data_trans_next;
        command <= command_next;
        frame_data <= frame_data_next;
        error <= error_next;
    end
end


always @(*) begin
    next_state = state;
    command_next = command;
    frame_data_next = frame_data;
    error_next = error;
    rd_next = 1'b0;
    wr_next = 1'b0;
    addr_next =addr;
    data_trans_next= data_trans;

    case (state)
        idle:begin
            if (!rx_empty) begin
                if (data_rec == SFD ) begin
                    next_state = cmd;
                end else begin
                    rd_next = 1'b1;
                end
            end
        end
        cmd: begin
            if(!rx_empty || rd_uart) begin
                if (rd_uart) begin
                    command_next = data_rec;
                    next_state = data;
                end
                else if (!rx_empty) begin
                    rd_next = 1'b1;
                end
            end
        end
        data: begin
            if(!rx_empty || rd_uart) begin
                if (rd_uart) begin
                    frame_data_next = data_rec;
                    next_state = stop;
                end else if(!rx_empty) begin
                    rd_next = 1'b1;
                end
            end
        end
        stop: begin
            if (!rx_empty || rd_uart) begin
                if (rd_uart) begin
                    next_state = transmit;
                    if (data_rec!=EFD) begin
                        error_next = ERR;
                    end 
                end else if (!rx_empty) begin
                    rd_next = 1'b1;
                end

            end
        end
        transmit: begin
            if (!tx_full) begin
                if (error == 8'b0) begin //No errors send ACK or Data
                    case (command) 

                    endcase
                end
                else begin //Error present send error code

                end

            end
        end
    endcase

end

endmodule