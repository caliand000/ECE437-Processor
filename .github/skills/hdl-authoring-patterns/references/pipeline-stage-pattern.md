# Pipeline stage pattern

## 1. Stage module: build once, gate once

```systemverilog
module id_stage
  import pipeline_types_pkg::*;
(
  input  logic        CLK, nRST,
  input  IF_ID        if_id_q,        // register output feeding this stage
  input  logic [31:0] rf_rdat1, rf_rdat2,
  input  logic        bubble,         // from hazard unit
  output ID_EX        id_ex_d         // goes to the ID/EX pipe_reg
  // plus explicit interface ports for control/extender
);
  ID_EX id_ex_raw;

  always_comb begin
    id_ex_raw           = '0;                       // default every field
    id_ex_raw.pc        = if_id_q.pc;
    id_ex_raw.rdat1     = rf_rdat1;
    id_ex_raw.rdat2     = rf_rdat2;
    // ...only fields this stage produces
  end

  assign id_ex_d = bubble ? '0 : id_ex_raw;         // the rule, written once
endmodule
```

Apply the same shape to every stage that currently has a column of `assign` lines with a shared condition. If a stage has no shared condition, a plain `always_comb` struct build (or a single struct assign) is still preferred over per-field `assign`.

## 2. Generic pipeline register

```systemverilog
module pipe_reg #(parameter type T = logic [31:0]) (
  input  logic CLK, nRST,
  input  logic en,       // load d
  input  logic flush,    // synchronous clear, has priority over en
  input  T     d,
  output T     q
);
  always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST)      q <= '0;
    else if (flush) q <= '0;
    else if (en)    q <= d;
  end
endmodule
```

Instantiate in `datapath`:
```systemverilog
pipe_reg #(.T(IF_ID))  IF_ID_REG  (.CLK, .nRST, .en(if_id_en),  .flush(pipe_flush), .d(if_id_d),  .q(if_id_q));
pipe_reg #(.T(ID_EX))  ID_EX_REG  (.CLK, .nRST, .en(advance),   .flush(pipe_flush), .d(id_ex_d),  .q(id_ex_q));
pipe_reg #(.T(EX_MEM)) EX_MEM_REG (.CLK, .nRST, .en(advance),   .flush(pipe_flush), .d(ex_mem_d), .q(ex_mem_q));
pipe_reg #(.T(MEM_WB)) MEM_WB_REG (.CLK, .nRST, .en(advance),   .flush(1'b0),       .d(mem_wb_d), .q(mem_wb_q));
```
Where, derived from the original latch block (VERIFY against the actual current code):
- `advance   = ihit && (!(dmemREN || dmemWEN) || dhit)`
- `pipe_flush = advance && huif.Flush`
- `if_id_en  = advance && huif.latch_en` (IF/ID holds on a load-use stall)
- ID/EX and EX/MEM load every `advance` cycle; during a stall `id_ex_d` is already the bubble.
- MEM/WB loads on `advance` and is never flushed.

## 3. Quirks to preserve (do not "generalize" these away)
- `ex_mem.read_data` is captured when `dhit` is true even when `advance` is false (separate `else if (dhit)` branch). Keep it as a small dedicated register/enable next to the EX/MEM register, with a comment explaining why.
- `ex_mem_in.read_data` and `mem_wb_in.read_data` use different `dhit` conditions. Keep them exactly.
- The register file writes on `negedge CLK`. Do not move it.
- Reset values are all-zero for the pipeline registers.

## 4. Control struct (final, separate commit)
Replace the loose control outputs with one packed struct:

```systemverilog
typedef struct packed {
  logic        reg_wr;
  logic [1:0]  mem_wr;
  logic        mem_to_reg;
  logic        alu_src;
  aluop_t      alu_op;
  logic [1:0]  jumpsel;
  logic [7:0]  branch;
  logic        pchalt;
} ctrl_t;
```
Then `ID_EX` holds `ctrl_t ctrl;` and a bubble is `ctrl = '0`. Do the same in EX/MEM and MEM/WB with only the fields still needed. This changes `control_request_unit_if` and `control_unit_tb`, so keep it in its own commit and keep `control_unit_tb` passing.

## 5. Checklist before finishing a stage refactor
- [ ] No run of repeated gated assigns remains.
- [ ] Every port has explicit direction and type.
- [ ] No loose stage-to-stage signals; structs only.
- [ ] No registers inside stage modules.
- [ ] Regression pass count and per-test cycle counts match baseline.
- [ ] Lint warning count did not increase.
