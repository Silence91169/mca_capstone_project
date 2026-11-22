// =============================================================================
// Module: top_module
// Project: Design and Performance Analysis of a 2-Way Set-Associative Cache
//          with LRU Replacement Compared with a Direct-Mapped Cache
// Component: Top-Level Integration Wrapper
// Assigned Member: Yash Raghubanshi (Project Lead / Integration)
// Language: Verilog-2001 (Synthesizable RTL)
// Phase: Phase II — Complete Integration
// =============================================================================
//
// DESCRIPTION:
//   Integrates both caches (direct-mapped and 2-way LRU set-associative) with
//   a shared 256×8-bit behavioral main memory model. A single-bit sel_2way_cache
//   mux routes CPU requests to the selected cache; the other cache is held idle.
//   Both caches share the same memory model so back-to-back tests remain fair.
//
// MEMORY MODEL: Synchronous, 2-cycle latency behavioral RAM (not synthesized).
// =============================================================================

`timescale 1ns / 1ps

module top_module (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sel_2way_cache, // 1 = 2-Way Cache, 0 = Direct-Mapped Cache
    // CPU Interface
    input  wire       req_valid,
    input  wire [7:0] req_addr,
    input  wire       req_wr_en,
    input  wire [7:0] req_wdata,
    output wire [7:0] resp_rdata,
    output wire       resp_valid,
    output wire       cache_hit,
    output wire       busy
);

    // =========================================================================
    // Shared Behavioral Main Memory (256 x 8-bit)
    // =========================================================================
    reg  [7:0] main_mem [0:255];
    reg  [7:0] mem_rdata_r;
    reg        mem_ready_r;
    reg  [1:0] mem_lat_cnt;   // 2-cycle memory latency counter

    // Arbitrated memory bus — only the active cache drives the bus
    wire       mem_req_d,  mem_wr_en_d;
    wire [7:0] mem_addr_d, mem_wdata_d;
    wire       mem_req_2,  mem_wr_en_2;
    wire [7:0] mem_addr_2, mem_wdata_2;

    wire       mem_req_active  = sel_2way_cache ? mem_req_2  : mem_req_d;
    wire       mem_wr_active   = sel_2way_cache ? mem_wr_en_2 : mem_wr_en_d;
    wire [7:0] mem_addr_active = sel_2way_cache ? mem_addr_2 : mem_addr_d;
    wire [7:0] mem_wdata_active= sel_2way_cache ? mem_wdata_2 : mem_wdata_d;

    // Memory controller: 2-cycle fixed latency
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready_r <= 1'b0;
            mem_rdata_r <= 8'h00;
            mem_lat_cnt <= 2'd0;
        end else begin
            if (mem_req_active && mem_lat_cnt == 2'd0) begin
                mem_lat_cnt <= 2'd1;
                mem_ready_r <= 1'b0;
            end else if (mem_lat_cnt == 2'd1) begin
                mem_lat_cnt <= 2'd0;
                mem_ready_r <= 1'b1;
                if (mem_wr_active)
                    main_mem[mem_addr_active] <= mem_wdata_active;
                else
                    mem_rdata_r <= main_mem[mem_addr_active];
            end else begin
                mem_ready_r <= 1'b0;
            end
        end
    end

    // =========================================================================
    // Direct-Mapped Cache Instance (Shivam)
    // =========================================================================
    wire [7:0] resp_rdata_d;
    wire       resp_valid_d, cache_hit_d, busy_d;

    cache_direct u_direct (
        .clk       (clk),
        .rst_n     (rst_n),
        .req_valid (sel_2way_cache ? 1'b0 : req_valid),
        .req_addr  (req_addr),
        .req_wr_en (req_wr_en),
        .req_wdata (req_wdata),
        .resp_rdata(resp_rdata_d),
        .resp_valid(resp_valid_d),
        .cache_hit (cache_hit_d),
        .busy      (busy_d),
        .mem_req   (mem_req_d),
        .mem_wr_en (mem_wr_en_d),
        .mem_addr  (mem_addr_d),
        .mem_wdata (mem_wdata_d),
        .mem_rdata (mem_rdata_r),
        .mem_ready (sel_2way_cache ? 1'b0 : mem_ready_r)
    );

    // =========================================================================
    // 2-Way Set-Associative Cache Instance (Keshav + LRU: Shitanshu)
    // =========================================================================
    wire [7:0] resp_rdata_2;
    wire       resp_valid_2, cache_hit_2, busy_2;

    cache_2way u_2way (
        .clk       (clk),
        .rst_n     (rst_n),
        .req_valid (sel_2way_cache ? req_valid : 1'b0),
        .req_addr  (req_addr),
        .req_wr_en (req_wr_en),
        .req_wdata (req_wdata),
        .resp_rdata(resp_rdata_2),
        .resp_valid(resp_valid_2),
        .cache_hit (cache_hit_2),
        .busy      (busy_2),
        .mem_req   (mem_req_2),
        .mem_wr_en (mem_wr_en_2),
        .mem_addr  (mem_addr_2),
        .mem_wdata (mem_wdata_2),
        .mem_rdata (mem_rdata_r),
        .mem_ready (sel_2way_cache ? mem_ready_r : 1'b0)
    );

    // =========================================================================
    // Output Mux — route active cache outputs to CPU
    // =========================================================================
    assign resp_rdata = sel_2way_cache ? resp_rdata_2 : resp_rdata_d;
    assign resp_valid = sel_2way_cache ? resp_valid_2 : resp_valid_d;
    assign cache_hit  = sel_2way_cache ? cache_hit_2  : cache_hit_d;
    assign busy       = sel_2way_cache ? busy_2        : busy_d;

endmodule

