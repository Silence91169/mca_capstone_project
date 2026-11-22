// =============================================================================
// Testbench: tb_top
// Project: Design and Performance Analysis of a 2-Way Set-Associative Cache
//          with LRU Replacement Compared with a Direct-Mapped Cache
// Component: Integration-Level Comparative Benchmark Testbench
// Assigned Member: Kaavya (Member 5 — Verification Lead)
// Language: Verilog-2001
// Phase: Phase II — Integration & Results
// =============================================================================
//
// DESCRIPTION:
//   Feeds four identical address-trace workloads to both cache subsystems
//   through top_module. Each workload runs twice (once per cache). Hit/Miss
//   counts are recorded and final hit-rate percentages are displayed.
//
// WORKLOADS (46 total requests across 4 patterns):
//   1. Sequential Access   : 16 requests — stream over all address lines
//   2. Temporal Repetition :  8 requests — repeated access to same 2 addresses
//   3. Conflict-Heavy      : 12 requests — alternating conflict addresses
//   4. Mixed               : 10 requests — realistic combined pattern
// =============================================================================

`timescale 1ns / 1ps

module tb_top;

    // =========================================================================
    // DUT Signals
    // =========================================================================
    reg        clk;
    reg        rst_n;
    reg        sel_2way_cache;
    reg        req_valid;
    reg  [7:0] req_addr;
    reg        req_wr_en;
    reg  [7:0] req_wdata;
    wire [7:0] resp_rdata;
    wire       resp_valid;
    wire       cache_hit;
    wire       busy;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    top_module dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .sel_2way_cache(sel_2way_cache),
        .req_valid     (req_valid),
        .req_addr      (req_addr),
        .req_wr_en     (req_wr_en),
        .req_wdata     (req_wdata),
        .resp_rdata    (resp_rdata),
        .resp_valid    (resp_valid),
        .cache_hit     (cache_hit),
        .busy          (busy)
    );

    // =========================================================================
    // Clock Generation: 10 ns period (100 MHz)
    // =========================================================================
    initial clk = 0;
    always #5 clk = ~clk;

    // =========================================================================
    // Scoreboard Variables
    // =========================================================================
    integer hits_direct, misses_direct, total_direct;
    integer hits_2way,   misses_2way,   total_2way;
    integer hits_wb_seq_d, hits_wb_seq_2;    // Workload-bucket seq
    integer hits_wb_tmp_d, hits_wb_tmp_2;    // Workload-bucket temporal
    integer hits_wb_con_d, hits_wb_con_2;    // Workload-bucket conflict
    integer hits_wb_mix_d, hits_wb_mix_2;    // Workload-bucket mixed

    // Timing
    integer cycles_hit_d,  cycles_miss_d;
    integer cycles_hit_2,  cycles_miss_2;

    // =========================================================================
    // Task: Reset DUT
    // =========================================================================
    task do_reset;
        begin
            rst_n     <= 1'b0;
            req_valid <= 1'b0;
            req_wr_en <= 1'b0;
            req_addr  <= 8'h00;
            req_wdata <= 8'h00;
            repeat(4) @(posedge clk);
            rst_n <= 1'b1;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: Issue a single read request and wait for completion
    //       Returns 1 if hit, 0 if miss
    // =========================================================================
    task issue_read;
        input  [7:0] addr;
        output       is_hit;
        output [7:0] rdata;
        output integer cyc_count;
        integer c;
        begin
            c         = 0;
            req_valid <= 1'b1;
            req_addr  <= addr;
            req_wr_en <= 1'b0;
            req_wdata <= 8'h00;
            @(posedge clk);
            // Wait until resp_valid asserted
            while (!resp_valid) begin
                @(posedge clk);
                c = c + 1;
            end
            is_hit  = cache_hit;
            rdata   = resp_rdata;
            cyc_count = c + 1;
            req_valid <= 1'b0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: Issue a single write request and wait for completion
    // =========================================================================
    task issue_write;
        input [7:0] addr;
        input [7:0] wdata;
        begin
            req_valid <= 1'b1;
            req_addr  <= addr;
            req_wr_en <= 1'b1;
            req_wdata <= wdata;
            @(posedge clk);
            while (!resp_valid) @(posedge clk);
            req_valid <= 1'b0;
            req_wr_en <= 1'b0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: Run all 4 workloads on the currently-selected cache
    //       Writes hit/miss tallies into the provided output vars.
    // =========================================================================
    task run_all_workloads;
        input is_2way;         // 0 = direct, 1 = 2-way  (for display only)
        output integer h_seq, h_tmp, h_con, h_mix;
        output integer m_seq, m_tmp, m_con, m_mix;
        // local
        integer k;
        reg       hit_flag;
        reg [7:0] rd;
        integer   cyc;
        // Address arrays for each workload
        reg [7:0] seq_addrs  [0:15];
        reg [7:0] tmp_addrs  [0:7];
        reg [7:0] con_addrs  [0:11];
        reg [7:0] mix_addrs  [0:9];
        begin
            h_seq = 0; m_seq = 0;
            h_tmp = 0; m_tmp = 0;
            h_con = 0; m_con = 0;
            h_mix = 0; m_mix = 0;

            // ------------------------------------------------------------------
            // Workload 1: Sequential — 16 reads to addresses 0x00..0x0F
            // ------------------------------------------------------------------
            seq_addrs[0]  = 8'h00; seq_addrs[1]  = 8'h01;
            seq_addrs[2]  = 8'h02; seq_addrs[3]  = 8'h03;
            seq_addrs[4]  = 8'h04; seq_addrs[5]  = 8'h05;
            seq_addrs[6]  = 8'h06; seq_addrs[7]  = 8'h07;
            seq_addrs[8]  = 8'h00; seq_addrs[9]  = 8'h01;
            seq_addrs[10] = 8'h02; seq_addrs[11] = 8'h03;
            seq_addrs[12] = 8'h04; seq_addrs[13] = 8'h05;
            seq_addrs[14] = 8'h06; seq_addrs[15] = 8'h07;
            for (k = 0; k < 16; k = k + 1) begin
                issue_read(seq_addrs[k], hit_flag, rd, cyc);
                if (hit_flag) h_seq = h_seq + 1; else m_seq = m_seq + 1;
            end

            // ------------------------------------------------------------------
            // Workload 2: Temporal Repetition — 8 reads, repeat 0x10 & 0x11
            // ------------------------------------------------------------------
            tmp_addrs[0] = 8'h10; tmp_addrs[1] = 8'h11;
            tmp_addrs[2] = 8'h10; tmp_addrs[3] = 8'h11;
            tmp_addrs[4] = 8'h10; tmp_addrs[5] = 8'h11;
            tmp_addrs[6] = 8'h10; tmp_addrs[7] = 8'h11;
            for (k = 0; k < 8; k = k + 1) begin
                issue_read(tmp_addrs[k], hit_flag, rd, cyc);
                if (hit_flag) h_tmp = h_tmp + 1; else m_tmp = m_tmp + 1;
            end

            // ------------------------------------------------------------------
            // Workload 3: Conflict-Heavy — 12 reads alternating 2 conflict addrs
            //   Direct-mapped: 0x00 and 0x08 both map to index 0 → thrashing
            //   2-way: same set index 0, but 2 ways → no thrashing after warm-up
            // ------------------------------------------------------------------
            con_addrs[0]  = 8'h00; con_addrs[1]  = 8'h08;
            con_addrs[2]  = 8'h00; con_addrs[3]  = 8'h08;
            con_addrs[4]  = 8'h00; con_addrs[5]  = 8'h08;
            con_addrs[6]  = 8'h00; con_addrs[7]  = 8'h08;
            con_addrs[8]  = 8'h00; con_addrs[9]  = 8'h08;
            con_addrs[10] = 8'h00; con_addrs[11] = 8'h08;
            for (k = 0; k < 12; k = k + 1) begin
                issue_read(con_addrs[k], hit_flag, rd, cyc);
                if (hit_flag) h_con = h_con + 1; else m_con = m_con + 1;
            end

            // ------------------------------------------------------------------
            // Workload 4: Mixed — 10 reads, realistic combination
            // ------------------------------------------------------------------
            mix_addrs[0] = 8'h20; mix_addrs[1] = 8'h21;
            mix_addrs[2] = 8'h20; mix_addrs[3] = 8'h22;
            mix_addrs[4] = 8'h21; mix_addrs[5] = 8'h20;
            mix_addrs[6] = 8'h28; mix_addrs[7] = 8'h20;
            mix_addrs[8] = 8'h21; mix_addrs[9] = 8'h20;
            for (k = 0; k < 10; k = k + 1) begin
                issue_read(mix_addrs[k], hit_flag, rd, cyc);
                if (hit_flag) h_mix = h_mix + 1; else m_mix = m_mix + 1;
            end
        end
    endtask

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    integer total_hits_d, total_hits_2;
    integer total_req;

    initial begin
        // VCD Waveform dump for GTKWave (Phase II)
        $dumpfile("waveforms/wave_top.vcd");
        $dumpvars(0, tb_top);

        total_req = 46;

        // -----------------------------------------------------------------------
        // RUN 1: Direct-Mapped Cache (sel_2way_cache = 0)
        // -----------------------------------------------------------------------
        sel_2way_cache = 1'b0;
        do_reset;
        $display("============================================================");
        $display("  INTEGRATION BENCHMARK — Direct-Mapped Cache (sel=0)");
        $display("============================================================");

        run_all_workloads(0,
            hits_wb_seq_d, hits_wb_tmp_d, hits_wb_con_d, hits_wb_mix_d,
            misses_direct, misses_direct, misses_direct, misses_direct);

        total_hits_d = hits_wb_seq_d + hits_wb_tmp_d + hits_wb_con_d + hits_wb_mix_d;

        $display("  Workload        | Requests | Hits | Misses | Hit Rate");
        $display("  ----------------+----------+------+--------+---------");
        $display("  Sequential      |    16    |  %0d  |   %0d   | %0d%%",
            hits_wb_seq_d, 16-hits_wb_seq_d, (hits_wb_seq_d*100)/16);
        $display("  Temporal        |     8    |  %0d  |   %0d   | %0d%%",
            hits_wb_tmp_d, 8-hits_wb_tmp_d,  (hits_wb_tmp_d*100)/8);
        $display("  Conflict-Heavy  |    12    |  %0d  |   %0d   | %0d%%",
            hits_wb_con_d, 12-hits_wb_con_d, (hits_wb_con_d*100)/12);
        $display("  Mixed           |    10    |  %0d  |   %0d   | %0d%%",
            hits_wb_mix_d, 10-hits_wb_mix_d, (hits_wb_mix_d*100)/10);
        $display("  ----------------+----------+------+--------+---------");
        $display("  TOTAL           |    46    |  %0d  |   %0d   | %0d%%",
            total_hits_d, total_req-total_hits_d, (total_hits_d*100)/total_req);
        $display("");

        // -----------------------------------------------------------------------
        // RUN 2: 2-Way Set-Associative LRU Cache (sel_2way_cache = 1)
        // -----------------------------------------------------------------------
        sel_2way_cache = 1'b1;
        do_reset;
        $display("============================================================");
        $display("  INTEGRATION BENCHMARK — 2-Way LRU Cache (sel=1)");
        $display("============================================================");

        run_all_workloads(1,
            hits_wb_seq_2, hits_wb_tmp_2, hits_wb_con_2, hits_wb_mix_2,
            misses_2way, misses_2way, misses_2way, misses_2way);

        total_hits_2 = hits_wb_seq_2 + hits_wb_tmp_2 + hits_wb_con_2 + hits_wb_mix_2;

        $display("  Workload        | Requests | Hits | Misses | Hit Rate");
        $display("  ----------------+----------+------+--------+---------");
        $display("  Sequential      |    16    |  %0d  |   %0d   | %0d%%",
            hits_wb_seq_2, 16-hits_wb_seq_2, (hits_wb_seq_2*100)/16);
        $display("  Temporal        |     8    |  %0d  |   %0d   | %0d%%",
            hits_wb_tmp_2, 8-hits_wb_tmp_2,  (hits_wb_tmp_2*100)/8);
        $display("  Conflict-Heavy  |    12    |  %0d  |   %0d   | %0d%%",
            hits_wb_con_2, 12-hits_wb_con_2, (hits_wb_con_2*100)/12);
        $display("  Mixed           |    10    |  %0d  |   %0d   | %0d%%",
            hits_wb_mix_2, 10-hits_wb_mix_2, (hits_wb_mix_2*100)/10);
        $display("  ----------------+----------+------+--------+---------");
        $display("  TOTAL           |    46    |  %0d  |   %0d   | %0d%%",
            total_hits_2, total_req-total_hits_2, (total_hits_2*100)/total_req);
        $display("");

        // -----------------------------------------------------------------------
        // COMPARATIVE SUMMARY
        // -----------------------------------------------------------------------
        $display("============================================================");
        $display("  COMPARATIVE PERFORMANCE SUMMARY (Phase II)");
        $display("============================================================");
        $display("  Metric              | Direct-Mapped | 2-Way LRU");
        $display("  --------------------+---------------+-----------");
        $display("  Total Requests      |      46       |     46");
        $display("  Total Hits          |      %0d       |     %0d",
            total_hits_d, total_hits_2);
        $display("  Total Misses        |      %0d       |     %0d",
            total_req-total_hits_d, total_req-total_hits_2);
        $display("  Overall Hit Rate    |     %0d%%      |    %0d%%",
            (total_hits_d*100)/total_req, (total_hits_2*100)/total_req);
        $display("  Conflict Hit Rate   |      %0d%%      |    %0d%%",
            (hits_wb_con_d*100)/12, (hits_wb_con_2*100)/12);
        $display("============================================================");

        if (total_hits_2 > total_hits_d)
            $display("  RESULT: 2-Way LRU outperforms Direct-Mapped by %0d hits (%0d%% advantage)",
                total_hits_2 - total_hits_d,
                ((total_hits_2 - total_hits_d)*100)/total_req);
        else if (total_hits_2 == total_hits_d)
            $display("  RESULT: Both caches perform equally on this trace.");
        else
            $display("  RESULT: Direct-Mapped outperforms 2-Way on this trace.");

        $display("============================================================");
        $display("  [KAAVYA] tb_top: Integration benchmark COMPLETE.");
        $display("============================================================");

        #20;
        $finish;
    end

endmodule
