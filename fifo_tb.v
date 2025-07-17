module fifo_tb;

reg clock,reset,wr_en,rd_en;
wire empty,full;
reg [15:0] data_in;
wire [15:0] data_out;

always #10 clock=~clock;

integer i;
reg [15:0] read_data;
reg done;
initial begin
    clock <= 1'b0;
    reset <=1'b0;
    wr_en <= 1'b0;
    rd_en <= 1'b0;
    done <= 1'b0;
    $dumpfile("fifo.vcd");
    $dumpvars(0,fifo_tb);
    
    #30 reset <=1'b1;
    #50 reset <= 1'b0;
    for (i=0;i<20;i=i+1) begin

    while (full) begin
        @(posedge clock);
        $display("FIFO is full waiting for read");
    end

    wr_en <= 1'b1;
    data_in  <= {$random} % 65536;
    $display("[%0t] clk i=%0d wr_en=%0d din=0x%0h ", $time, i, wr_en,data_in); 

    @(posedge clock);   
    end
    done = 1'b1;
end

initial begin
    @(posedge clock);
    while (~done) begin
    while (empty) begin
        @(posedge clock);
        $display("FIFO is empty waiting for write");
    end

    rd_en <= 1'b1;
    @(posedge clock);
    read_data <=data_out;
    $display("[%0t] clk rd_en=%0d rdata=0x%0h ", $time, rd_en, read_data);
    end

    #100 $finish;
end

fifo U0(.clock(clock),.reset(reset),.empty(empty),.full(full),.data_in(data_in),.data_out(data_out),.rd_en(rd_en),.wr_en(wr_en));

endmodule