module ID(
/*	input wire clk,
	input wire rst,
	input wire rdy,
	input wire clear,*/
	
	//stall
	input wire iq_empty_i,
	input wire ROB_valid_i,
	input wire RS_valid_i,
	input wire LS_RS_valid_i,
	input wire Branch_RS_valid_i,

	//InstQueue
	input wire[`InstBus] inst_i,
	input wire[`AddrBus] pc_i,
	input wire bp_i,
	output reg iq_re_o,

	//RegFile
	output reg reg1_re_o,
	output reg[`NameBus] reg1_o,
	output reg reg2_re_o,
	output reg[`NameBus] reg2_o,

	output reg rd_we_o,
	output reg[`NameBus] rd_addr_o,
	output reg[`TagBus] rd_tag_o,

	//Dispatch
	output reg disp_en_o,
	output reg[`OpBus] op_o,
	output reg[`DataBus] imm_o,
	output reg[`AddrBus] pc_o,
	output reg[`TagBus] des_o,
	output reg bp_o,
//	output reg[`TimeBus] time_o,

	//ROB
	input wire[`TagBus] ROB_tag_i,
	output reg ROB_we_o,
	output reg ROB_valid_o,
	output reg[`NameBus] ROB_addr_o,
	output reg[`TypeBus] ROB_type_o,
	output reg ROB_bp_o
);

//reg[`TimeBus] Time;

wire[6:0] opcode;
wire[2:0] funct;
wire LSTag;
wire BranchTag;
wire stall;

assign opcode = inst_i[6:0];
assign funct = inst_i[14:12];
assign LSTag = (opcode == 7'b0000011 || opcode == 7'b0100011);
assign BranchTag = (opcode == 7'b1101111 || opcode == 7'b1100111 || opcode == 7'b1100011);
assign stall = (iq_empty_i == `Empty) || (ROB_valid_i == `Invalid)
				|| (RS_valid_i == `Invalid && !LSTag && !BranchTag)
				|| (LS_RS_valid_i == `Invalid && LSTag)
				|| (Branch_RS_valid_i == `Invalid && BranchTag);
/*
always @(posedge clk) begin
	if (rst || clear) begin
		// reset
		Time <= `Null;
	end
	else begin
		Time <= Time + 1;
	end
end*/

always @(*) begin/*
	if (rst) begin
		// reset
		disp_en_o = `Disable;
		op_o = `Null;
		imm_o = `Null;
		pc_o = `Null;
		reg1_re_o = `Disable;
		reg1_o = `Null;
		reg2_re_o = `Disable;
		reg2_o = `Null;

		ROB_we_o = `Disable;
		ROB_valid_o = `Invalid;
		ROB_addr_o = `Null;
		ROB_type_o = `Null;

		rd_addr_o = `Null;
		rd_tag_o = `Null;
		des_o = `Null;
		iq_re_o = `Disable;
		rd_we_o = `Disable;

	//	time_o = `Null;
	end
	else begin*/
		if (stall == `Stall) begin
			disp_en_o = `Disable;
			op_o = `Null;
			imm_o = `Null;
			pc_o = `Null;
			reg1_re_o = `Disable;
			reg1_o = `Null;
			reg2_re_o = `Disable;
			reg2_o = `Null;

			ROB_we_o = `Disable;
			ROB_valid_o = `Invalid;
			ROB_addr_o = `Null;
			ROB_type_o = `Null;
			ROB_bp_o = `Null;

			rd_addr_o = `Null;
			rd_tag_o = `Null;
			des_o = `Null;
			bp_o = `Null;
			iq_re_o = `Disable;
			rd_we_o = `Disable;

		//	time_o = `Null;
		end
		else begin
			pc_o = pc_i;
			disp_en_o = `Enable;
			iq_re_o = `Enable;
			op_o = `Null;
			ROB_bp_o = `Null;
			bp_o = `Null;
		//	time_o = `Null;
			case (opcode)
				7'b0110111: begin
					op_o = `LUI;
					imm_o = {inst_i[31:12], 12'b0};
					reg1_re_o = `Enable;
					reg1_o = `Null;
					reg2_re_o = `Enable;
					reg2_o = `Null;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TReg;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end
				7'b0010111: begin
					op_o = `AUIPC;
					imm_o = {inst_i[31:12], 12'b0};
					reg1_re_o = `Enable;
					reg1_o = `Null;
					reg2_re_o = `Enable;
					reg2_o = `Null;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TReg;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end
				7'b1101111: begin
					op_o = `JAL;
					imm_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
					reg1_re_o = `Enable;
					reg1_o = `Null;
					reg2_re_o = `Enable;
					reg2_o = `Null;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TBoth;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end
				7'b1100111: begin
					op_o = `JALR;
					imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
					reg1_re_o = `Enable;
					reg1_o = inst_i[19:15];
					reg2_re_o = `Enable;
					reg2_o = `Null;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TBoth;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end
				7'b1100011: begin
					case (funct)
						3'b000: op_o = `BEQ;
						3'b001: op_o = `BNE;
						3'b100: op_o = `BLT;
						3'b101: op_o = `BGE;
						3'b110: op_o = `BLTU;
						3'b111: op_o = `BGEU;
					endcase
					imm_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
        	        reg1_re_o = `Enable;
                	reg1_o = inst_i[19:15];
            	    reg2_re_o = `Enable;
					reg2_o = inst_i[24:20];
					iq_re_o = `Enable;
					rd_we_o = `Disable;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = `Null;
					ROB_type_o = `TPc;
					ROB_bp_o = bp_i;

                	rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					bp_o = bp_i;
					rd_addr_o = `Null;
				end
				7'b0000011: begin
					case (funct)
						3'b000: op_o = `LB;
						3'b001: op_o = `LH;
						3'b010: op_o = `LW;
						3'b100: op_o = `LBU;
						3'b101: op_o = `LHU;
					endcase
					imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
					reg1_re_o = `Enable;
					reg1_o = inst_i[19:15];
					reg2_re_o = `Enable;
					reg2_o = `Null;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TLoad;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
				//	time_o = Time;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end
				7'b0100011: begin
					case (funct)
						3'b000: op_o = `SB;
						3'b001: op_o = `SH;
						3'b010: op_o = `SW;
					endcase
					imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                	reg1_re_o = `Enable;
					reg1_o = inst_i[19:15];
					reg2_re_o = `Enable;
					reg2_o = inst_i[24:20];
					iq_re_o = `Enable;
					rd_we_o = `Disable;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = `Null;
					ROB_type_o = `TMem;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
				//	time_o = Time;
					rd_addr_o = `Null;
				end
				7'b0010011: begin
					case (funct)
						3'b000: op_o = `ADDI;
						3'b001: op_o = `SLLI;
						3'b010: op_o = `SLTI;
						3'b011: op_o = `SLTIU;
						3'b100: op_o = `XORI;
						3'b110: op_o = `ORI;
						3'b111: op_o = `ANDI;
						3'b101: begin
							case (inst_i[30])
								1'b0: op_o = `SRLI;
								1'b1: op_o = `SRAI;
							endcase
						end 
					endcase
					if (funct != 3'b101 && funct != 3'b001)
						imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
					else
						imm_o = {{26{1'b0}}, inst_i[25:20]};
    	            reg1_re_o = `Enable;
        	        reg1_o = inst_i[19:15];
            	    reg2_re_o = `Enable;
                	reg2_o = `Null;

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TReg;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end
				7'b0110011: begin
					case (funct)
						3'b000: begin
							case(inst_i[30])
								1'b0: op_o = `ADD;
								1'b1: op_o = `SUB;
							endcase
						end
						3'b001: op_o = `SLL;
						3'b010: op_o = `SLT;
						3'b011: op_o = `SLTU;
						3'b100: op_o = `XOR;
						3'b110: op_o = `OR;
						3'b111: op_o = `AND;
						3'b101: begin
							case(inst_i[30])
								1'b0: op_o = `SRL;
								1'b1: op_o = `SRA;
							endcase
						end 
					endcase
					imm_o = `Null;
					reg1_re_o = `Enable;
					reg1_o = inst_i[19:15];
					reg2_re_o = `Enable;
					reg2_o = inst_i[24:20];

					ROB_we_o = `Enable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = inst_i[11:7];
					ROB_type_o = `TReg;

					rd_tag_o = ROB_tag_i;
					des_o = ROB_tag_i;
					iq_re_o = `Enable;
					rd_we_o = `Enable;
					rd_addr_o = inst_i[11:7];
				end

				default: begin
					disp_en_o = `Disable;
					op_o = `Null;
					imm_o = `Null;
					pc_o = `Null;
					reg1_re_o = `Disable;
					reg1_o = `Null;
					reg2_re_o = `Disable;
					reg2_o = `Null;

					ROB_we_o = `Disable;
					ROB_valid_o = `Invalid;
					ROB_addr_o = `Null;
					ROB_type_o = `Null;

					rd_addr_o = `Null;
					rd_tag_o = `Null;
					des_o = `Null;
					iq_re_o = `Disable;
					rd_we_o = `Disable;
				end
			endcase
		end

//	end
end

endmodule