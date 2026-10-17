# Datapath walkthrough and stage split

## Scope and baseline

This refactor was made on branch `refactor/datapath-stage-modules`, created from the checked-out commit `b49189d` while preserving the pre-existing worktree changes. The processor behavior was measured before changing the RTL.

| Check | Baseline | After refactor |
| --- | --- | --- |
| `run_all_asm_tests.sh` | 36/36 assembled | 36/36 simulated |
| Simulated programs | 36/36 passed | 36/36 passed |
| Simulated cycles | calculatedays 2679; fib 495; loop 138; mergesort 12997; multiply 784; multiplyprocedure 109; qsort 2159; search 671; associative 77; beqnottaken 43; beqtaken 59; bgenottaken 43; bgetaken 67; bgeunottaken 47; bgeutaken 63; bltnottaken 43; blttaken 63; bltunottaken 43; bltutaken 63; bnenottaken 43; bnetaken 63; branchjump1 127; controlflowhazard 77; datahazard 73; forwardinghazard 84; halt 35; ihitbeforedhit 108; ihitdhitsame 87; jal 63; jalr 71; ldst1 117; ldst2 130; loadstore 126; lui 67; rtype 197; structuralhazard 39 | pending final runner completion |
| `make lint` | exit 0; 167 warning lines; 0 errors | exit 0; 167 warning lines; 0 errors |

Warning categories and counts are unchanged. A temporary `UNOPTFLAT` warning appeared when the first split connected the hazard unit to `id_ex_in`; it was removed by restoring the original `id_ex_out.MemtoReg` and `id_ex_out.rd` dependencies.

## Existing datapath, in source order

### Includes, module header, and declarations

The module receives `CLK`, active-low asynchronous reset `nRST`, and the `datapath_cache_if.dp` view of the instruction/data cache interface. It creates the control, extender, branch-decider, hazard, and forwarding interfaces and declares the existing `IF_ID`, `ID_EX`, `EX_MEM`, and `MEM_WB` structs from `pipeline_types_pkg`.

The `*_in` structs are combinational values produced for the next latch. The `*_out` structs are the registered values consumed by later logic. The unused `*_nxt` declarations were not needed by the implementation. The register file is part of the datapath: its read addresses come from the current IF/ID instruction, and its write side comes from MEM/WB.

### Module instances

The control unit decodes the IF/ID instruction and produces ALU, memory, writeback, jump, branch, and halt control. The extender produces the immediate. The hazard and forwarding units are pure combinational decision logic. The decider converts registered EX/MEM ALU flags and branch type into `PCsrc`. The ALU consumes the selected EX operands and produces the EX/MEM ALU result and flags. The register file writes on its own `negedge CLK` block; the datapath registers and memory request registers use `posedge CLK`.

### ALU section

This section is operand selection in front of `alu.sv`, not a second ALU. `Alu_a` selects the first operand using `fuif.Alu_in1`: the ID/EX register value, the current register-file writeback value, the MEM/WB writeback value, or the EX/MEM immediate. `Alu_b` selects the second register operand from ID/EX, the current writeback value, or MEM/WB. The `AluSrc` mux then selects either the immediate or `Alu_b` as `Alu_c`, which is connected to `alu.sv` input `B`. The ALU itself remains the combinational function unit.

The same forwarded `Alu_a` and `Alu_b` values are placed in `ex_mem_in.rdat1` and `ex_mem_in.rdat2`. The latter becomes the store data. Thus the muxes have inputs crossing several boundaries: ID/EX values are registered EX inputs, `rf_wdat` is the current WB result before the register-file write, `mem_wb_in.wrb` is the combinational result being prepared for the WB latch, and `ex_mem_out.immediate` is the registered MEM value.

### Immediate generator and register file

The extender reads the IF/ID instruction and drives the immediate that is copied into ID/EX, unless `Zero_controls` turns the whole ID/EX control/data input into a bubble. Register-file read selectors come from instruction fields `[19:15]` and `[24:20]`. Its write selector, enable, and data come from MEM/WB. `MemtoReg` selects cache data over the ALU/jump result.

### Branch unit

The decider reads `ex_mem_out.Zero`, `ex_mem_out.Neg`, and the registered branch-type vector. Its `PCsrc` output is consumed by both the hazard unit and the PC mux. This is a combinational cross-stage path: branch control is computed from EX/MEM state while the fetch PC is being chosen.

