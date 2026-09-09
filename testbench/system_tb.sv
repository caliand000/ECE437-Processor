/*
  Eric Villasenor
  evillase@gmail.com

  system test bench, for connected processor (datapath+cache)
  and memory (ram).

*/

// interface
`include "system_if.vh"

// types
`include "cpu_types_pkg.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module system_tb;
  // clock period
  parameter PERIOD = 20;

  // signals 
  logic CLK = 1, nRST;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  system_if syif();

  // test program
  test                                PROG (CLK,nRST,syif);

  // dut
`ifndef MAPPED
  system                              DUT (CLK,nRST,syif);

  // CPU Tracker. Uncomment and change signal names to enable.
  // NOTE: All of these signals MUST be passed all the way through
  // to the write back stage and sampled in the WRITEBACK stage.
  // This means more signals that would normally be necessary
  // for correct execution must be passed along to help with debugging.
  
  /*
  cpu_tracker_pipeline cpu_track0 (
    // CLK in datapath
    .CLK(DUT.CPU.DP.CLK),
    // MEMWB latch stall signal (or ~enable)
    .memwb_latch_stall(~DUT.CPU.DP.dpif.ihit),
    // funct3 bits, brought to WB stage
    .funct3(DUT.CPU.DP.funct3_WB),
    // funct7 bits, brought to WB stage
    .funct7(DUT.CPU.DP.funct7_WB),
    // opcode bits, brought to WB stage
    .opcode(opcode_t'(DUT.CPU.DP.opcode_WB)),
    // rsel1 bits, brought to WB stage
    .rsel1(DUT.CPU.DP.rs1_WB),
    // rsel2 bits, brought to WB stage
    .rsel2(DUT.CPU.DP.rs2_WB),
    // wsel bits, brought to WB stage
    .wsel(DUT.CPU.DP.rd_WB),
    // 32-bit instruction, brought to WB stage
    .instr(DUT.CPU.DP.instr_WB),
    // PC for this instruction, brought to WB stage
    .pc(DUT.CPU.DP.PC_WB),
    // next PC to go to after this instruction, brought to WB stage
    .next_pc(DUT.CPU.DP.nPC_WB),
    // target PC for this instruction. Branches and JAL: PC + imm32; JALR: R[rs] + imm32, brought to WB stage
    .branch_jump_target_pc(DUT.CPU.DP.branch_PC_WB),
    // 32-bit decoded immediate, brought to WB stage
    .imm32(DUT.CPU.DP.imm_WB),
    // upper 20 bits as used by U-Type instructions (LUI, AUIPC), brought to WB stage. Can be the upper 20 bits of your decoded imm32 if your pipeline does this already.
    .utype_upper20(DUT.CPU.DP.imm_WB[31:12]),
    // 32-bit wdat to register file
    .reg_file_wdat(DUT.CPU.DP.rfif.wdat),
    // 32-bit data memory address, brought to WB stage
    .data_mem_addr(DUT.CPU.DP.dmemaddr_WB),
    // 32-bit data memory store value, brought to WB stage
    .data_mem_store(DUT.CPU.DP.dmemstore_WB)
  );
  */
`else
  system                              DUT (,,,,//for altera debug ports
    CLK,
    nRST,
    syif.halt,
    syif.load,
    syif.addr,
    syif.store,
    syif.REN,
    syif.WEN,
    syif.tbCTRL
  );
`endif
endmodule

program test(input logic CLK, output logic nRST, system_if.tb syif);
  // import word type
  import cpu_types_pkg::word_t;

  // number of cycles
  int unsigned cycles = 0;

  initial
  begin
    nRST = 0;
    syif.tbCTRL = 0;
    syif.addr = 0;
    syif.store = 0;
    syif.WEN = 0;
    syif.REN = 0;
    @(posedge CLK);
    $display("Starting Processor.");
    nRST = 1;
    // wait for halt
    while (!syif.halt)
    begin
      @(posedge CLK);
      cycles++;
    end
    $display("Halted at %g time and ran for %d cycles.",$time, (cycles-1)/2);
    nRST = 0;
    dump_memory();
    $finish;
  end

  task automatic dump_memory();
    string filename = "memcpu.hex";
    int memfd;

    syif.tbCTRL = 1;
    syif.addr = 0;
    syif.WEN = 0;
    syif.REN = 0;

    memfd = $fopen(filename,"w");
    if (memfd)
      $display("Starting memory dump.");
    else
      begin $display("Failed to open %s.",filename); $finish; end

    for (int unsigned i = 0; memfd && i < 16384; i++)
    begin
      int chksum = 0;
      bit [7:0][7:0] values;
      string ihex;

      syif.addr = i << 2;
      syif.REN = 1;
      repeat (4) @(posedge CLK);
      if (syif.load === 0)
        continue;
      values = {8'h04,16'(i),8'h00,syif.load};
      foreach (values[j])
        chksum += values[j];
      chksum = 16'h100 - chksum;
      ihex = $sformatf(":04%h00%h%h",16'(i),syif.load,8'(chksum));
      $fdisplay(memfd,"%s",ihex.toupper());
    end //for
    if (memfd)
    begin
      syif.tbCTRL = 0;
      syif.REN = 0;
      $fdisplay(memfd,":00000001FF");
      $fclose(memfd);
      $display("Finished memory dump.");
    end
  endtask
endprogram
