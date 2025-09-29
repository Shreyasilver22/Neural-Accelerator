module image_mem (
    input  [9:0] addr,       // 0-783 → needs 10 bits
    output [7:0] pixel
);

    reg [7:0] mem [0:783];   // 28x28 = 784 pixels

    initial begin
        $readmemh("image0.mem", mem);
    end

    assign pixel = mem[addr];
endmodule




module MAC (
    input  clk, reset,
    input  signed [7:0] x,   // input value
    input  signed [7:0] w,   // weight
    input  enable,
    output reg signed [15:0] y   // accumulated result
    
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            y <= 0;
        else if (enable)
            y <= y + (x * w);   // multiply and accumulate
    end
endmodule
