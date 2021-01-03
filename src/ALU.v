`include "Definitions.v"
module ALU(
	//ALURS
	input wire ALU_en_i,
    input wire[`OpBus] op_i,
    input wire[`DataBus] reg1_i,
    input wire[`DataBus] reg2_i,
    input wire[`TagBus] des_i,
    input wire[`DataBus] imm_i,
    input wire[`AddrBus] pc_i,

    //CDB (-> RS & ROB)
    output reg cdb_en_o,
    output reg[`TagBus] cdb_tag_o,
    output reg[`DataBus] cdb_data_o
);

always @(*) begin
	if (ALU_en_i == `Disable) begin
		// reset
		cdb_en_o = `Disable;
		cdb_tag_o = `Null;
		cdb_data_o = `Null;
	end
	else begin
		cdb_en_o = `Enable;
		cdb_tag_o = des_i;
		cdb_data_o = `Null;
		case (op_i)
			`LUI: cdb_data_o = imm_i;
			`AUIPC: cdb_data_o = imm_i + pc_i;

			`ADD: cdb_data_o = reg1_i + reg2_i;
			`SUB: cdb_data_o = reg1_i - reg2_i;
			`SLL: cdb_data_o = reg1_i << reg2_i[5 : 0];
			`SLT: cdb_data_o = $signed(reg1_i) < $signed(reg2_i);
			`SLTU: cdb_data_o = reg1_i < reg2_i;
			`XOR: cdb_data_o = reg1_i ^ reg2_i;
			`SRL: cdb_data_o = reg1_i >> reg2_i[5 : 0];
			`SRA: cdb_data_o = $signed(reg1_i) >> reg2_i[5 : 0];
			`OR: cdb_data_o = reg1_i | reg2_i;
			`AND: cdb_data_o = reg1_i & reg2_i;

			`ADDI: cdb_data_o = reg1_i + imm_i;
			`SLLI: cdb_data_o = reg1_i << imm_i[5 : 0];
			`SLTI: cdb_data_o = $signed(reg1_i) < $signed(imm_i);
			`SLTIU: cdb_data_o = reg1_i < imm_i;
			`XORI: cdb_data_o = reg1_i ^ imm_i;
			`SRLI: cdb_data_o = reg1_i >> imm_i[5 : 0];
			`SRAI: cdb_data_o = $signed(reg1_i) >> imm_i[5 : 0];
			`ORI: cdb_data_o = reg1_i | imm_i;
			`ANDI: cdb_data_o = reg1_i & imm_i;

			default: cdb_en_o = `Disable;
		endcase
	end
end

endmodule