### IF/ID input and ID/EX input

The IF/ID input is the cache instruction and current instruction address. The ID/EX input copies the IF/ID PC, register-file data, extended immediate, source/destination registers, and decoded controls. Every field is conditionally replaced with zero under `huif.Zero_controls`; this is the load-use stall bubble. The branch/jump type and `jumpsel` are carried with the instruction.

### ID/EX to EX/MEM input

This section carries the registered instruction state forward and attaches the ALU flags, forwarded operands, ALU output, `PC + immediate`, immediate, and memory data. `ex_mem_in.read_data` has the special expression `dpif.dhit ? dpif.dmemload : ex_mem_out.read_data`. It can receive a data-cache response directly while retaining the previous registered value otherwise.

### EX/MEM to MEM/WB input and `jumpsel`

The MEM/WB input carries the memory response and writeback control. The `jumpsel` mux is evaluated before the WB latch so `mem_wb_out.wrb` is already the selected value when writeback and forwarding consume it:

- `00`: ALU result, for ordinary arithmetic/logic instructions.
- `01`: `PC + immediate`, for AUIPC.
- `10`: the immediate, for LUI.
- `11`: `PC + 4`, reconstructed as `AdderOut - immediate + 4`, for JAL/JALR.

The `read_data` expression additionally selects `dpif.dmemload` when both instruction and data caches hit in the same cycle.

### Data-cache requests

`dmemstore` is EX/MEM `rdat2`, and `dmemaddr` is EX/MEM `AluOut`. The `dmemREN` and `dmemWEN` signals are registers. Reset clears both. A `dhit` clears both request bits. Otherwise, an ID/EX store or load request sets the corresponding bit only when instruction fetch has hit and no branch flush is active. The request remains asserted until the data cache reports `dhit`. `imemREN` is the inverse of both data request bits, so the data transaction gets priority and instruction fetch pauses during it.

### Control, forwarding, and hazards

The control interface receives the IF/ID instruction. The forwarding interface compares ID/EX source registers against EX/MEM and MEM/WB destinations and receives their write enables, jump selection, and memory-to-register control. The hazard interface compares IF/ID source registers against the registered ID/EX destination and receives `PCsrc` and ID/EX `MemtoReg`.

`huif.Flush` is asserted for a taken branch or jump. `huif.Zero_controls` inserts the load-use bubble while `huif.Halt` holds the PC. `huif.latch_en` permits the normal IF/ID latch update. These controls are combinational and feed both the ID/EX input mux and the pipeline latch controller.

### Program-counter logic

On reset, `imemaddr` and `halt` clear. On each positive edge, `imemaddr` takes `iaddr` and `halt` becomes sticky once EX/MEM `pchalt` is asserted. When `ihit` is low, the PC holds. With a hit, `PCsrc` selects sequential PC, EX/MEM `AdderOut` for PC-relative branch/jump targets, or EX/MEM `rdat1 + immediate` for JALR. The `ex_mem_out` use is intentional: the redirect decision and its operands belong to the instruction that has reached the branch/execute result boundary.

### Latch logic

All four pipeline structs clear asynchronously on reset. A normal latch cycle requires `ihit` and either no active data request or `dhit`. A flush clears IF/ID, ID/EX, and EX/MEM but still updates MEM/WB in the enclosing condition. Otherwise `latch_en` controls whether IF/ID takes its new cache input; ID/EX and EX/MEM continue to receive their computed inputs in both branches. MEM/WB takes its input whenever the enclosing condition is true.

The special `else if(dpif.dhit)` path runs when the normal latch condition is false but the cache has just returned data. It updates only `ex_mem_out.read_data` from `ex_mem_in.read_data`, preserving the rest of the stalled pipeline state. This is why `read_data` is computed both at the EX/MEM input and again in the MEM/WB path.

## Proposed module split

