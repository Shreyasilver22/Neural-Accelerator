module tb_mac;

    reg clk, reset, enable;
    reg signed [7:0] w;    // weight (example)
    wire signed [7:0] x;   // pixel input
    wire signed [15:0] y;

    reg [9:0] addr;        // pixel index 0-783

    // Instantiate image memory
    image_mem imem (
        .addr(addr),
        .pixel(x)
    );

    // Instantiate MAC
    MAC mac_unit (
        .clk(clk),
        .reset(reset),
        .x(x),
        .w(w),
        .enable(enable),
        .y(y)
    );

    // Clock generator
    always #5 clk = ~clk;

    initial begin
        // init
        clk = 0;
        reset = 1;
        enable = 0;
        addr = 0;
        w = 8'sd1;   // example: weight = 1
        #10 reset = 0;

        // Feed all 784 pixels
        for (addr = 0; addr < 784; addr = addr + 1) begin
            enable = 1;
            #10;   // wait one clock cycle
        end

        enable = 0;
        #20;

        $display("Final MAC output: %d", y);
        $finish;
    end



endmodule
