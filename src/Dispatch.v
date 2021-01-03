module Dispatch(
	//ID
	input wire disp_en_i,
	input wire[`OpBus] op_i,
	input wire[`DataBus] imm_i,
	input wire[`AddrBus] pc_i,
	input wire[`TagBus] des_i,
	input wire bp_i,
//	input wire[`TimeBus] time_i,

	//RegFile
	input wire reg1_valid_i,
    input wire[`TagBus] reg1_tag_i,
    input wire[`DataBus] reg1_data_i,
    input wire reg2_valid_i,
    input wire[`TagBus] reg2_tag_i,
    input wire[`DataBus] reg2_data_i,

    //ROB
    output reg ROB_reg1_re_o,
    output reg[`TagBus] ROB_reg1_tag_o,
    input wire ROB_reg1_valid_i,
    input wire[`DataBus] ROB_reg1_data_i,
    output reg ROB_reg2_re_o,
    output reg[`TagBus] ROB_reg2_tag_o,
    input wire ROB_reg2_valid_i,
    input wire[`DataBus] ROB_reg2_data_i,

    //RS
    output reg RS_we_o,
    output reg[`OpBus] op_o,
	output reg[`DataBus] imm_o,
	output reg[`AddrBus] pc_o,
	output reg[`TagBus] des_o,

    output reg reg1_valid_o,
    output reg[`TagBus] reg1_tag_o,
    output reg[`DataBus] reg1_data_o,
    output reg reg2_valid_o,
    output reg[`TagBus] reg2_tag_o,
    output reg[`DataBus] reg2_data_o,

    //LoadStoreRS
    output reg LS_RS_we_o,
	output reg[`OpBus] LS_op_o,
	output reg[`DataBus] LS_imm_o,
	output reg[`TagBus] LS_des_o,
//	output reg[`TimeBus] LS_time_o,

	output reg LS_reg1_valid_o,
    output reg[`TagBus] LS_reg1_tag_o,
    output reg[`DataBus] LS_reg1_data_o,
    output reg LS_reg2_valid_o,
    output reg[`TagBus] LS_reg2_tag_o,
    output reg[`DataBus] LS_reg2_data_o,

    //BranchRS
    output reg Branch_RS_we_o,
    output reg[`OpBus] Branch_op_o,
	output reg[`DataBus] Branch_imm_o,
	output reg[`AddrBus] Branch_pc_o,
	output reg[`TagBus] Branch_des_o,
	output reg Branch_bp_o,

    output reg Branch_reg1_valid_o,
    output reg[`TagBus] Branch_reg1_tag_o,
    output reg[`DataBus] Branch_reg1_data_o,
    output reg Branch_reg2_valid_o,
    output reg[`TagBus] Branch_reg2_tag_o,
    output reg[`DataBus] Branch_reg2_data_o
);

wire LSTag, BranchTag;

assign LSTag = (op_i >= `LB && op_i <= `SW);
assign BranchTag = (op_i >= `JAL && op_i <= `BGEU);

