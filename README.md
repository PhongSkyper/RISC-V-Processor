# RISC-V Processor Implementation

🚀 **Thiết kế và triển khai bộ vi xử lý RISC-V 32-bit trên FPGA**

Dự án này bao gồm hai giai đoạn phát triển:
1. **Single Cycle** - Thiết kế đơn chu kỳ cơ bản
2. **Pipeline** - Thiết kế pipeline 5 tầng với xử lý hazard

---

## 📋 Tổng Quan Dự Án

Project này triển khai bộ xử lý RISC-V 32-bit (RV32I) từ kiến trúc cơ bản đến kiến trúc pipeline tối ưu. Tất cả module được viết bằng SystemVerilog và đã được kiểm chứng trên FPGA DE2/DE10.

### ✨ Tính Năng Chính

- **ISA Support**: RV32I Base Integer Instruction Set
- **Architecture**: Single Cycle + Pipeline (5-stage)
- **Hazard Handling**: Data forwarding, Load hazard detection
- **Memory**: Instruction memory + Data memory (LSU)
- **I/O**: Timer, GPIO peripherals
- **Verification**: Testbench với SystemVerilog

---

## 📁 Cấu Trúc Thư Mục

```
RISC-V-Project/
│
├── docs/                           # 📄 Tài liệu và sơ đồ thiết kế
│   ├── single_cycle_block.jpg      # Sơ đồ khối Single Cycle
│   ├── alu_design.jpg              # Thiết kế ALU
│   ├── lsu.jpg                     # Load-Store Unit
│   ├── regfile.jpg                 # Register File
│   └── KTMT_L01_Group_23.pdf       # Báo cáo chi tiết
│
├── rtl/                            # 💻 Source Code (SystemVerilog)
│   │
│   ├── single_cycle/               # Giai đoạn 1: Thiết kế đơn chu kỳ
│   │   ├── single_cycle.sv         # Top module
│   │   ├── alu.sv                  # Arithmetic Logic Unit
│   │   ├── regfile.sv              # Register File (32x32-bit)
│   │   ├── control_logic.sv        # Control Unit
│   │   ├── immgen.sv               # Immediate Generator
│   │   ├── lsu.sv                  # Load-Store Unit
│   │   ├── inst_mem.sv             # Instruction Memory
│   │   ├── brc.sv                  # Branch Comparator
│   │   └── ...                     # Các module phụ trợ
│   │
│   └── pipeline/                   # Giai đoạn 2: Thiết kế Pipeline
│       │
│       ├── model1_non_forwarding/  # Model 1: Không có forwarding
│       │   ├── pipelined.sv        # Top module pipeline
│       │   ├── fetch_stage.sv      # IF Stage
│       │   ├── decode_stage.sv     # ID Stage
│       │   ├── execute_stage.sv    # EX Stage
│       │   ├── mem_stage.sv        # MEM Stage
│       │   ├── wb_stage.sv         # WB Stage
│       │   ├── hazard_detection_load.sv  # Hazard Detection
│       │   ├── stage_*.sv          # Pipeline Registers
│       │   └── ...
│       │
│       └── model2_forwarding/      # Model 2: Có data forwarding
│           ├── pipelined.sv        # Top module với forwarding
│           ├── forward_control.sv  # Forwarding Control Unit
│           ├── hazard_detection_load.sv
│           ├── stage_*.sv          # Pipeline Registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
│           └── ...
│
└── simulation/                     # 🧪 Testbench và Verification
    │
    ├── tb_single_cycle/            # (Nếu có testbench riêng cho single cycle)
    │
    └── tb_pipeline/                # Testbench cho pipeline
        ├── model1_non_forwarding/
        │   ├── tbench.sv           # Top testbench
        │   ├── driver.sv           # Driver module
        │   ├── scoreboard.sv       # Scoreboard
        │   └── tlib.svh            # Test library
        │
        └── model2_forwarding/
            ├── tbench.sv
            ├── driver.sv
            ├── scoreboard.sv
            └── tlib.svh
```

---

## 🏗️ Kiến Trúc Thiết Kế

### 1. Single Cycle Architecture

Thiết kế đơn chu kỳ cơ bản với datapath và control unit:
- **Datapath**: PC → Instruction Memory → Decode → Execute → Memory → Write Back
- **Control Unit**: Giải mã instruction và sinh control signals
- **Thời gian chu kỳ**: Phụ thuộc vào đường dẫn dài nhất (critical path)

