# UART-16550-sv

SystemVerilog implementation of the **UART 16550** serial communication controller.  
This project contains a **full 16550-compatible UART** (with TX, RX, FIFO, registers, and baud generator) and a **simplified UART model** for basic understanding.  
Each module includes its own **self-contained testbench** for easier verification.

![image](https://www.beyondsemi.com/images/moduli/5efdba5dfd43b4dc477fd9058df34fa9.png)

---

## 📌 Features
- **Transmit (TX) and Receive (RX) support**  
- **FIFO buffers** for TX and RX data handling  
- **Configurable Baud Rate Generator**  
- **Register Interface** (control, status, and data registers)  
- **SystemVerilog Implementation** of UART 16550  
- **Simple Verilog UART model** for learning and quick testing  
- **Integrated testbenches** provided inside module files  

---

## 🏗️ Implementation Details
### 🔹 Core Modules
- **FIFO (`2_fifo_top.sv`)**: Implements transmit and receive FIFOs.  
- **UART TX (`3_uart_tx_top.sv`)**: Transmitter logic (start/stop bits, data serialization).  
- **UART RX (`4_uart_rx_top.sv`)**: Receiver logic (data sampling, stop bit check, deserialization).  
- **Registers & Baud Generator (`5_regs_uart.sv`)**: Register interface + baud clock divider.  
- **All Modules (`1_all_mod.sv`)**: Integrates TX, RX, FIFOs, and registers into one complete UART 16550 unit.  

### 🔹 Simple UART
- **`uart_top.sv`**: Basic TX/RX-only UART (no FIFOs or registers).  
- **`uart_tb.sv`**: Testbench for validating simple UART operation.  

---

## 🧪 Testbench Information
- Each **module file contains its own testbench**.  
- Allows **individual verification** of FIFO, TX, RX, and Registers.  
- For full system verification, use:
  - `UART-16550/1_all_mod.sv` → integrates everything  
  - `UART-Simple/uart_tb.sv` → for simple UART demo  

---
## 🔧 Schematic
![image](https://github.com/SumitSengar47/UART-16550-sv/blob/761f03b2e0589e6330a806535ad0d1ce5eb8eb3f/uart_16550.png)

---

## 📌 Future Work

- Add interrupt support (to fully match 16550 spec)
- Extend verification with randomized testbenches
- Provide integration example with RISC-V CPU
- FPGA synthesis and hardware validation
