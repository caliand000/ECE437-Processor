/*
	Filename:     cpu_tracker_singlecycle.sv

	Created by:     Zach Lagpacan
	Email:          zlagpaca@purdue.edu
	Date Created:   10/21/2024
	Description:    
			
		This testbench component prints out instruction info in writeback stage of the pipeline
		in order to conveniently trace datapath execution for easier debugging.

		Designed to diff easily against the output from "sim -t".

		This is the singlecycle version.
			For pipeline designs, use cpu_tracker_pipeline.sv

		Credit to Jacob R. Stevens (steven69@purdue.edu) for the original cpu_tracker for the MIPS ISA.
		This new version targets the RISC-V ISA and adapts exactly to "sim -t" output.
		Credit to Anusuya Nallathambi and Ansh Patel for helping with RISC-V updates.
*/

`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;

module cpu_tracker_singlecycle (
	input logic CLK,                    // CLK in datapath
	input logic enable_pc,              // signal which enables PC to go to next instruction
	input logic dhit,										// dhit from dpif
	input logic [FUNC3_W-1:0] funct3,   // funct3 bits
	input logic [FUNC7_W-1:0] funct7,   // funct7 bits
	input opcode_t opcode,              // opcode bits
	input regbits_t rsel1,              // rsel1 bits
	input regbits_t rsel2,              // rsel2 bits
	input regbits_t wsel,               // wsel bits
	input word_t instr,                 // 32-bit instruction
	input word_t pc,                    // PC for this instruction
	input word_t next_pc,               // next PC to go to after this instruction
	input word_t branch_jump_target_pc, // target PC for this instruction. Branches and JAL: PC + imm32; JALR: R[rs] + imm32
	input word_t imm32,                 // 32-bit decoded immediate
	input logic [19:0] utype_upper20,  	// upper 20 bits as used by U-Type instructions (LUI, AUIPC). Can be the upper 20 bits of your decoded imm32 if your datapath does this already.
	input word_t reg_file_wdat,         // 32-bit wdat to register file
	input logic data_mem_read,					// 1-bit dmemREN from dpif
	input logic data_mem_write, 				// 1-bit dmemWEN from dpif
	input word_t data_mem_addr,         // 32-bit dmemaddr from dpif
	input word_t data_mem_load,					// 32-bit dmemload from dpif
	input word_t data_mem_store         // 32-bit dmemstore from dpif
);

	parameter CPUID = 1;

	word_t presumed_reserve_addr;
	opcode_t last_opcode;
	logic valid_instr;
	word_t saved_pc;

	int fp;

	string filename;

	string output_str;
	string temp_str;
	string ram_str;

	string instr_mnemonic;
	string operands;
	string rsel1_str;
	string rsel2_str;
	string wsel_str;

	function string uppercase (
		input word_t data,
		input int num_bits
	);
		$sformat(uppercase, "%X", data);
		uppercase = uppercase.toupper();
	endfunction

	function string reg_convert (
		input regbits_t register
	);
		$sformat(reg_convert, "R%0d", register);
	endfunction

	initial begin: OPEN_FILE
		$sformat(filename, "cpu%0d_trace.log", CPUID);
		fp = $fopen(filename, "w");
	end
	
	always @ (*) begin
    rsel1_str = reg_convert(rsel1);
    rsel2_str = reg_convert(rsel2);
    wsel_str = reg_convert(wsel);
  end

	always @ (*) begin
    case (opcode)
      RTYPE: $sformat(operands, "%s, %s, %s", wsel_str, rsel1_str, rsel2_str);
      ITYPE: 
      begin
        case(funct3_i_t'(funct3))
          SRLI_SRAI, SLLI: $sformat(operands, "%s, %s, %0d", wsel_str, rsel1_str, (imm32[4:0]));
          default: $sformat(operands, "%s, %s, %0d", wsel_str, rsel1_str, signed'(imm32));
        endcase
      end
      ITYPE_LW: $sformat(operands, "%s, %0d(%s)", wsel_str, signed'(imm32), rsel1_str);
      LR_SC:
      begin
        case(funct5_atomic_t'(funct7[6:2]))
          LR: $sformat(operands, "%s, (%s)", wsel_str, rsel1_str);
          SC: $sformat(operands, "%s, %s, (%s)", wsel_str, rsel2_str, rsel1_str);
        endcase
      end
      STYPE: $sformat(operands, "%s, %0d(%s)", rsel2_str, signed'(imm32), rsel1_str);
      JALR: $sformat(operands, "%s, %s, %0d", wsel_str, rsel1_str, signed'(imm32));
      BTYPE: $sformat(operands, "%s, %s, %0d", rsel1_str, rsel2_str, signed'(branch_jump_target_pc));
      JAL: $sformat(operands, "%s, %0d", wsel_str, signed'(branch_jump_target_pc));
      LUI:   $sformat(operands,"%s, %0d", wsel_str, signed'(utype_upper20));
      AUIPC: $sformat(operands,"%s, %0d", wsel_str, signed'(utype_upper20));
      HALT:  $sformat(operands, "");
    endcase
  end

	always @ (*) begin
		case (opcode)
			JAL:      instr_mnemonic = "JAL";
			JALR:      instr_mnemonic = "JALR";
			BTYPE:
			begin
				case(funct3_b_t'(funct3))
					BEQ:      instr_mnemonic = "BEQ";
					BNE:      instr_mnemonic = "BNE";
					BLT:      instr_mnemonic = "BLT";
					BGE:      instr_mnemonic = "BGE";
					BLTU:     instr_mnemonic = "BLTU";
					BGEU:     instr_mnemonic = "BGEU";
				endcase
			end
			STYPE:
			begin
				case(funct3_s_t'(funct3))
					SB:       instr_mnemonic = "SB";
					SH:       instr_mnemonic = "SH";
					SW:       instr_mnemonic = "SW";
				endcase
			end
			ITYPE_LW:
			begin
				case(funct3_ld_i_t'(funct3))
					LB:       instr_mnemonic = "LB";
					LH:       instr_mnemonic = "LH";
					LW:       instr_mnemonic = "LW";
					LBU:      instr_mnemonic = "LBU";
					LHU:      instr_mnemonic = "LHU";
				endcase
			end
			LR_SC:
			begin
				case(funct5_atomic_t'(funct7[6:2]))
					LR:       instr_mnemonic = "LR.W";
					SC:       instr_mnemonic = "SC.W";
				endcase
			end
			ITYPE:
			begin
				case(funct3_i_t'(funct3))
					ADDI:     instr_mnemonic = "ADDI";
					SLTI:     instr_mnemonic = "SLTI";
					SLTIU:    instr_mnemonic = "SLTIU";
					ANDI:     instr_mnemonic = "ANDI";
					ORI:      instr_mnemonic = "ORI";
					XORI:     instr_mnemonic = "XORI";
					SLLI:     instr_mnemonic = "SLLI";
					SRLI_SRAI:    
					begin
						case(funct7_srla_r_t'(funct7))
							SRA: instr_mnemonic = "SRAI";
							SRL: instr_mnemonic = "SRLI";
						endcase
					end
				endcase
			end
			LUI:      instr_mnemonic = "LUI";
			AUIPC:   instr_mnemonic = "AUIPC";
			HALT:     instr_mnemonic = "HALT";
			RTYPE: begin
				case(funct3_r_t'(funct3))
					SLL:  instr_mnemonic = "SLL";
					SRL_SRA:
					begin
						case(funct7_srla_r_t'(funct7))
							SRA: instr_mnemonic = "SRA";
							SRL: instr_mnemonic = "SRL";
						endcase
					end
					ADD_SUB:  
					begin
						case(funct7_r_t'(funct7))
							ADD: instr_mnemonic = "ADD";
							SUB: instr_mnemonic = "SUB";
						endcase
					end
					AND:  instr_mnemonic = "AND";
					OR:   instr_mnemonic = "OR";
					XOR:  instr_mnemonic = "XOR";
					SLT:  instr_mnemonic = "SLT";
					SLTU: instr_mnemonic = "SLTU";
				endcase
			end
			default:  instr_mnemonic = "xxx";
		endcase
	end

	always @ (posedge CLK) begin

		if (enable_pc) begin
			last_opcode <= opcode;
		end

		if (enable_pc) begin
			saved_pc <= pc;
		end

		if (dhit && last_opcode == STYPE) begin
      $sformat(temp_str, "%s(Core %0d): %s", uppercase(saved_pc, 32), CPUID, uppercase(instr, 32));
      $sformat(temp_str, "%s %s %s\n", temp_str, instr_mnemonic, operands);
      $sformat(temp_str, "%s\tPC <-- %s\n", temp_str, uppercase(next_pc, 32));
			$sformat(temp_str,"%s\t[%s]",temp_str, uppercase({16'h0, data_mem_addr[15:0]}, 32));
			$sformat(temp_str, "%s <-- %s\n", temp_str, uppercase(data_mem_store, 32));
			$sformat(output_str, "%s\n", temp_str);
			$fwrite(fp, output_str);
		end

		if (dhit && last_opcode == ITYPE_LW) begin
			$sformat(temp_str, "%s(Core %0d): %s", uppercase(saved_pc, 32), CPUID, uppercase(instr, 32));
      $sformat(temp_str, "%s %s %s\n", temp_str, instr_mnemonic, operands);
      $sformat(temp_str, "%s\tPC <-- %s\n", temp_str, uppercase(next_pc, 32));
			$sformat(ram_str, "\t[word read");
			$sformat(ram_str, "%s from %s]\n", ram_str, uppercase({16'h0, data_mem_addr[15:0]}, 32));
			$sformat(ram_str, "%s\t%s", ram_str, wsel_str);
			$sformat(ram_str, "%s <-- %s\n", ram_str, uppercase(data_mem_load, 32));
			$sformat(output_str, "%s%s\n", temp_str, ram_str);
			$fwrite(fp, output_str);
    end
	end
    
	always @ (posedge CLK) begin

		valid_instr = 1'b1;

		// check for:
				// MEMWB stall -> not committing this cycle
				// instr == NOP && pc == 0 -> inserted NOP/bubble
		if (enable_pc && !((instr == 32'h00000000 || instr == 32'h00000013) && pc == 32'h0)) begin
      $sformat(temp_str, "%s(Core %0d): %s", uppercase(pc, 32), CPUID, uppercase(instr, 32));
      $sformat(temp_str, "%s %s %s\n", temp_str, instr_mnemonic, operands);
      $sformat(temp_str, "%s\tPC <-- %s\n", temp_str, uppercase(next_pc, 32));
      case(opcode)
        RTYPE: 
        begin
          $sformat(temp_str, "%s\t%s <-- %s\n", temp_str, wsel_str, uppercase(reg_file_wdat, 32));
        end
        ITYPE:
        begin
          case(funct3_i_t'(funct3))
            default: $sformat(temp_str, "%s\t%s <-- %s\n", temp_str, wsel_str, uppercase(reg_file_wdat, 32));
          endcase
        end
        BTYPE:
        begin
          // pass
        end
        JAL, JALR: $sformat(temp_str, "%s\t%s <-- %s\n", temp_str, wsel_str, uppercase(reg_file_wdat, 32));
        LUI: $sformat(temp_str, "%s\t%s <-- %s\n", temp_str, wsel_str, uppercase(reg_file_wdat, 32));
        AUIPC: $sformat(temp_str, "%s\t%s <-- %s\n", temp_str, wsel_str, uppercase(reg_file_wdat, 32));
        default: begin
					$sformat(temp_str, "");
					valid_instr = 1'b0;
				end
      endcase
      $sformat(output_str, "%s\n", temp_str);
      if (valid_instr) begin
				$fwrite(fp, output_str);
			end
		end
	end

	final begin: CLOSE_FILE
		$fclose(fp);
	end

endmodule