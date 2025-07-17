module ram
#(parameter DEPTH=64,WIDTH=8) //6 bit address and 8 bit data
(
    input [5:0] addr,
    input wr_en, //reads when wr_en is 0
    output reg [7:0] data_out,
    input [7:0] data_in,
    input clock,reset,
    input clear
);

reg [7:0] memory[63:0];
reg clear_started; //Cannot read or write when clearing is going on
reg [5:0] cnt;
always @(posedge clock) begin
    if(reset) begin
        data_out <= 8'd0;
        cnt <= 6'd0;
        clear_started <= 1'd0;
    end else begin
        if (clear_started) begin
            memory[cnt] <= 8'd0;
            if (cnt == 63) begin
                clear_started <= 1'd0;
                cnt <= 6'd0;
            end
            else begin
                cnt <= cnt + 6'd1;
            end
        end else begin
            if (clear) begin
                clear_started <= 1'd1;
            end
            else if (wr_en) begin
                memory[addr] <= data_in;
            end
            else if (!wr_en) begin
                data_out <= memory[addr];
            end
        end
    end
end

endmodule