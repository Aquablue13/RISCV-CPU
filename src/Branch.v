module Branch(
	//BranchRS
	input wire Branch_en_i,
    input wire[`OpBus] op_i,
    input wire[`DataBus] reg1_i,
    input wire[`DataBus] reg2_i,
    input wire[`TagBus] des_i,
    input wire[`DataBus] imm_i,
    input wire[`AddrBus] pc_i,
    input wire bp_i,

    //CDB (-> RS & ROB)
    output reg cdb_en_o,
    output reg[`TagBus] cdb_tag_o,
    output reg cdb_judge_o,
    output reg[`AddrBus] cdb_pc_o,
    output reg[`AddrBus] cdb_oripc_o,
    output reg[`DataBus] cdb_data_o
);

always @(*) begin
	if (Branch_en_i == `Disable) begin
		cdb_en_o = `Disable;
		cdb_tag_o = `Null;
		cdb_judge_o = `Fail;
		cdb_data_o = `Null;
		cdb_pc_o = `Null;
		cdb_oripc_o = `Null;
	end
	else begin
		cdb_en_o = `Enable;
		cdb_tag_o = des_i;
		cdb_judge_o = `Fail;
		cdb_data_o = `Null;
		cdb_oripc_o = pc_i;
		cdb_pc_o = pc_i + `PcStep;
		if (bp_i == `Suc) begin
			cdb_pc_o = pc_i + `PcStep;
			case (op_i)
				`JAL: begin
					cdb_data_o = pc_i + `PcStep;
					cdb_judge_o = `Fail;
				end 
				`JALR: begin
					cdb_data_o = pc_i + `PcStep;
					cdb_judge_o = `Suc;
				end

				`BEQ: begin
					cdb_judge_o = (reg1_i == reg2_i);
				end
				`BNE: begin
					cdb_judge_o = (reg1_i != reg2_i);
				end
				`BLT: begin
					cdb_judge_o = ($signed(reg1_i) < $signed(reg2_i));
				end
				`BGE: begin
					cdb_judge_o = ($signed(reg1_i) >= $signed(reg2_i));
				end
				`BLTU: begin
					cdb_judge_o = (reg1_i < reg2_i);
				end
				`BGEU: begin
					cdb_judge_o = (reg1_i >= reg2_i);
				end

				default:
					cdb_en_o = `Disable;
			endcase
		end
		else begin
			case (op_i)
				`JAL: begin
					cdb_data_o = pc_i + `PcStep;
					cdb_judge_o = `Fail;
					cdb_pc_o = pc_i + $signed(imm_i);
				end 
				`JALR: begin
					cdb_data_o = pc_i + `PcStep;
					cdb_judge_o = `Suc;
					cdb_pc_o = (reg1_i + $signed(imm_i)) & `JALRnum;
				end

				`BEQ: begin
					cdb_pc_o = pc_i + $signed(imm_i);
					cdb_judge_o = (reg1_i == reg2_i);
				end
				`BNE: begin
					cdb_pc_o = pc_i + $signed(imm_i);
					cdb_judge_o = (reg1_i != reg2_i);
				end
				`BLT: begin
					cdb_pc_o = pc_i + $signed(imm_i);
					cdb_judge_o = ($signed(reg1_i) < $signed(reg2_i));
				end
				`BGE: begin
					cdb_pc_o = pc_i + $signed(imm_i);
					cdb_judge_o = ($signed(reg1_i) >= $signed(reg2_i));
				end
				`BLTU: begin
					cdb_pc_o = pc_i + $signed(imm_i);
					cdb_judge_o = (reg1_i < reg2_i);
				end
				`BGEU: begin
					cdb_pc_o = pc_i + $signed(imm_i);
					cdb_judge_o = (reg1_i >= reg2_i);
				end

				default:
					cdb_en_o = `Disable;
			endcase
		end
		
	end
end

endmodule