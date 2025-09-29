Low-Power Neural Accelerator for Edge AI Applications
Overview

This project explores the design and evaluation of a low-power neural network accelerator, focusing on energy-efficient classification tasks.
We target ECG signal classification (healthy vs. abnormal heartbeats) and MNIST digit recognition as benchmarks to measure performance.

The goal is to demonstrate how hardware-aware optimizations and lightweight neural architectures can significantly reduce power consumption without compromising accuracy, making the solution suitable for edge and wearable devices.

Objectives

Design a neural accelerator optimized for low power consumption.

Implement and train models for:

ECG signal classification (binary classification).

MNIST digit classification (multi-class baseline).

Compare results with traditional CPU/GPU inference.

Evaluate trade-offs in accuracy, power, latency, and memory footprint.

Methodology

Model Development

Train lightweight neural networks for ECG and MNIST.

Optimize using quantization, pruning, and reduced precision arithmetic.

Accelerator Design

Implement hardware-inspired accelerator simulation.

Explore systolic arrays, parallelism, and low-bit multipliers.

Performance Evaluation

Compare accelerator vs. CPU/GPU in terms of:

Accuracy

Power/Energy consumption

Latency

Model size

Results (Expected)

Significant power savings with minimal accuracy drop.

Demonstration of feasibility for real-time ECG monitoring on low-power devices.

Team Contributions

Model Training & ECG Data Processing – Preprocessing ECG signals and building the classifier.

MNIST Baseline Development – Training a compact CNN for MNIST.

Accelerator Design & Simulation – Developing hardware-aware modules for efficiency.

Performance Analysis – Comparing energy, accuracy, and latency metrics.

Documentation & Integration – Structuring repository, writing reports, and combining results.

Applications

Wearable health monitoring (ECG devices).

IoT edge computing for pattern recognition.

Low-power AI accelerators for mobile and embedded systems.
