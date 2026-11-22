# Design and Performance Analysis of a 2-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache

> **Project Status: Phase I & Phase II Complete — Full Integration, Verification & Final IEEE Report Ready**  
> *Both Direct-Mapped and 2-Way Set-Associative Caches fully implemented, integrated with shared behavioral memory (`top_module.v`), verified across 96 hardware assertions, benchmarked across 4 standardized workloads, and documented in IEEE Conference format.*

---

## 📌 Project Reports & Deliverables (PDF Format)

- 📄 **Phase I Report (PDF):** [`docs/IEEE_REPORT_PHASE1.pdf`](docs/IEEE_REPORT_PHASE1.pdf) *(Phase I Submission)*
- 📄 **Phase II Report (PDF):** [`docs/IEEE_REPORT_PHASE2.pdf`](docs/IEEE_REPORT_PHASE2.pdf) *(Phase II Final Submission)*
- 📑 **Combined Full Report (PDF):** [`docs/IEEE_REPORT.pdf`](docs/IEEE_REPORT.pdf) *(Comprehensive Final Project Report)*
- 🎥 **Prototype Demo Video Link:** [Google Drive Demo Video (5-Minute Walkthrough)](https://drive.google.com/file/d/1s9-p3VAnroPm70vCqMKWxDDHWJo9CIOd/view?usp=sharing)
- 📊 **Integration Benchmark Results:** [`results/sim_top.log`](results/sim_top.log) & [`results/performance_comparison.csv`](results/performance_comparison.csv)
- 📁 **Top-Level Integration Wrapper:** [`rtl/top_module.v`](rtl/top_module.v)
- 🧪 **Comparative Benchmark Testbench:** [`tb/tb_top.v`](tb/tb_top.v)
- 💻 **Commands to Run on Terminal:**
  ```bash
  make sim_top   # Runs Phase II integration benchmark comparing both caches side-by-side
  make sim       # Runs automated regression suite across all modular unit testbenches
  ```

---

## 🏆 Key Phase II Benchmark Results (46 Total Requests)

| Access Workload | Total Requests | Direct-Mapped Hits | 2-Way LRU Hits | Hit Rate (DM / 2-Way) | Associativity Advantage |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Sequential Stream** | 16 | 8 | 8 | 50.0% / 50.0% | Tie (equal capacity) |
| **Temporal Repetition** | 8 | 6 | 6 | 75.0% / 75.0% | Tie (no conflict) |
| **Conflict-Heavy (Thrashing)** | **12** | **0** | **10** | **0.0% / 83.3%** | **+83.3% (Eliminates Thrashing!)** |
| **Mixed Interleaved** | 10 | 5 | 6 | 50.0% / 60.0% | +10.0% advantage |
| **OVERALL TOTAL** | **46** | **19** | **30** | **41.3% / 65.2%** | **+23.9% Net Advantage** |

- **Total Verification Assertions:** **96 / 96 PASS (100% Pass Rate)**
  - Direct-Mapped Unit Tests (`tb_direct.v`): 17/17 PASS
  - 2-Way Datapath Tests (`tb_cache_2way_keshav.v`): 26/26 PASS
  - 2-Way Extended Suite (`tb_2way.v`): 18/18 PASS
  - LRU & FSM Tests (`tb_lru_fsm.v`): 24/24 PASS
  - Phase II Integration Benchmark (`tb_top.v`): 11/11 PASS

---

## 1. Project Overview

This college project explores the architectural design, Verilog HDL modeling, and comparative performance evaluation of two fundamental CPU cache organizations:
1. **A 2-Way Set-Associative Cache** featuring a **Least Recently Used (LRU)** line replacement policy.
2. **A Direct-Mapped Cache** of equivalent storage capacity.

Cache memory sits between the high-speed processor core and relatively slow main memory to bridge the Von Neumann memory latency bottleneck. By implementing both cache architectures under identical capacity and memory configurations, this project aims to evaluate how set-associativity and replacement logic influence cache hit rates, conflict misses, latency, and hardware resource utilization.

---

## 2. Problem Statement

Modern microprocessors require fast memory access to sustain execution throughput. However, dynamic memory (DRAM/Main Memory) is significantly slower than processor clock cycles. Direct-mapped caches provide fast access times and low hardware complexity, but suffer from high **conflict miss rates** when multiple active memory blocks map to the exact same cache line.

A set-associative cache mitigates conflict misses by providing multiple lines ("ways") per set, allowing competing memory addresses to reside in cache simultaneously. However, this flexibility requires replacement decision logic (such as LRU) and increases hardware complexity. 

This project addresses the design trade-offs between hardware complexity, hit/miss rates, and access penalties by creating baseline hardware models of both cache topologies in Verilog HDL and comparing their behavior under standardized memory access traces.

---

## 3. Project Objectives

- **Architectural Modeling:** Formulate functional specifications and structural block diagrams for both a Direct-Mapped and a 2-Way Set-Associative cache.
- **RTL Design (Verilog HDL):** Model the datapath, tag comparison, hit/miss detection logic, and finite state machines (FSM) controlling cache-to-memory transactions.
- **LRU Policy Realization:** Implement a hardware LRU tracking mechanism (1-bit state per set for 2-way associativity) to dictate line eviction on misses.
- **Memory Subsystem Integration:** Interface both cache controllers with a simulated 256-byte synchronous main memory module.
- **Verification & Comparative Benchmarking:** Develop verification testbenches with deterministic access patterns (e.g., sequential loops, ping-pong address thrashing) to quantify hit/miss ratios, conflict miss reduction, and access cycles.

---

## 4. Hardware Configuration & Specifications

Both cache architectures are constrained to identical overall storage capacities and operate on an 8-bit memory address space to allow direct, apples-to-apples performance comparisons.

### System Parameters

| Parameter | Specification | Notes |
|:---|:---|:---|
| **Address Width** | 8 bits (`[7:0]`) | Supports a 256-byte physical address space |
| **Data Width** | 8 bits (`[7:0]`) | 1-byte data word per memory location |
| **Main Memory Size** | 256 × 8 bits (256 bytes) | Byte-addressable synchronous storage |
| **Cache Block / Line Size** | 1 byte | Single-byte block transfer (0 offset bits) |
| **Total Cache Capacity** | 8 bytes | Storage for 8 data entries across both architectures |
| **Two-Way Set-Associative** | 4 sets × 2 ways | 8 lines total across 4 sets |
| **Direct-Mapped Cache** | 8 lines (8 sets × 1 way) | 8 lines total, 1 line per set |
| **Replacement Policy** | Least Recently Used (LRU) | Applied to the 2-Way Set-Associative design |

---

## 5. Address Mapping & Bit Allocations

With an 8-bit address space ($2^8 = 256$ addresses) and 1-byte cache blocks, no intra-block offset bits are required ($2^0 = 1$ byte).

```
================================================================================
Two-Way Set-Associative Address Decomposition (4 Sets, 2 Ways, 1 Byte/Block)
--------------------------------------------------------------------------------
Bit:      [7]       [6]       [5]       [4]       [3]       [2]   |  [1]     [0]
Field:                          TAG (6 bits)                      |  SET INDEX (2 bits)
================================================================================

================================================================================
Direct-Mapped Address Decomposition (8 Lines, 1 Byte/Block)
--------------------------------------------------------------------------------
Bit:      [7]       [6]       [5]       [4]       [3]   |  [2]     [1]     [0]
Field:                  TAG (5 bits)                    |  LINE INDEX (3 bits)
================================================================================
```

### 1. Two-Way Set-Associative Cache (4 Sets × 2 Ways)
- **Tag:** `address[7:2]` (6 bits) — Checked against both Way 0 and Way 1 tags simultaneously.
- **Set Index:** `address[1:0]` (2 bits) — Selects 1 of the 4 cache sets ($2^2 = 4$).
- **Block Offset:** None (0 bits, 1-byte block).

### 2. Direct-Mapped Cache (8 Lines)
- **Tag:** `address[7:3]` (5 bits) — Checked against the stored tag of the selected line.
- **Line Index:** `address[2:0]` (3 bits) — Directly addresses 1 of the 8 cache lines ($2^3 = 8$).
- **Block Offset:** None (0 bits, 1-byte block).

---

## 6. Proposed Architecture Overview

```
                          +-------------------+
                          | CPU / Host Master |
                          +---------+---------+
                                    | [Addr, Data, Read/Write]
                                    v
                 +--------------------------------------+
                 | Cache Controller (Direct-Mapped /    |
                 | 2-Way Set-Associative with LRU)      |
                 +------------------+-------------------+
                                    | Memory Bus Interface
                                    v
                          +-------------------+
                          | Main Memory       |
                          | (256 x 8-bit RAM) |
                          +-------------------+
```

- **Direct-Mapped Cache:** Uses a single memory array for data and tags. When an address is requested, the 3-bit line index selects the line, and if valid bit = 1 and tag matches, a **Hit** is flagged. On a **Miss**, the existing line is replaced immediately by data fetched from main memory.
- **2-Way Set-Associative Cache:** Divides the 8 lines into 4 sets with 2 ways (`Way 0` and `Way 1`). When an address is presented, the 2-bit set index accesses both ways concurrently. Dual comparators verify tags in parallel. On a **Miss**, a dedicated 1-bit LRU register for that set identifies which way was least recently accessed to select the replacement victim.
- **Memory Interface & Controller FSM:** Coordinates states (`IDLE`, `COMPARE_TAG`, `ALLOCATE` / `WRITE_BACK`) to handle hit service, miss latency, and synchronization with main memory.

*(For detailed architectural specifications, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).)*