| Module | Contains | Input ports | Output ports |
| --- | --- | --- | --- |
| `if_stage` | PC register, next-PC mux, halt flag, `imemREN`, IF/ID input | `CLK`, `nRST`, `datapath_cache_if.dp`, `decider_if`, `hazard_unit_if`, `EX_MEM` | `IF_ID` input value |
| `id_stage` | register-file read field hookup, extender, control unit, hazard unit, ID/EX bubble mux | `CLK`, `nRST`, `IF_ID`, register-file read data, `ID_EX` registered dependency, control/extender/decider/hazard interfaces | `ID_EX` input value |
| `ex_stage` | forwarding unit, operand muxes, ALU, branch decider, EX/MEM input | `datapath_cache_if.dp`, `ID_EX`, `EX_MEM`, current WB data, `MEM_WB` input value, forwarding/decider interfaces | `EX_MEM` input value |
| `mem_stage` | data request registers, data address/store, MEM/WB input and `jumpsel` mux | `CLK`, `nRST`, `datapath_cache_if.dp`, `ID_EX`, `EX_MEM`, hazard interface | `MEM_WB` input value |
| `wb_stage` | register-file read/write hookup | `CLK`, `nRST`, `IF_ID`, `MEM_WB` | register-file read data and writeback data |
| `datapath` | interface instances, existing pipeline structs, stage instances, pipeline latch/flush/stall block | shared stage signals and `datapath_cache_if.dp` | registered pipeline state and cache-facing stage outputs |

Hazard and forwarding logic move into the stage that owns their decisions: hazard logic is instantiated by `id_stage`, and forwarding plus branch decision are instantiated by `ex_stage`. The hazard interface still crosses into IF, EX, and MEM because its outputs control PC, bubble, flush, and data request behavior. The forwarding stage still consumes the combinational MEM/WB input value to preserve the original forwarding path. Those are the intentionally awkward interfaces required by the existing timing behavior.

## New datapath.sv

```systemverilog
`include "datapath_cache_if.vh"
`include "control_request_unit_if.vh"
`include "extender_if.vh"
`include "decider_if.vh"
`include "hazard_unit_if.vh"
`include "forward_unit_if.vh"
`include "cpu_types_pkg.vh"
`include "pipeline_types_pkg.vh"

module datapath #(
  parameter PC_INIT = 0
)(
  input logic CLK,
  input logic nRST,
  datapath_cache_if.dp dpif
);
  import pipeline_types_pkg::*;

  control_request_unit_if cruif();
  extender_if exif_in();
  decider_if deif();
  hazard_unit_if huif();
  forward_unit_if fuif();

  IF_ID if_id_in;
  IF_ID if_id_out;
  ID_EX id_ex_in;
  ID_EX id_ex_out;
  EX_MEM ex_mem_in;
  EX_MEM ex_mem_out;
  MEM_WB mem_wb_in;
  MEM_WB mem_wb_out;

  logic [31:0] rf_wdat, rf_rdat1, rf_rdat2;
  logic [4:0] rf_rsel1, rf_rsel2;

  if_stage #(.PC_INIT(PC_INIT)) IF_STAGE(
    .CLK(CLK), .nRST(nRST), .dpif(dpif), .deif(deif), .huif(huif),
    .ex_mem_out(ex_mem_out), .if_id_in(if_id_in)
  );
  id_stage ID_STAGE(
    .CLK(CLK), .nRST(nRST), .if_id_out(if_id_out),
    .rf_rdat1(rf_rdat1), .rf_rdat2(rf_rdat2), .id_ex_out(id_ex_out),
    .deif(deif), .cruif(cruif), .exif_in(exif_in), .huif(huif),
    .id_ex_in(id_ex_in)
  );
  ex_stage EX_STAGE(
    .dpif(dpif), .deif(deif), .fuif(fuif), .id_ex_out(id_ex_out),
    .ex_mem_out(ex_mem_out), .rf_wdat(rf_wdat), .mem_wb_in(mem_wb_in),
    .ex_mem_in(ex_mem_in)
  );
  mem_stage MEM_STAGE(
    .CLK(CLK), .nRST(nRST), .dpif(dpif), .huif(huif),
    .id_ex_out(id_ex_out), .ex_mem_out(ex_mem_out),
    .mem_wb_in(mem_wb_in)
  );
  wb_stage WB_STAGE(
    .CLK(CLK), .nRST(nRST), .if_id_out(if_id_out),
    .mem_wb_out(mem_wb_out), .rf_rsel1(rf_rsel1), .rf_rsel2(rf_rsel2),
    .rf_rdat1(rf_rdat1), .rf_rdat2(rf_rdat2), .rf_wdat(rf_wdat)
  );

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      if_id_out <= '0;
      id_ex_out <= '0;
      ex_mem_out <= '0;
      mem_wb_out <= '0;
    end
    else begin
      if(dpif.ihit && (!(dpif.dmemREN || dpif.dmemWEN) || dpif.dhit)) begin
        if(huif.Flush) begin
          if_id_out <= '0;
          id_ex_out <= '0;
          ex_mem_out <= '0;
        end
        else if(huif.latch_en) begin
          if_id_out <= if_id_in;
          id_ex_out <= id_ex_in;
          ex_mem_out <= ex_mem_in;
        end
        else begin
          if_id_out <= if_id_out;
          id_ex_out <= id_ex_in;
          ex_mem_out <= ex_mem_in;
        end
        mem_wb_out <= mem_wb_in;
      end
      else if(dpif.dhit) begin
        ex_mem_out.read_data <= ex_mem_in.read_data;
      end
    end
  end

endmodule
```

