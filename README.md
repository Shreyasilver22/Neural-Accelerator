FPGA Neural Network Accelerator (MNIST) 🧠⚡A pure hardware implementation of a Multi-Layer Perceptron (MLP) Neural Network on the Nexys 4 DDR FPGA. 
This accelerator performs real-time digit recognition on the MNIST dataset using integer quantization.Unlike software-based inference, this project implements the entire pipeline—from memory fetching to MAC operations and Activation functions—using custom digital logic (RTL), offering a transparent view into how neural networks operate at the gate level.
🏗️ ArchitectureThe design implements a fully connected neural network (784 $\to$ 16 $\to$ 10) controlled by a Finite State Machine (FSM).The PipelineInput Layer: 784 inputs (28x28 pixel grayscale images) stored in Block RAM/Distributed RAM.Hidden Layer: 16 Neurons processing inputs in parallel.Operations: 8-bit Integer Weights, 32-bit Accumulation.Activation: ReLU (Rectified Linear Unit).Output Layer: 10 Neurons (Digits 0-9).Activation: Linear (Logits).Argmax Unit: A combinatorial logic block that instantly identifies the digit with the highest confidence score."Brain Inspection" Mode 
🔍A unique feature of this accelerator is the Debug Monitor. Using on-board switches, the user can inspect the real-time internal activation score of any hidden neuron, displayed on the 7-segment display.🛠️ Hardware Setup (Nexys 4 DDR)ComponentLabelFunctionSwitch [3:0]SW0 - SW3Image Selector: Selects 1 of 16 test images from memory.
Switch [7:4]SW4 - SW7Neuron Monitor: Selects which Hidden Neuron (0-15) to view on the display.
Button CenterBTNCStart Trigger: Starts the inference engine.
Button RedCPU_RESETN System Reset: Clears accumulators and FSM.LED 0LD0
Done Signal: Lights up when inference is complete.
LED [4:1]LD1 - LD4Prediction: Displays the predicted digit in Binary (e.g., 0101 = 5).
7-SegmentDisplayNeuron Value: Shows the decimal activation score of the selected neuron.📂
Project StructurePlaintext├── rtl/
│   ├── FPGA_Top_Wrapper.v       # Top-level module mapping ports to hardware
│   ├── mnist_mlp_accelerator.v  # Core Neural Network Logic
│   ├── accelerator_controller.v # FSM for sequencing layers
│   ├── neurons.v                # Hidden and Output Neuron modules
│   ├── mac_units.v              # Multiply-Accumulate Units
│   └── display/                 # Drivers for 7-Segment and BCD conversion
├── python/
│   ├── train_model.py           # Keras script to train and quantize weights
│   ├── verify_mnist.py          # Bit-exact simulator for verification
│   └── generate_custom.py       # Generates sanity-check images (1, 2, 3, 4)
├── memory_files/
│   ├── images16.mem             # Input images (Hex)
│   ├── hidden_weights.mem       # Quantized weights (Layer 1)
│   ├── output_weights.mem       # Quantized weights (Layer 2)
│   └── ... (biases)
└── constraints/
    └── nexys4ddr.xdc            # Pin mapping file
🚀 How to Run1. Training & Quantization (Python)The network weights are trained in Python using TensorFlow/Keras and then quantized to integers for the FPGA.Bashcd python
python train_model.py
This generates the .mem files required for synthesis.2. FPGA Implementation (Vivado)Create a new project targeting the Artix-7 XC7A100T.Add all Verilog source files.Add the .mem files (Ensure "Copy sources into project" is checked).Add the nexys4ddr.xdc constraints file.Run Synthesis, Implementation, and Generate Bitstream.Program the device via USB.3. Verification (Sanity Check)To prove the logic works, we use a custom dataset of geometric shapes:SW=0000 (Vertical Line): Predicts 1 (LEDs 0001).SW=0001 (S-Shape): Predicts 2 (LEDs 0010).SW=0010 (E-Shape): Predicts 3 (LEDs 0011).📊 ResultsInput ImageExpected DigitLED Output (Binary)10 0 0 120 0 1 030 0 1 150 1 0 1📜 LicenseThis project is open-source. Feel free to use it for educational purposes
Author: Shreyas Singh , Raghav Aggrawal , Shreya Dixit , Kirti Kumar 
Date: November 2025
