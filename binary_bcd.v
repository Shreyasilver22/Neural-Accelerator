module Binary_to_BCD (
    input [15:0] bin_in,
    output reg [3:0] ones,
    output reg [3:0] tens,
    output reg [3:0] hundreds,
    output reg [3:0] thousands
);
    // Simple "Double Dabble" algorithm implementation
    integer i;
    reg [31:0] bcd; // Register to hold shifting bits

    always @(bin_in) begin
        bcd = 0;
        bcd[15:0] = bin_in; // Load binary into lower bits

        for (i = 0; i < 16; i = i + 1) begin
            // Check if columns > 4, add 3
            if (bcd[19:16] > 4) bcd[19:16] = bcd[19:16] + 3; // ones
            if (bcd[23:20] > 4) bcd[23:20] = bcd[23:20] + 3; // tens
            if (bcd[27:24] > 4) bcd[27:24] = bcd[27:24] + 3; // hundreds
            if (bcd[31:28] > 4) bcd[31:28] = bcd[31:28] + 3; // thousands
            
            // Shift left 1
            bcd = bcd << 1;
        end
        
        thousands = bcd[31:28];
        hundreds  = bcd[27:24];
        tens      = bcd[23:20];
        ones      = bcd[19:16];
    end
endmodule
