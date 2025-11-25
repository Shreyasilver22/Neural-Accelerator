module Seven_Seg_Driver (
    input clk,               // 100MHz FPGA Clock
    input reset,
    input [3:0] d3, d2, d1, d0, // The 4 digits to display
    input is_negative,       // 1 if number is negative
    output reg [6:0] seg,    // Cathodes (A-G)
    output reg [7:0] an      // Anodes (Digit Select)
);

    // 1. Slow down clock for display refresh (100MHz -> ~1kHz)
    reg [16:0] refresh_counter;
    wire [1:0] digit_select;
    
    always @(posedge clk or posedge reset) begin
        if (reset) refresh_counter <= 0;
        else refresh_counter <= refresh_counter + 1;
    end
    assign digit_select = refresh_counter[16:15]; // Use top 2 bits

    // 2. Muxing: Select which digit to show based on counter
    reg [3:0] digit_to_show;
    always @* begin
        case(digit_select)
            2'b00: begin an = 8'b11111110; digit_to_show = d0; end // Rightmost
            2'b01: begin an = 8'b11111101; digit_to_show = d1; end 
            2'b10: begin an = 8'b11111011; digit_to_show = d2; end
            2'b11: begin 
                   an = 8'b11110111; 
                   // If negative, show 10 (which we map to minus), else show digit
                   digit_to_show = is_negative ? 4'd10 : d3; 
                   end 
        endcase
    end

    // 3. Decoder: Convert Digit to Segment Patterns (Common Anode)
    // 0 = Light On, 1 = Light Off
    always @* begin
        case(digit_to_show)
            4'd0: seg = 7'b1000000; // 0
            4'd1: seg = 7'b1111001; // 1
            4'd2: seg = 7'b0100100; // 2
            4'd3: seg = 7'b0110000; // 3
            4'd4: seg = 7'b0011001; // 4
            4'd5: seg = 7'b0010010; // 5
            4'd6: seg = 7'b0000010; // 6
            4'd7: seg = 7'b1111000; // 7
            4'd8: seg = 7'b0000000; // 8
            4'd9: seg = 7'b0010000; // 9
            4'd10:seg = 7'b0111111; // Minus Sign (-)
            default: seg = 7'b1111111; // Off
        endcase
    end
endmodule