```
┌──────┐   ┌─────┐   ┌─────┐   ┌─────┐   ┌──────┐
│  PC  │ → │ IM  │ → │ DEC │ → │ ALU │ → │ MEM  │ → WB
└──────┘   └─────┘   └─────┘   └─────┘   └──────┘
```

### 2. Pipeline Architecture (5-Stage)

Pipeline 5 tầng với xử lý hazards:

```
┌────┐   ┌────┐   ┌────┐   ┌────┐   ┌────┐
│ IF │ → │ ID │ → │ EX │ → │MEM │ → │ WB │
└────┘   └────┘   └────┘   └────┘   └────┘
```

**Pipeline Stages:**
1. **IF (Instruction Fetch)**: Lấy instruction từ memory
2. **ID (Instruction Decode)**: Giải mã + đọc registers
3. **EX (Execute)**: Thực thi ALU operations
4. **MEM (Memory Access)**: Truy cập data memory
5. **WB (Write Back)**: Ghi kết quả vào register file

**Hazard Handling:**
- ✅ **Data Forwarding** (Model 2): Chuyển tiếp kết quả từ EX/MEM, MEM/WB về EX stage
- ✅ **Load Hazard Detection**: Phát hiện và stall pipeline khi cần
- ⚠️ **Branch Prediction**: Assume not taken (flush pipeline nếu sai)

---

## 🚀 Hướng Dẫn Sử Dụng

### Yêu Cầu

- **Simulator**: ModelSim / Questa / VCS
- **FPGA Tools**: Intel Quartus Prime (nếu synthesize cho DE2/DE10)
- **Language**: SystemVerilog

### Simulation

#### Chạy Single Cycle:
```bash
# Compile
vlog -sv rtl/single_cycle/*.sv

# Simulate
vsim -c single_cycle -do "run -all"
```

#### Chạy Pipeline (Model 2 - Forwarding):
```bash
# Compile RTL
vlog -sv rtl/pipeline/model2_forwarding/*.sv

# Compile Testbench
vlog -sv simulation/tb_pipeline/model2_forwarding/*.sv

# Simulate
vsim -c tbench -do "run -all"
```

### Synthesize trên FPGA

1. Mở Quartus Prime
2. Tạo project mới và import các file `.sv` từ `rtl/single_cycle/` hoặc `rtl/pipeline/`
3. Chọn target FPGA (DE2: Cyclone IV, DE10: MAX 10)
4. Compile và program lên board

---

## 📊 Kết Quả Thực Nghiệm

### Performance Comparison

| Metric                  | Single Cycle | Pipeline (No Forward) | Pipeline (Forward) |
|-------------------------|--------------|----------------------|-------------------|
| **CPI**                 | 1.0          | ~1.3                 | ~1.1              |
| **Max Frequency**       | ~50 MHz      | ~100 MHz             | ~95 MHz           |
| **Throughput**          | Low          | Medium               | High              |
| **Area (LEs)**          | ~2500        | ~3200                | ~3500             |

> **Lưu ý**: Số liệu trên FPGA Cyclone IV E (DE2-115)

---

## 📖 Instruction Set Support

### Supported Instructions (RV32I)

#### Arithmetic & Logic:
- `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`
- `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`
- `SLT`, `SLTU`, `SLTI`, `SLTIU`
- `LUI`, `AUIPC`

#### Memory Access:
- **Load**: `LB`, `LH`, `LW`, `LBU`, `LHU`
- **Store**: `SB`, `SH`, `SW`

#### Control Flow:
- **Branch**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- **Jump**: `JAL`, `JALR`

---

## 🤝 Đóng Góp

Dự án này được phát triển bởi nhóm sinh viên Đại học Bách Khoa TP.HCM.

### Contributors:
- **Nhóm**: Group 23 - Kiến Trúc Máy Tính L01
- **Giảng viên hướng dẫn**: (Tên GV)

---

## 📝 Tài Liệu Tham Khảo

1. [RISC-V Specifications](https://riscv.org/technical/specifications/)
2. [RV32I Base Integer Instruction Set](https://github.com/riscv/riscv-isa-manual)
3. Computer Organization and Design: RISC-V Edition (David Patterson & John Hennessy)

---

## 📧 Liên Hệ

Nếu có câu hỏi hoặc đóng góp, vui lòng tạo Issue hoặc Pull Request trên GitHub.

---

## 📄 License

MIT License - Free to use for educational purposes.

---

**⭐ Nếu project hữu ích, đừng quên cho 1 star nhé! ⭐**
