`timescale 1ns/1ps

// ============================================================
// MODULE 1: Image Memory (Simulation)
// ============================================================
module image_mem (
    input [3:0] image_index,
    input [9:0] addr,
    output [7:0] pixel
);
    reg [7:0] mem [0:784*16-1];
    initial $readmemh("images16.mem", mem);
    assign pixel = mem[image_index*784 + addr];
endmodule

// ============================================================
// MODULE 2: ReLU Activation Function (32-bit)
// ============================================================
module RELU (
    input  signed [31:0] in,
    output signed [31:0] out
);
    assign out = (in[31] == 1'b1) ? 32'd0 : in;
endmodule

// ============================================================
// MODULE 3: Layer 1 MAC Unit (32-bit Accumulator)
// ============================================================
module MAC_L1 (
    input clk, reset, enable,
    input signed [7:0] x,
    input signed [7:0] w,
    output reg signed [31:0] y // CRITICAL FIX: 32-bit Accumulator
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            y <= 0;
        else if (enable)
            y <= y + (x * w);
    end
endmodule

// ============================================================
// MODULE 4: Layer 1 Weight Memory (Simulation)
// ============================================================
module hidden_weight_mem (
    input [3:0] weight_index,
    input [9:0] addr,
    output signed [7:0] weight
);
    reg signed [7:0] mem [0:16*784-1];
    initial $readmemh("hidden_weights.mem", mem);
    assign weight = mem[weight_index*784 + addr];
endmodule

// ============================================================
// MODULE 5: Layer 1 Bias Memory (Simulation)
// ============================================================
module hidden_bias_mem (
    input [3:0] neuron_index,
    output signed [15:0] bias
);
    reg signed [15:0] mem [0:15];
    initial $readmemh("hidden_biases.mem", mem);
    assign bias = mem[neuron_index];
endmodule

// ============================================================
// MODULE 6: Layer 1 (Hidden Layer) Neuron (32-bit)
// ============================================================
module hidden_neuron (
    input clk, reset, enable,
    input [3:0] image_index, [3:0] neuron_index, [9:0] addr,
    output signed [31:0] relu_out // FIX: 32-bit output
);
    wire [7:0] pixel;
    wire signed [7:0] weight;
    wire signed [31:0] mac_out;
    wire signed [15:0] bias_val;
    wire signed [31:0] mac_with_bias;

    image_mem img (.image_index(image_index), .addr(addr), .pixel(pixel));
    hidden_weight_mem wgt (.weight_index(neuron_index), .addr(addr), .weight(weight));
    hidden_bias_mem bmem (.neuron_index(neuron_index), .bias(bias_val));

    MAC_L1 mac_unit (.clk(clk), .reset(reset), .x(pixel), .w(weight), .enable(enable), .y(mac_out));

    // Sign-extend 16-bit bias to 32-bit accumulator result before ReLU
    assign mac_with_bias = mac_out + {{16{bias_val[15]}}, bias_val};
    RELU act (.in(mac_with_bias), .out(relu_out));
endmodule

// ============================================================
// MODULE 7: Layer 2 MAC Unit (32-bit Accumulator)
// ============================================================
module MAC_L2 (
    input clk, reset, enable,
    input signed [31:0] x,    // FIX: 32-bit input
    input signed [7:0] w,
    output reg signed [31:0] y // FIX: 32-bit Accumulator
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            y <= 0;
        else if (enable)
            y <= y + (x * w);
    end
endmodule

// ============================================================
// MODULE 8: Layer 2 Weight Memory (Simulation)
// ============================================================
module output_weight_mem (
    input [3:0] weight_index,
    input [3:0] addr,
    output signed [7:0] weight
);
    reg signed [7:0] mem [0:10*16-1];
    initial $readmemh("output_weights.mem", mem);
    assign weight = mem[weight_index*16 + addr];
endmodule

// ============================================================
// MODULE 9: Layer 2 Bias Memory (Simulation)
// ============================================================
module output_bias_mem (
    input [3:0] neuron_index,
    output signed [15:0] bias
);
    reg signed [15:0] mem [0:9];
    initial $readmemh("output_biases.mem", mem);
    assign bias = mem[neuron_index];
endmodule

// ============================================================
// MODULE 10: Layer 2 (Output Layer) Neuron (32-bit)
// ============================================================
module output_neuron (
    input clk, reset, enable,
    input signed [31:0] hidden_activation, // FIX: 32-bit input
    input [3:0] neuron_index,
    input [3:0] addr,
    output signed [31:0] relu_out // FIX: 32-bit output
);
    wire signed [7:0] weight;
    wire signed [31:0] mac_out;
    wire signed [15:0] bias_val;
    wire signed [31:0] mac_with_bias;

    output_weight_mem wgt (.weight_index(neuron_index), .addr(addr), .weight(weight));
    output_bias_mem bmem (.neuron_index(neuron_index), .bias(bias_val));

    MAC_L2 mac_unit (.clk(clk), .reset(reset), .x(hidden_activation), .w(weight), .enable(enable), .y(mac_out));

    assign mac_with_bias = mac_out + {{16{bias_val[15]}}, bias_val};
    
    // *** CRITICAL FIX: Output the raw Logit score directly (Linear Activation) ***
    // This provides the stable, unclipped score to the Argmax unit.
    RELU act_output (.in(mac_with_bias), .out(relu_out));
endmodule

// ============================================================
// MODULE 11: The Multi-Layer Controller FSM
// ============================================================
module accelerator_controller (
    input clk, reset, start,
    output reg h_reset, output reg h_enable, output reg [9:0] h_addr,
    output reg o_reset, output reg o_enable, output reg [3:0] o_addr,
    output reg done, output reg store_h_results
);

    localparam IDLE = 3'b000, RESET_H = 3'b001, RUN_H = 3'b010, RESET_O = 3'b011, RUN_O = 3'b100, DONE_S = 3'b101;
    reg [2:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE; else state <= next_state;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin h_addr <= 0; o_addr <= 0; end
        else if (state == RUN_H) begin if (h_addr < 10'd783) h_addr <= h_addr + 1; else h_addr <= 0; end
        else if (state == RUN_O) begin if (o_addr < 4'd15) o_addr <= o_addr + 1; else o_addr <= 0; end
        else if (state == IDLE && start) begin h_addr <= 0; o_addr <= 0; end
    end

    always @* begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = RESET_H;
            RESET_H: next_state = RUN_H;
            RUN_H: if (h_addr == 10'd783) next_state = RESET_O;
            RESET_O: next_state = RUN_O;
            RUN_O: if (o_addr == 4'd15) next_state = DONE_S;
            DONE_S: next_state = IDLE;
        endcase
    end

    always @* begin
        h_reset = 1'b0; h_enable = 1'b0; o_reset = 1'b0; o_enable = 1'b0; done = 1'b0; store_h_results = 1'b0;
        case (state)
            RESET_H: h_reset = 1'b1;
            RUN_H: begin h_enable = 1'b1; if (h_addr == 10'd783) store_h_results = 1'b1; end
            RESET_O: o_reset = 1'b1;
            RUN_O: o_enable = 1'b1;
            DONE_S: done = 1'b1;
        endcase
    end
endmodule

// ============================================================
// MODULE 12: The Argmax "Judge" Unit (32-bit)
// ============================================================
module argmax_unit (
    input signed [31:0] score_0, input signed [31:0] score_1, input signed [31:0] score_2, input signed [31:0] score_3, input signed [31:0] score_4, 
    input signed [31:0] score_5, input signed [31:0] score_6, input signed [31:0] score_7, input signed [31:0] score_8, input signed [31:0] score_9,
    output reg [3:0] predicted_digit
);
    reg signed [31:0] max_score;
    always @* begin
        max_score = score_0; predicted_digit = 4'd0;
        if (score_1 > max_score) begin max_score = score_1; predicted_digit = 4'd1; end
        if (score_2 > max_score) begin max_score = score_2; predicted_digit = 4'd2; end
        if (score_3 > max_score) begin max_score = score_3; predicted_digit = 4'd3; end
        if (score_4 > max_score) begin max_score = score_4; predicted_digit = 4'd4; end
        if (score_5 > max_score) begin max_score = score_5; predicted_digit = 4'd5; end
        if (score_6 > max_score) begin max_score = score_6; predicted_digit = 4'd6; end
        if (score_7 > max_score) begin max_score = score_7; predicted_digit = 4'd7; end
        if (score_8 > max_score) begin max_score = score_8; predicted_digit = 4'd8; end
        if (score_9 > max_score) begin max_score = score_9; predicted_digit = 4'd9; end
    end
endmodule

 // ============================================================
// MODULE 13: THE TOP-LEVEL ACCELERATOR (UPDATED)
// ============================================================
module mnist_mlp_accelerator (
    input clk, reset, start,
    input [3:0] image_index,
    input [3:0] monitor_select,      // <--- NEW: Select which neuron to watch (0-15)
    output signed [31:0] monitor_out,// <--- NEW: Output the value of that neuron
    output [3:0] predicted_digit,
    output done
);

    wire h_reset, h_enable, o_reset, o_enable, store_h_results;
    wire [9:0] h_addr;
    wire [3:0] o_addr;

    wire signed [31:0] h_relu_out [0:15]; 
    wire signed [31:0] o_relu_out [0:9];  

    reg signed [31:0] hidden_activations [0:15];
    
    accelerator_controller u_controller (
        .clk(clk), .reset(reset), .start(start),
        .h_reset(h_reset), .h_enable(h_enable), .h_addr(h_addr),
        .o_reset(o_reset), .o_enable(o_enable), .o_addr(o_addr),
        .done(done), .store_h_results(store_h_results)
    );

    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin : gen_hidden_layer
        hidden_neuron hn (.clk(clk), .reset(h_reset), .enable(h_enable), .image_index(image_index), .neuron_index(i[3:0]), .addr(h_addr), .relu_out(h_relu_out[i]));
    end endgenerate

    always @(posedge clk) begin
        if (store_h_results) begin
            hidden_activations[0]  <= h_relu_out[0];
            hidden_activations[1]  <= h_relu_out[1];
            hidden_activations[2]  <= h_relu_out[2];
            hidden_activations[3]  <= h_relu_out[3];
            hidden_activations[4]  <= h_relu_out[4];
            hidden_activations[5]  <= h_relu_out[5];
            hidden_activations[6]  <= h_relu_out[6];
            hidden_activations[7]  <= h_relu_out[7];
            hidden_activations[8]  <= h_relu_out[8];
            hidden_activations[9]  <= h_relu_out[9];
            hidden_activations[10] <= h_relu_out[10];
            hidden_activations[11] <= h_relu_out[11];
            hidden_activations[12] <= h_relu_out[12];
            hidden_activations[13] <= h_relu_out[13];
            hidden_activations[14] <= h_relu_out[14];
            hidden_activations[15] <= h_relu_out[15];
        end
    end
    
    // --- NEW LOGIC: MUX to select the neuron to display ---
    // We look at the result after the ReLU calculation
    assign monitor_out = h_relu_out[monitor_select];

    genvar j;
    generate for (j = 0; j < 10; j = j + 1) begin : gen_output_layer
        output_neuron on (.clk(clk), .reset(o_reset), .enable(o_enable), .hidden_activation(hidden_activations[o_addr]), .neuron_index(j[3:0]), .addr(o_addr), .relu_out(o_relu_out[j]));
    end endgenerate

    argmax_unit u_argmax (
        .score_0(o_relu_out[0]), .score_1(o_relu_out[1]), .score_2(o_relu_out[2]), .score_3(o_relu_out[3]), .score_4(o_relu_out[4]), 
        .score_5(o_relu_out[5]), .score_6(o_relu_out[6]), .score_7(o_relu_out[7]), .score_8(o_relu_out[8]), .score_9(o_relu_out[9]), 
        .predicted_digit(predicted_digit));
        
endmodule
