# Design IP SPI master and verify using UVM
## Introduce
My name is Vo Quang Huy. This project is Course Project 2 of a university course, focusing on the design and verification of a **SPI master IP**.
This repository contains the RTL design and UVM-based verification environment for an SPI Master core with an APB3 interface.

## Document
For further details, please refer to the full report linked below:
- [SPI Master IP Report](http://github.com/Venus-Lv5/APB3-to-SPI/blob/main/doc/Report_DA2_final.pdf).

## Tools and Methodology Used
- Languages: Verilog for RTL design and SystemVerilog for build environment and create testbenches and verification components.
- Methodology verification: UVM 1.2
- Tool: QuestaSim 2023.2

## Project Structure
The repository is organized into the following directories:

- `rtl/` - SPI master IP RTL source code.
- `vip/`
  - `spi_vip/` - UART VIP simulating UART transaction.
  - `apb_vip/` - APB VIP simulating AHB master transactions.
- `regmodel/` - UVM register model for SPI IP registers.
- `tb/` - UVM testbench components including environment, scoreboard, testbench.
- `sequences/` - Sequences to generate SPI or APB transactions.
- `testcases/` - Testcases to verify various functionalities.
- `sim/` - Simulation scripts and Makefile
- `docs/` - VPlan and documents

## IP Feature (RTL Design)
- APB3 interface for configuration and control
- Configurable data width (8/16 bits)
- Configurable all SPI modes (CPOL/CPHA)
- Configurable SCLK divider (8 bits):  SCLK = PCLK / (2 × (div_val + 1))
- Continuous transfer mode and multiple slave support
- TX/RX FIFO status is reported through interrupt signals.

## Register map
| Offset        | Register Name | Description |
|---------------|---------------|-------------|
| 0x4000_2000   | **LCR** (Line Control Register) | Configures SPI operation including data width, CPOL, CPHA, continuous transfer mode, and slave selection |
| 0x4000_2004   | **DLR** (Divisor Latch Register) | Configures the clock divider for SCLK generation |
| 0x4000_2008   | **IER** (Interrupt Enable Register) | Enables or disables interrupt sources related to TX/RX FIFO status |
| 0x4000_200C   | **FSR** (FIFO Status Register) | Reports current status of TX FIFO and RX FIFO |
| 0x4000_2010   | **TBR** (Transmitter Buffer Register) | Write data to be transmitted via SPI |
| 0x4000_2014   | **RBR** (Receiver Buffer Register) | Read data received from SPI |


### Line Control Register – LCR (0x4000_2000)
| Bit  | Name | Access | Description |
|-----:|------|:------:|-------------|
| 31:6 | RSVD | — | Reserved, must be written as 0 |
| 5:4  | SS   | R/W | Select SPI slave (00–11 corresponding to Slave 0–3) |
| 3    | CDTE | R/W | Enable/disable continuous transfer mode |
| 2    | CPHA | R/W | Configure SPI clock phase |
| 1    | CPOL | R/W | Configure SPI clock polarity |
| 0    | WLS  | R/W | Data frame width (0: 8-bit, 1: 16-bit) |

### Divisor Latch Register – DLR (0x4000_2004)
| Bit   | Name | Access | Description |
|------:|------|:------:|-------------|
| 31:8  | RSVD | — | Reserved, must be written as 0 |
| 7:0   | div_val | R/W | Clock divider value used to generate SCLK |

### Interrupt Enable Register – IER (0x4000_2008)
| Bit   | Name | Access | Description |
|------:|------|:------:|-------------|
| 31:4  | RSVD | — | Reserved, must be written as 0 |
| 3     | en_rx_fifo_empty | R/W | Enable interrupt when RX FIFO is empty |
| 2     | en_rx_fifo_full  | R/W | Enable interrupt when RX FIFO is full |
| 1     | en_tx_fifo_empty | R/W | Enable interrupt when TX FIFO is empty |
| 0     | en_tx_fifo_full  | R/W | Enable interrupt when TX FIFO is full |

### FIFO Status Register – FSR (0x4000_200C)
| Bit   | Name | Access | Description |
|------:|------|:------:|-------------|
| 31:4  | RSVD | — | Reserved |
| 3     | rx_fifo_empty_status | RO | RX FIFO empty status |
| 2     | rx_fifo_full_status  | RO | RX FIFO full status |
| 1     | tx_fifo_empty_status | RO | TX FIFO empty status |
| 0     | tx_fifo_full_status  | RO | TX FIFO full status |

### Transmitter Buffer Register – TBR (0x4000_2010)
| Bit   | Name | Access | Description |
|------:|------|:------:|-------------|
| 31:16 | RSVD | — | Reserved |
| 15:0  | tx_data | WO | Data written to TX FIFO for SPI transmission |

### Receiver Buffer Register – RBR (0x4000_2014)
| Bit   | Name | Access | Description |
|------:|------|:------:|-------------|
| 31:16 | RSVD | — | Reserved |
| 15:0  | rx_data | RO | Data received from SPI and stored in RX FIFO |

Reserved (RSVD) bits should be written as 0 and are ignored on read.

## SPI Master IP Structure
This is my RTL structure for SPI master IP:
![SPI master IP structure](https://github.com/Venus-Lv5/APB3-to-SPI/blob/main/doc/rtl_structure.png)
- **APB Slave**: Acts as the interface between the APB bus and the SPI IP, handling APB read/write transactions and providing access to internal registers for configuration and status monitoring.
- **Register Block**: Stores configuration and status information such as CPOL/CPHA mode, SCLK clock divider, slave selection, interrupt control, and transmit/receive data.
- **TX FIFO**: Buffers data written from the APB interface before being transmitted by the SPI Master, and provides FIFO status information.
- **RX FIFO**: Buffers data received from the SPI Master via MISO before being read by the APB master, and reports FIFO status.
- **Interrupt Controller**: Generates interrupt requests based on TX/RX FIFO status, with interrupt sources enabled or disabled via configuration registers.
- **SPI Master**: Core block that performs SPI data transmission and reception. It generates SCLK, drives MOSI, samples MISO according to CPOL/CPHA configuration, and controls slave select signals (CS/SS).

### SPI Master Commonent Structure
![SPI master block structure](https://github.com/Venus-Lv5/APB3-to-SPI/blob/main/doc/spi_master_component.png)
- **SCLK Generator**: Generates the SPI clock (SCLK) by dividing the system clock (PCLK) using the divider value configured in the Divisor Latch Register (DLR). The generated SCLK is used to synchronize data transfer with the SPI slave.
  The SCLK frequency is approximately calculated as:
  f_SCLK ≈ f_PCLK / (2 × (div_val + 1))
  where `div_val` is a programmable divider value ranging from 0 to 255.
- **Data Transmit/Receive Block**: Handles serial data shifting on MOSI and sampling data from MISO according to the configured SPI mode (CPOL/CPHA). Its operation is controlled by the SPI controller.
- **Slave Select Block**: Decodes the slave selection signals and drives the corresponding chip select outputs (CS/SS0–CS/SS3).
- **SPI Controller**: Acts as the central control unit of the SPI Master. It coordinates the operation of all sub-blocks, manages SPI transfer sequencing, and interfaces with TX/RX FIFOs for data transmission and reception.

## Testbench Structure
Below is my Testbench structure to verify the UART IP.
![Testbench structure to verify the VIP](https://github.com/Venus-Lv5/APB3-to-SPI/blob/main/doc/tb_structure.png)

- **Base Test**: Acts as the top-level test, responsible for initializing the testbench, applying configuration objects, and controlling test execution flow.
- **APB Configuration**: Defines APB-related parameters such as bus timing, default register values, and interrupt behavior. This configuration is applied in the base test and shared with the APB agent.
- **SPI Configuration**: Stores SPI protocol parameters including CPOL, CPHA, data width, clock divider, slave selection, and transfer mode. These parameters control the behavior of the SPI agent and expected DUT operation.
- **SPI Environment (spi_env)**: The main verification environment that integrates SPI and APB agents, scoreboard, register model, predictor, and adapters.
- **SPI Agent**: Verifies SPI protocol behavior.
  - **spi_sequencer**: Generates SPI transactions based on test scenarios.
  - **spi_driver**: Drives SPI signals (SCLK, MOSI, SS) to the DUT via the SPI virtual interface.
  - **spi_monitor**: Monitors SPI bus activity and sends observed transactions to the scoreboard.
- **APB Agent**: Handles register access and control through the APB bus.
  - **apb_sequencer**: Generates APB read/write transactions.
  - **apb_driver**: Drives APB bus signals to the DUT via the APB virtual interface.
  - **apb_monitor**: Observes APB transactions for prediction and checking.
- **Register Model (apb_reg_block)**: Implements the UVM Register Abstraction Layer (RAL) for SPI control and status registers.
- **Adapter & Predictor**: Translate APB register accesses into SPI-level expectations and update the register model based on monitored transactions.
- **Scoreboard**: Compares SPI and APB transactions with DUT behavior to ensure functional correctness.

## Verification Plan
You can find the full verification strategy and test details and testbench structure in the VPlan:  
- [Verification Plan](https://github.com/Venus-Lv5/APB3-to-SPI/blob/main/doc/Vplan_SPI_master.csv).

## How to use
- Config file `project_env.bash` with your UVM library location
- Go to `sim\`
- Run source `project_env.bash` to set up the environment.
- Use `make build` to compile the design.
- Use `make help` to see available commands and usage instructions.

## Result
- Open `sim/regress.rpt` to check the results of the testcases.
- Open `sim/log/` to check the individual logs for each testcase.
- Open `IP_MERGE.ucdb` with QuestaSim to check the coverage results.

## Conclusion
There may still be mistakes — any feedback or suggestions for improvement would be greatly appreciated.

Thank you very much
