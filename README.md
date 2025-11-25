


# FPGA Neural Network Accelerator (MNIST) 🧠⚡

### **Real-Time Digit Recognition on Nexys 4 DDR — Pure Hardware MLP**

This project implements a **fully hardware-accelerated Multi-Layer Perceptron (MLP)** on the **Nexys 4 DDR (Artix-7) FPGA**, capable of performing **real-time MNIST inference** using **integer-quantized weights**. Unlike software-based inference, everything—from memory fetch to MAC operations to activation functions—is realized **directly in RTL**, providing a transparent understanding of neural network computation at the digital logic level.

---

## 🎯 **Key Features**

* **Pure RTL neural network implementation** (no MicroBlaze, no HLS).
* **Fully connected architecture**:
  **784 → 16 → 10**
* **8-bit weights**, **32-bit accumulation**, and **ReLU activation**.
* **Argmax logic** built as combinational hardware.
* **Debug monitor** for inspecting hidden neuron activations on the 7-segment display.
* **Real FPGA-friendly optimizations**: pipelined MAC units, BRAM-based storage, clean FSM control.

---

## 🧩 **Architecture Overview**

### **1. Input Layer**

* 784 pixels from a 28×28 grayscale image
* Stored in **Block RAM / Distributed RAM**
* Selected using switches **SW[3:0]** (16 test images)

### **2. Hidden Layer (16 Neurons)**

* Operates in parallel
* MAC operations on 8-bit signed weights
* Accumulates into 32-bit registers
* Activation: **ReLU**

### **3. Output Layer (10 Neurons)**

* Linear activation to produce logits
* **Argmax block** instantly selects the predicted digit

### **4. Control FSM**

* Sequences:

  1. Input Fetch
  2. Hidden Layer MAC
  3. Output Layer MAC
  4. Argmax
  5. Display output

---

## 🔍 **Brain-Inspection Mode (Debug Monitor)**

A unique interactive feature:

* **SW[7:4]** → Select any hidden neuron (0–15)
* 7-segment display → Shows the neuron’s activation value
* Allows users to analyze the NN’s internal behavior in real-time

Perfect for **education**, **demo**, and **ML hardware interpretability**.

---

## 🛠️ **Nexys 4 DDR Hardware Mapping**

| Component     | Label          | Function                         |
| ------------- | -------------- | -------------------------------- |
| Switches      | **SW[3:0]**    | Select input test image (0–15)   |
| Switches      | **SW[7:4]**    | Select hidden neuron for debug   |
| Button Center | **BTNC**       | Start inference                  |
| Button        | **CPU_RESETN** | System reset                     |
| LED 0         | **LD0**        | Done signal (inference complete) |
| LEDs 4–1      | **LD4–LD1**    | 4-bit binary predicted digit     |
| 7-Segment     | —              | Shows hidden neuron activation   |

---

## 📁 **Project Structure**

```
├── rtl/
│   ├── FPGA_Top_Wrapper.v        # Handles board-level mapping
│   ├── mnist_mlp_accelerator.v   # Core NN datapath
│   ├── accelerator_controller.v  # FSM controller
│   ├── neurons.v                 # Hidden + output neuron modules
│   ├── mac_units.v               # Pipelined MAC units
│   └── display/                  # 7-seg driver + BCD encoder
│
├── python/
│   ├── train_model.py            # Keras training + quantization
│   ├── verify_mnist.py           # Bit-exact python simulator
│   └── generate_custom.py        # Generates 1/2/3/4 test shapes
│
├── memory_files/
│   ├── images16.mem              # 16 test images in hex
│   ├── hidden_weights.mem        # Layer 1 weights
│   ├── output_weights.mem        # Layer 2 weights
│   └── biases.mem                # Bias terms
│
└── constraints/
    └── nexys4ddr.xdc             # Pin mapping file
```

---

## 🚀 **How to Run**

### **1. Train & Quantize (Python)**

Generates all `.mem` files needed by the FPGA.

```bash
cd python
python train_model.py
```

---

### **2. Vivado FPGA Flow**

1. Create a project for **XC7A100T (Nexys 4 DDR)**
2. Add all RTL files
3. Add `.mem` files → **Enable "Copy sources into project"**
4. Add `nexys4ddr.xdc`
5. Run:

   * Synthesis
   * Implementation
   * Bitstream generation
6. Program via USB JTAG

---

## 📊 **Sanity-Check Verification**

A tiny geometric dataset is used for quick testing:

| SW Value | Shape         | Expected | LED Output |
| -------- | ------------- | -------- | ---------- |
| 0000     | Vertical line | 1        | 0001       |
| 0001     | S-shape       | 2        | 0010       |
| 0010     | E-shape       | 3        | 0011       |
| 0101     | Square-ish    | 5        | 0101       |

All shapes classify correctly on hardware, proving correctness.

---

## 🧾 **License**

Open-source — feel free to use, modify, or extend for educational or research use.

---

## ✍️ **Authors**

**Shreyas Singh**,
**Raghav Aggarwal**,
**Shreya Dixit**,
**Kirti Kumar**
**Date:** November 2025

---
