module uart_tb;
    reg clock, reset;
    wire tx;
    wire rx = tx;
    wire rx_empty;
    reg rd_uart;
    wire [7:0] data_out;
    wire [7:0] data_LSR;
    wire tx_full;
    reg wr_uart;
    reg [7:0] data_in;

    localparam CLK = 50000000;
    localparam CLK_TIME = (1000000000 / CLK);
    localparam BAUD_RATE=9600;
    localparam BIT_TIME = (1000000000/BAUD_RATE);
    always #(CLK_TIME/2) clock = ~clock;

    uart U0 (
        .clock(clock),
        .reset(reset),
        .tx(tx),
        .rx(rx),
        .rx_empty(rx_empty),
        .rd_uart(rd_uart),
        .data_out(data_out),
        .data_LSR(data_LSR),
        .tx_full(tx_full),
        .wr_uart(wr_uart),
        .data_in(data_in)
    );

    integer i;
    reg [7:0] tx_data [0:9];  
    reg [7:0] rx_data [0:9];   
    integer passed = 0, failed = 0;

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tb);

        clock = 0;
        reset = 1;
        wr_uart = 0;
        rd_uart = 0;
        data_in = 8'd0;

        #(10 * CLK_TIME) reset = 0;
        #(10 * CLK_TIME);


        for (i = 0; i < 8; i = i + 1) begin
            tx_data[i] = $random % 256;
        end

 
        for (i = 0; i < 8; i = i + 1) begin
            while (tx_full) @(posedge clock); 
            data_in <= tx_data[i];
            wr_uart <= 1'b1;
            #(CLK_TIME);
            wr_uart <= 1'b0;
            $display("[TX] Sent byte: %b", tx_data[i]);
            #(10*BIT_TIME);
        end

        for (i = 0; i < 8; i = i + 1) begin
            while (rx_empty) @(posedge clock);

            rd_uart = 1;
            #(CLK_TIME);
            rx_data[i] = data_out;
            rd_uart = 0;
            if (rx_data[i] === tx_data[i]) begin
                $display("[RX] Received byte %b [PASS]", rx_data[i]);
                passed = passed + 1;
            end else begin
                $display("[RX] Received byte %b (Expected: %b) [FAIL]", rx_data[i], tx_data[i]);
                failed = failed + 1;
            end
            #(10*BIT_TIME);
        end


        $display("PASSED: %d", passed);
        $display("FAILED: %d", failed);
        $finish;
    end
endmodule
