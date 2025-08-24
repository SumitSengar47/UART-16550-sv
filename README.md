# SystemVerilog UART Implementations: From Basics to 16550-Standard

[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.md)

A project showcasing two distinct UART (Universal Asynchronous Receiver-Transmitter) designs in SystemVerilog: a foundational model for educational purposes and a feature-complete, 16550-compatible controller for practical applications.

---

## 1. Simplified UART: The Core Concepts

This implementation is the ideal starting point for understanding the fundamentals of serial communication. It strips away advanced features to provide a clear, uncluttered view of the core transmit and receive logic.

#### Block Diagram
The simplified UART consists of just two main blocks: a transmitter that serializes parallel data and a receiver that deserializes incoming serial data.

<!-- TODO: Add your simple UART block diagram image here -->
![Simple UART Block Diagram](https://vanhunteradams.com/Protocols/UART/uart_hardware.png)

#### Features & Implementation Details
-   **Purpose**: Designed for learning and quick prototyping.
-   **Core Logic**: Contains only the essential transmitter (`uart_tx`) and receiver (`uart_rx`) modules.
-   **Functionality**: Handles basic serialization (parallel-to-serial) and deserialization (serial-to-parallel) with start and stop bits.
-   **Files**:
    -   `UART-Simple/uart_top.sv`: Top-level module for the simple UART.
    -   `UART-Simple/uart_tb.sv`: A self-contained testbench to verify its operation.

#### Simulation Waveform
AThis waveform demonstrates the simple UART transmitting the ASCII character '7A' (`8'h7A`). You can see the parallel data `dintx[7:0]` being serialized on the `tx` line, framed by a start bit (low) and a stop bit (high).

<!-- TODO: Add your simple UART simulation waveform image here -->
![Simple UART Waveform](https://github.com/SumitSengar47/UART-16550-sv/blob/744cc650a47d138f7389f1e4cabaabeeb48ebdf8/UART-Simple/simple_uart_tb.png)

---

## 2. Advanced UART 16550 Controller

This is a comprehensive, synthesizable implementation modeled after the industry-standard 16550 UART. It incorporates FIFO buffers and a full register set, making it suitable for integration into larger systems like SoCs where efficient data handling is critical.

#### High-Level Schematic
The diagram below illustrates the architecture of the full 16550 UART, showing how the transmitter, receiver, FIFOs, and register file are interconnected.

![image](https://www.beyondsemi.com/images/moduli/5efdba5dfd43b4dc477fd9058df34fa9.png)


#### Implemented Modules
-   **`2_fifo_top.sv`**: A generic, parameterizable FIFO buffer used for both the transmit and receive data paths. This is crucial for preventing data loss and reducing processor interrupt frequency.
-   **`3_uart_tx_top.sv`**: The transmitter module. It fetches data from the TX FIFO, adds framing bits (start/stop), and serializes it.
-   **`4_uart_rx_top.sv`**: The receiver module. It samples the incoming serial line, validates the framing, and pushes the received data into the RX FIFO.
-   **`5_regs_uart.sv`**: Implements the memory-mapped register file for configuration (baud rate, data bits, etc.) and status checking. It also contains the programmable baud rate generator.
-   **`1_all_mod.sv`**: The top-level wrapper that integrates all the above modules into a single, cohesive 16550-compatible unit.

#### Schematic
![image](https://github.com/SumitSengar47/UART-16550-sv/blob/761f03b2e0589e6330a806535ad0d1ce5eb8eb3f/uart_16550.png)

#### Simulation Waveform
This waveform shows a more complex transaction involving the 16550's register interface and FIFO buffers.

<!-- TODO: Add your 16550 simulation waveform image here -->
![UART 16550 Waveform](<path_to_your_16550_waveform.png>)

---

## 🗺️ Future Work

The following enhancements are planned to make this project even more complete:
-   [ ] **Interrupt Logic**: Implement the full interrupt generation and control system to be fully 16550-compliant.
-   [ ] **Advanced Verification**: Develop a UVM testbench with constrained-random testing for more robust verification.
-   [ ] **CPU Integration Example**: Provide a complete example showing integration with a RISC-V core in an SoC.
-   [ ] **FPGA Synthesis & Validation**: Add synthesis scripts and demonstrate the UART's operation on actual hardware.
