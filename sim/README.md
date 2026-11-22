# Simulation Environment & Scripts

This folder contains guidelines and scripts for compiling and running simulations using **Icarus Verilog (`iverilog`)** and inspecting waveforms via **GTKWave**.

---

## Tool Prerequisites
- **Icarus Verilog:** `iverilog` and `vvp`
- **Waveform Viewer:** `gtkwave`

---

## Reproducible Regression

From the repository root, run:

```bash
make test
```

This compiles and runs the direct-mapped test, both two-way tests, the LRU and
reference-FSM test, the self-checking top-level integration test, and the result
parser. Any failed check, timeout, compiler error, or simulator failure returns a
nonzero status.

Generated performance datasets are kept separate:

- `results/performance_integration_2addr.csv`: two-address integration conflict trace.
- `results/performance_unit_3addr.csv`: three-address modular conflict trace.
- `results/performance_comparison.csv`: legacy per-trace modular table.

## Individual Simulation Commands

### 1. Direct-Mapped Cache Simulation
```bash
# Compile
iverilog -g2001 -o ../build/sim_direct.vvp ../rtl/cache_direct.v ../tb/tb_direct.v

# Execute
vvp ../build/sim_direct.vvp

# View Waveforms
gtkwave ../waveforms/direct_cache.vcd
```

### 2. 2-Way Set-Associative Cache Simulation
```bash
# Compile
iverilog -g2001 -o ../build/sim_2way.vvp ../rtl/cache_2way.v ../rtl/lru_controller.v ../tb/tb_2way.v

# Execute
vvp ../build/sim_2way.vvp

# View Waveforms
gtkwave ../waveforms/2way_cache.vcd
```

`cache_fsm.v` is tested separately by `make sim_lru_fsm`; it is not instantiated
by `cache_2way.v`.

### 3. Top-Level Comparative Benchmark
```bash
# Compile
iverilog -g2001 -o ../build/sim_top.vvp ../rtl/*.v ../tb/tb_top.v

# Execute
vvp ../build/sim_top.vvp
```

