module IF(
	input wire clk,
	input wire rst,
    input wire rdy,

    //ICache
    input wire inst_valid_i,
    input wire[`InstBus] inst_i,
    output reg inst_en_o,
    output reg[`AddrBus] inst_addr_o,

    //InstQueue
    input wire iq_full_i,
    output reg iq_en_o,
    output reg[`InstBus] iq_inst_o,
    output reg[`AddrBus] iq_pc_o,
    output reg iq_bp_o,

    //ROB
    input wire commit_en_i,
    input wire commit_isjalr_i,
    input wire commit_judge_i,
    input wire commit_bp_i,
    input wire[`AddrBus] commit_pc_i,
    input wire[`AddrBus] commit_oripc_i

    //dbg
//	output reg[`AddrBus] dbg_o
);

reg[`AddrBus] pc;
reg[`AddrBus] npc;
reg[`BPStatusBus] bpstatus[`BPBus];
/*
always @(*) begin
	dbg_o = pc;
end*/

wire[6:0] opcode;
assign opcode = inst_i[6:0];

wire[`DataBus] imm, imm_b;
assign imm = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
assign imm_b = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};

integer i;

always @(posedge clk) begin
	if (rst) begin
		// reset
		pc <= `Null;
		npc <= `Null + `PcStep;
		for (i = 0; i < `BPSize; i = i + 1) begin
			bpstatus[i] <= `WeaklyTaken;
		end
		inst_en_o <= `Disable;
		inst_addr_o <= `Null;
		iq_en_o <= `Disable;
		iq_inst_o <= `Null;
		iq_pc_o <= `Null;
		iq_bp_o <= `Null;
	end
	else if (rdy) begin
		if (commit_en_i == `Enable && commit_isjalr_i == `No) begin
			if (commit_judge_i == `Fail) begin
				case (bpstatus[commit_oripc_i[`BPIndexBus]])
					`StronglyNotTaken: ;
					`WeaklyNotTaken: bpstatus[commit_oripc_i[`BPIndexBus]] <= `StronglyNotTaken;
					`WeaklyTaken: bpstatus[commit_oripc_i[`BPIndexBus]] <= `WeaklyNotTaken;
					`StronglyTaken: bpstatus[commit_oripc_i[`BPIndexBus]] <= `WeaklyTaken;
				endcase
			end
			else begin
				case (bpstatus[commit_oripc_i[`BPIndexBus]])
					`StronglyNotTaken: bpstatus[commit_oripc_i[`BPIndexBus]] <= `WeaklyNotTaken;
					`WeaklyNotTaken: bpstatus[commit_oripc_i[`BPIndexBus]] <= `WeaklyTaken;
					`WeaklyTaken: bpstatus[commit_oripc_i[`BPIndexBus]] <= `StronglyTaken;
					`StronglyTaken: ;
				endcase
			end
		end
		
		if (commit_en_i == `Enable && (commit_judge_i != commit_bp_i || commit_isjalr_i == `Yes)) begin
			pc <= commit_pc_i;
			npc <= commit_pc_i + `PcStep;
			iq_en_o <= `Disable;
			iq_inst_o <= `Null;
			iq_pc_o <= `Null;
			iq_bp_o <= `Null;
			inst_en_o <= `Enable;
			inst_addr_o <= commit_pc_i;
		end
		else if (inst_valid_i == `Valid && iq_full_i != `Full) begin
			if (opcode == 7'b1101111) begin
				pc <= pc + imm;
				npc <= pc + imm + `PcStep;
				iq_en_o <= `Enable;
				iq_inst_o <= inst_i;
				iq_pc_o <= pc;
				iq_bp_o <= `Fail;
				inst_en_o <= `Enable;
				inst_addr_o <= pc + imm;
			end
			else if (opcode == 7'b1100011) begin
				if (bpstatus[pc[`BPIndexBus]] == `StronglyNotTaken || bpstatus[pc[`BPIndexBus]] == `WeaklyNotTaken) begin
					pc <= npc;
					npc <= npc + `PcStep;
					iq_en_o <= `Enable;
					iq_inst_o <= inst_i;
					iq_pc_o <= pc;
					iq_bp_o <= `Fail;
					inst_en_o <= `Enable;
					inst_addr_o <= npc;
				end
				else begin
					pc <= pc + imm_b;
					npc <= pc + imm_b + `PcStep;
					iq_en_o <= `Enable;
					iq_inst_o <= inst_i;
					iq_pc_o <= pc;
					iq_bp_o <= `Suc;
					inst_en_o <= `Enable;
					inst_addr_o <= pc + imm_b;
				end
			end
			else begin
				pc <= npc;
				npc <= npc + `PcStep;
				iq_en_o <= `Enable;
				iq_inst_o <= inst_i;
				iq_pc_o <= pc;
				iq_bp_o <= `Fail;
				inst_en_o <= `Enable;
				inst_addr_o <= npc;
			end
		end
		else begin
			iq_en_o <= `Disable;
			iq_inst_o <= `Null;
			iq_pc_o <= `Null;
			iq_bp_o <= `Fail;
			inst_en_o <= `Enable;
			inst_addr_o <= pc;
		end
	end
end

endmodule