always @(*) begin
	if (disp_en_i == `Enable) begin
		if (LSTag) begin
			RS_we_o = `Disable;
			op_o = `Null;
			imm_o = `Null;
			pc_o = `Null;
			des_o = `Null;

			LS_RS_we_o = `Enable;
			LS_op_o = op_i;
			LS_imm_o = imm_i;
			LS_des_o = des_i;
//			LS_time_o = time_i;

			Branch_RS_we_o = `Disable;
			Branch_op_o = `Null;
			Branch_imm_o = `Null;
			Branch_pc_o = `Null;
			Branch_des_o = `Null;
			Branch_bp_o = `Null;
		end
		else if (BranchTag) begin
			RS_we_o = `Disable;
			op_o = `Null;
			imm_o = `Null;
			pc_o = `Null;
			des_o = `Null;

			LS_RS_we_o = `Disable;
			LS_op_o = `Null;
			LS_imm_o = `Null;
			LS_des_o = `Null;
	//		LS_time_o = `Null;

			Branch_RS_we_o = `Enable;
			Branch_op_o = op_i;
			Branch_imm_o = imm_i;
			Branch_pc_o = pc_i;
			Branch_des_o = des_i;
			Branch_bp_o = bp_i;
		end
		else begin
			RS_we_o = `Enable;
			op_o = op_i;
			imm_o = imm_i;
			pc_o = pc_i;
			des_o = des_i;

			LS_RS_we_o = `Disable;
			LS_op_o = `Null;
			LS_imm_o = `Null;
			LS_des_o = `Null;
	//		LS_time_o = `Null;
		
			Branch_RS_we_o = `Disable;
			Branch_op_o = `Null;
			Branch_imm_o = `Null;
			Branch_pc_o = `Null;
			Branch_des_o = `Null;
			Branch_bp_o = `Null;
		end
	end
	else begin
		RS_we_o = `Disable;
		op_o = `Null;
		imm_o = `Null;
		pc_o = `Null;
		des_o = `Null;

		LS_RS_we_o = `Disable;
		LS_op_o = `Null;
		LS_imm_o = `Null;
		LS_des_o = `Null;
//		LS_time_o = `Null;

		Branch_RS_we_o = `Disable;
		Branch_op_o = `Null;
		Branch_imm_o = `Null;
		Branch_pc_o = `Null;
		Branch_des_o = `Null;
		Branch_bp_o = `Null;
	end
end

always @(*) begin
	if (disp_en_i == `Enable) begin
		if (reg1_valid_i == `Valid) begin
			ROB_reg1_re_o = `Disable;
			ROB_reg1_tag_o = `Null;
		end
		else begin
			ROB_reg1_re_o = `Enable;
			ROB_reg1_tag_o = reg1_tag_i;
		end

		if (reg2_valid_i == `Valid) begin
			ROB_reg2_re_o = `Disable;
			ROB_reg2_tag_o = `Null;
		end
		else begin
			ROB_reg2_re_o = `Enable;
			ROB_reg2_tag_o = reg2_tag_i;
		end
	end
	else begin
		ROB_reg1_re_o = `Disable;
		ROB_reg2_re_o = `Disable;
		ROB_reg1_tag_o = `Null;
		ROB_reg2_tag_o = `Null;
	end
end

always @(*) begin
	if (disp_en_i == `Enable) begin
		if (reg1_valid_i == `Valid) begin
			if (LSTag) begin
				LS_reg1_valid_o = `Valid;
				LS_reg1_tag_o = `Null;
				LS_reg1_data_o = reg1_data_i;

				Branch_reg1_valid_o = `Invalid;
				Branch_reg1_tag_o = `Null;
				Branch_reg1_data_o = `Null;

				reg1_valid_o = `Invalid;
				reg1_tag_o = `Null;
				reg1_data_o = `Null;
			end
			else if (BranchTag) begin
				Branch_reg1_valid_o = `Valid;
				Branch_reg1_tag_o = `Null;
				Branch_reg1_data_o = reg1_data_i;

				LS_reg1_valid_o = `Invalid;
				LS_reg1_tag_o = `Null;
				LS_reg1_data_o = `Null;

				reg1_valid_o = `Invalid;
				reg1_tag_o = `Null;
				reg1_data_o = `Null;
			end
			else begin
				reg1_valid_o = `Valid;
				reg1_tag_o = `Null;
				reg1_data_o = reg1_data_i;

				LS_reg1_valid_o = `Invalid;
				LS_reg1_tag_o = `Null;
				LS_reg1_data_o = `Null;

				Branch_reg1_valid_o = `Invalid;
				Branch_reg1_tag_o = `Null;
				Branch_reg1_data_o = `Null;
			end
		end
		else begin
			if (ROB_reg1_valid_i == `Valid) begin
				if (LSTag) begin
					LS_reg1_valid_o = `Valid;
					LS_reg1_tag_o = `Null;
					LS_reg1_data_o = ROB_reg1_data_i;

					Branch_reg1_valid_o = `Invalid;
					Branch_reg1_tag_o = `Null;
					Branch_reg1_data_o = `Null;

					reg1_valid_o = `Invalid;
					reg1_tag_o = `Null;
					reg1_data_o = `Null;
				end
				else if (BranchTag) begin
					Branch_reg1_valid_o = `Valid;
					Branch_reg1_tag_o = `Null;
					Branch_reg1_data_o = ROB_reg1_data_i;

					LS_reg1_valid_o = `Invalid;
					LS_reg1_tag_o = `Null;
					LS_reg1_data_o = `Null;

					reg1_valid_o = `Invalid;
					reg1_tag_o = `Null;
					reg1_data_o = `Null;
				end
				else begin
					reg1_valid_o = `Valid;
					reg1_tag_o = `Null;
					reg1_data_o = ROB_reg1_data_i;

					LS_reg1_valid_o = `Invalid;
					LS_reg1_tag_o = `Null;
					LS_reg1_data_o = `Null;

					Branch_reg1_valid_o = `Invalid;
					Branch_reg1_tag_o = `Null;
					Branch_reg1_data_o = `Null;
				end
			end
			else begin
				if (LSTag) begin
					LS_reg1_valid_o = `Invalid;
					LS_reg1_tag_o = reg1_tag_i;
					LS_reg1_data_o = `Null;

					Branch_reg1_valid_o = `Invalid;
					Branch_reg1_tag_o = `Null;
					Branch_reg1_data_o = `Null;

					reg1_valid_o = `Invalid;
					reg1_tag_o = `Null;
					reg1_data_o = `Null;
				end
				else if (BranchTag) begin
					Branch_reg1_valid_o = `Invalid;
					Branch_reg1_tag_o = reg1_tag_i;
					Branch_reg1_data_o = `Null;

					LS_reg1_valid_o = `Invalid;
					LS_reg1_tag_o = `Null;
					LS_reg1_data_o = `Null;

					reg1_valid_o = `Invalid;
					reg1_tag_o = `Null;
					reg1_data_o = `Null;
				end
				else begin
					reg1_valid_o = `Invalid;
					reg1_tag_o = reg1_tag_i;
					reg1_data_o = `Null;

					LS_reg1_valid_o = `Invalid;
					LS_reg1_tag_o = `Null;
					LS_reg1_data_o = `Null;

					Branch_reg1_valid_o = `Invalid;
					Branch_reg1_tag_o = `Null;
					Branch_reg1_data_o = `Null;
				end
			end
		end
	end
	else begin
		LS_reg1_valid_o = `Invalid;
		LS_reg1_tag_o = `Null;
		LS_reg1_data_o = `Null;

		Branch_reg1_valid_o = `Invalid;
		Branch_reg1_tag_o = `Null;
		Branch_reg1_data_o = `Null;

		reg1_valid_o = `Invalid;
		reg1_tag_o = `Null;
		reg1_data_o = `Null;
	end
end

always @(*) begin
	if (disp_en_i == `Enable) begin
		if (reg2_valid_i == `Valid) begin
			if (LSTag) begin
				LS_reg2_valid_o = `Valid;
				LS_reg2_tag_o = `Null;
				LS_reg2_data_o = reg2_data_i;

				Branch_reg2_valid_o = `Invalid;
				Branch_reg2_tag_o = `Null;
				Branch_reg2_data_o = `Null;

				reg2_valid_o = `Invalid;
				reg2_tag_o = `Null;
				reg2_data_o = `Null;
			end
			else if (BranchTag) begin
				Branch_reg2_valid_o = `Valid;
				Branch_reg2_tag_o = `Null;
				Branch_reg2_data_o = reg2_data_i;

				LS_reg2_valid_o = `Invalid;
				LS_reg2_tag_o = `Null;
				LS_reg2_data_o = `Null;

				reg2_valid_o = `Invalid;
				reg2_tag_o = `Null;
				reg2_data_o = `Null;
			end
			else begin
				reg2_valid_o = `Valid;
				reg2_tag_o = `Null;
				reg2_data_o = reg2_data_i;

				LS_reg2_valid_o = `Invalid;
				LS_reg2_tag_o = `Null;
				LS_reg2_data_o = `Null;

				Branch_reg2_valid_o = `Invalid;
				Branch_reg2_tag_o = `Null;
				Branch_reg2_data_o = `Null;
			end
		end
		else begin
			if (ROB_reg2_valid_i == `Valid) begin
				if (LSTag) begin
					LS_reg2_valid_o = `Valid;
					LS_reg2_tag_o = `Null;
					LS_reg2_data_o = ROB_reg2_data_i;

					Branch_reg2_valid_o = `Invalid;
					Branch_reg2_tag_o = `Null;
					Branch_reg2_data_o = `Null;

					reg2_valid_o = `Invalid;
					reg2_tag_o = `Null;
					reg2_data_o = `Null;
				end
				else if (BranchTag) begin
					Branch_reg2_valid_o = `Valid;
					Branch_reg2_tag_o = `Null;
					Branch_reg2_data_o = ROB_reg2_data_i;

					LS_reg2_valid_o = `Invalid;
					LS_reg2_tag_o = `Null;
					LS_reg2_data_o = `Null;

					reg2_valid_o = `Invalid;
					reg2_tag_o = `Null;
					reg2_data_o = `Null;
				end
				else begin
					reg2_valid_o = `Valid;
					reg2_tag_o = `Null;
					reg2_data_o = ROB_reg2_data_i;

					LS_reg2_valid_o = `Invalid;
					LS_reg2_tag_o = `Null;
					LS_reg2_data_o = `Null;

					Branch_reg2_valid_o = `Invalid;
					Branch_reg2_tag_o = `Null;
					Branch_reg2_data_o = `Null;
				end
			end
			else begin
				if (LSTag) begin
					LS_reg2_valid_o = `Invalid;
					LS_reg2_tag_o = reg2_tag_i;
					LS_reg2_data_o = `Null;

					Branch_reg2_valid_o = `Invalid;
					Branch_reg2_tag_o = `Null;
					Branch_reg2_data_o = `Null;

					reg2_valid_o = `Invalid;
					reg2_tag_o = `Null;
					reg2_data_o = `Null;
				end
				else if (BranchTag) begin
					Branch_reg2_valid_o = `Invalid;
					Branch_reg2_tag_o = reg2_tag_i;
					Branch_reg2_data_o = `Null;

					LS_reg2_valid_o = `Invalid;
					LS_reg2_tag_o = `Null;
					LS_reg2_data_o = `Null;

					reg2_valid_o = `Invalid;
					reg2_tag_o = `Null;
					reg2_data_o = `Null;
				end
				else begin
					reg2_valid_o = `Invalid;
					reg2_tag_o = reg2_tag_i;
					reg2_data_o = `Null;

					LS_reg2_valid_o = `Invalid;
					LS_reg2_tag_o = `Null;
					LS_reg2_data_o = `Null;

					Branch_reg2_valid_o = `Invalid;
					Branch_reg2_tag_o = `Null;
					Branch_reg2_data_o = `Null;
				end
			end
		end
	end
	else begin
		LS_reg2_valid_o = `Invalid;
		LS_reg2_tag_o = `Null;
		LS_reg2_data_o = `Null;

		Branch_reg2_valid_o = `Invalid;
		Branch_reg2_tag_o = `Null;
		Branch_reg2_data_o = `Null;

		reg2_valid_o = `Invalid;
		reg2_tag_o = `Null;
		reg2_data_o = `Null;
	end
end

endmodule