---

## 7. Technology Stack & Planned Tooling

- **Hardware Description Language:** Verilog HDL (IEEE 1364-2001 / IEEE 1364-2005)
- **Simulation Engine:** Icarus Verilog (`iverilog`) / ModelSim / QuestaSim
- **Waveform Viewer:** GTKWave (`.vcd` dump analysis)
- **Build & Automation:** Shell scripts / Makefiles (planned in `sim/`)
- **Documentation:** Markdown & block diagrams

---

## 8. Planned Implementation Roadmap

- [x] **Phase 1: Project Initialization & Architectural Definition**
  - Repository structure creation
  - Git configuration and `.gitignore` setup
  - Architectural requirements and signal definition ([`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md))
  - Team task breakdown and ownership ([`docs/TEAM_RESPONSIBILITIES.md`](docs/TEAM_RESPONSIBILITIES.md))
- [ ] **Phase 2: Core RTL Development**
  - [x] Direct-mapped cache datapath and control unit ([`docs/DIRECT_MAPPED_CACHE.md`](docs/DIRECT_MAPPED_CACHE.md))
  - [ ] 2-way set-associative cache datapath and dual tag comparators
  - [ ] LRU replacement tracking logic and controller FSM
  - [ ] 256 × 8-bit synchronous main memory behavioral model
- [ ] **Phase 3: Verification & Testbench Implementation**
  - [x] Unit testbench for direct-mapped cache (`tb/tb_direct.v` - 31/31 tests passing)
  - [ ] Unit testbenches for 2-way cache module
  - [ ] Synthetic access pattern generators (thrashing, localized loops, sequential streams)
  - [ ] Memory interaction assertions and latency monitors
- [ ] **Phase 4: Comparative Simulation & Performance Analysis**
  - Execution of comparative simulation suites
  - Hit/miss rate extraction and conflict miss analysis
  - GTKWave waveform verification
  - Final report preparation and conclusion

---

## 9. Repository Structure

```
2-way-set-associative-cache-lru/
│
├── README.md               # Project overview, specifications, and roadmap
├── .gitignore              # Ignores EDA artifacts, waveforms, and temporary outputs
│
├── rtl/                    # Synthesizable Verilog modules (Planned)
│   └── .gitkeep
│
├── tb/                     # Testbenches and verification environments (Planned)
│   └── .gitkeep
│
├── sim/                    # Simulation scripts, Makefiles, and runner tools (Planned)
│   └── .gitkeep
│
├── build/                  # Compiled binaries and simulator executables (Ignored)
│   └── .gitkeep
│
├── waveforms/              # Value Change Dump (.vcd) waveform files (Ignored)
│   └── .gitkeep
│
├── results/                # Simulation logs, hit/miss statistics, reports (Ignored)
│   └── .gitkeep
│
└── docs/                   # Architectural notes, team logs, and schematics
    ├── ARCHITECTURE.md     # Detailed microarchitectural specifications
    ├── TEAM_RESPONSIBILITIES.md # Roles and deliverables for all team members
    └── diagrams/           # Block diagrams and state charts
        └── .gitkeep
```

---

## 10. Team Members & Responsibilities

| Member | Primary Responsibility | Primary Focus Area |
|:---|:---|:---|
| **Yash** | Project Architecture & Repository Setup | Specification authoring, repository hygiene, module interfacing, system integration |
| **Keshav** | Two-Way Cache RTL | 2-way set-associative datapath, storage arrays, parallel tag comparators |
| **Shitanshu** | LRU Replacement & Cache FSM | 1-bit LRU update unit, cache controller FSM (Hit/Miss/Fetch states) |
| **Shivam** | Direct-Mapped Cache RTL | Direct-mapped cache datapath, tag/valid arrays, hit/miss detection |
| **Kaavya** | Testbenches & Simulation | Test vector generation, memory modeling, simulation scripts, GTKWave analysis |

*(For full deliverable breakdowns, see [`docs/TEAM_RESPONSIBILITIES.md`](docs/TEAM_RESPONSIBILITIES.md).)*

