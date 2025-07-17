module fifo(
    input reset,
          clock,
          wr_en,
          rd_en,
    input [15:0] data_in, //A wider databus used to store both {data,error}
    output reg [15:0] data_out, 
    output empty,full

);
//Depth is 8 and WIDTH is 16 bits
reg [2:0] wptr,rptr;
reg [15:0] fifo [0:7];

always @(posedge clock) begin
    if (reset) begin
        wptr <= 3'd0;
    end
    else begin
        if (wr_en && !full) begin
            fifo[wptr] <= data_in;
            wptr <= wptr+3'd1;
        end
    end
end

always @(posedge clock) begin
    if (reset) begin
        rptr<=3'd0;
        data_out <= 16'b0;
    end
    else begin
        if (rd_en && !empty) begin
            data_out <= fifo[rptr];
            rptr <= rptr+3'd1;
        end
    end
end


assign empty = (wptr==rptr);
assign full = ((wptr+1)==rptr);




endmodule