## Phase C condition mapping

| Original latch behavior | `advance` | `pipe_flush` | `if_id_en` | IF/ID | ID/EX | EX/MEM | MEM/WB |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Reset: all four structs assigned `'0` | n/a | n/a | n/a | async clear | async clear | async clear | async clear |
| `dpif.ihit && (!(dpif.dmemREN || dpif.dmemWEN) || dpif.dhit)` | 1 | `huif.Flush` | `huif.latch_en` | load only when `latch_en` | load | load | load |
| Same condition with `huif.Flush` | 1 | 1 | don't care | flush | flush | flush | load, never flush |
| Same condition, no flush, `huif.latch_en` | 1 | 0 | 1 | load | load | load | load |
| Same condition, no flush, `!huif.latch_en` | 1 | 0 | 0 | hold | load bubble-built data | load | load |
| `else if(dpif.dhit)` after the normal condition fails | 0 | 0 | 0 | hold | hold | hold except `read_data` | hold |

`EX_MEM_READ_DATA_REG` has enable `advance || dpif.dhit` and flush `pipe_flush`: when `advance` is false, the `dhit` term preserves the original dedicated capture; when `advance` is true, it tracks the normal EX/MEM input. The full EX/MEM register's `read_data` field is intentionally ignored in favor of this dedicated value.

## Verified oddities not changed

- `forward_unit.sv`: confirmed. `Alu_in1` is first assigned `2'b11` for a non-load EX/MEM dependency and then immediately overridden to `2'b10` by the next `if` when the same condition is true. This is dead behavior in the current code and was left unchanged.
- `alu.sv` opcode width: not confirmed in this checkout. `opcode` is 5 bits and all case literals are also 5-bit literals (`5'b...`).
- `decider.sv` names and type ordering: confirmed as an oddity. It declares and decodes `bgt`/`bgtu` while `control_unit.sv` produces `bge`/`bgeu`; bit positions do line up (`beq`, `bne`, signed comparison, unsigned comparison, `blt`, `bltu`, `jal`, `jalr`), but the names do not. The implemented signed comparison expression also deserves separate functional review, but was not changed here.
- `extender.sv`: confirmed. It declares `bgt`/`bgtu` but assigns `bge`/`bgeu`. With implicit nets enabled, those become undeclared implicit signals and the declared names remain unused. No behavior change was made.
- `system_tb.sv`: confirmed. The commented-out tracker block references `DP.funct3_WB`, `DP.opcode_WB`, and related signals that are not ports/signals in the current datapath. The grep did not find active merge-conflict marker lines; the stale block is simply commented-out legacy instrumentation.

## Commits

Logical commits on this branch:

- `395eae6` Extract instruction-fetch datapath stage
- `57506cf` Extract instruction-decode datapath stage
- `d722b3a` Extract execute datapath stage
- `5cd048b` Extract memory datapath stage
- `15a042d` Extract writeback datapath stage
- `6383449` Compose datapath from stage modules
- Documentation commit: current `HEAD` on this branch

## Questions / residual uncertainty

The cycle counts match exactly. The repository was already dirty before this task, including `Makefile`, register-file sources, testbenches, generated `obj_dir` contents, a synthesis wrapper, and schematics; those changes were intentionally not included in this refactor's commits. Available post-refactor module tests: `alu`, `decider`, `forward_unit`, `icache`, `memory_control`, and `register_file` passed; `control_unit`, `hazard_unit`, `dcache`, and `request_unit` reported failures. A pre-refactor unit-test baseline was not isolated because the worktree already contained unrelated source and testbench modifications.
