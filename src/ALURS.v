module ALURS(
	input wire clk,
	input wire rst,
	input wire rdy,
	input wire clear,
	
	//Dispatch
	input wire we_i,
	input wire[`OpBus] op_i,
	input wire[`DataBus] imm_i,
	input wire[`AddrBus] pc_i,
	input wire[`TagBus] des_i,

	input wire reg1_valid_i,
    input wire[`TagBus] reg1_tag_i,
    input wire[`DataBus] reg1_data_i,
    input wire reg2_valid_i,
    input wire[`TagBus] reg2_tag_i,
    input wire[`DataBus] reg2_data_i,

	//ID
	output reg RS_valid_o,    

    //CDB
    //ALU
    input wire cdb1_en_i,
    input wire[`TagBus] cdb1_tag_i,
    input wire[`DataBus] cdb1_data_i,
    //LSB
    input wire cdb2_en_i,
    input wire[`TagBus] cdb2_tag_i,
    input wire[`DataBus] cdb2_data_i,
    //Branch
    input wire cdb3_en_i,
    input wire[`TagBus] cdb3_tag_i,
    input wire[`DataBus] cdb3_data_i,
    //ROB
    input wire write_en_i,
    input wire[`TagBus] write_tag_i,
    input wire[`DataBus] write_data_i,

    //ALU
    output reg ALU_en_o,
    output reg[`OpBus] op_o,
    output reg[`DataBus] reg1_o,
    output reg[`DataBus] reg2_o,
    output reg[`TagBus] des_o,
    output reg[`DataBus] imm_o,
    output reg[`AddrBus] pc_o
);

reg[`RSBus] rs_valid;
reg[`OpBus] rs_op[`RSBus];
reg[`TagBus] rs_des[`RSBus];
reg[`DataBus] rs_imm[`RSBus];
reg[`AddrBus] rs_pc[`RSBus];
reg[`RSBus] rs_reg1_valid;
reg[`RSBus] rs_reg2_valid;
reg[`TagBus] rs_reg1_tag[`RSBus];
reg[`TagBus] rs_reg2_tag[`RSBus];
reg[`DataBus] rs_reg1_data[`RSBus];
reg[`DataBus] rs_reg2_data[`RSBus];

wire[`RSBus] empty;
wire[`RSBus] valid;

assign empty = (~rs_valid & (-(~rs_valid)));
assign valid = (rs_valid & rs_reg1_valid & rs_reg2_valid) & (-(rs_valid & rs_reg1_valid & rs_reg2_valid));

//////// Can be faster qwq

integer i;

always @(*) begin
	if (empty == `Null) begin
		RS_valid_o = `Invalid;
	end
	else begin
		RS_valid_o = `Valid;
	end
end

always @(posedge clk) begin
	if (rst || clear) begin
		// reset
		ALU_en_o <= `Disable;
		op_o <= `Null;
		reg1_o <= `Null;
		reg2_o <= `Null;
		des_o <= `Null;
		imm_o <= `Null;
		pc_o <= `Null;
		for (i = 0; i < `RSsize; i = i + 1) begin
			rs_valid[i] <= `Invalid;
			rs_op[i] <= `Null;
			rs_pc[i] <= `Null;
			rs_des[i] <= `Null;
			rs_reg1_valid[i] <= `Invalid;
			rs_reg2_valid[i] <= `Invalid;
			rs_reg1_tag[i] <= `Null;
			rs_reg2_tag[i] <= `Null;
			rs_reg1_data[i] <= `Null;
			rs_reg2_data[i] <= `Null;
		end
	end
	else if (rdy) begin
		for (i = 0; i < `RSsize; i = i + 1) begin
			if (rs_valid[i] == `Valid && rs_reg1_valid[i] == `Invalid) begin
				if (cdb1_en_i == `Enable && rs_reg1_tag[i] == cdb1_tag_i) begin
					rs_reg1_valid[i] <= `Valid;
					rs_reg1_tag[i] <= cdb1_tag_i;
					rs_reg1_data[i] <= cdb1_data_i;
				end
				else if (cdb2_en_i == `Enable && rs_reg1_tag[i] == cdb2_tag_i) begin
					rs_reg1_valid[i] <= `Valid;
					rs_reg1_tag[i] <= cdb2_tag_i;
					rs_reg1_data[i] <= cdb2_data_i;
				end
				else if (cdb3_en_i == `Enable && rs_reg1_tag[i] == cdb3_tag_i) begin
					rs_reg1_valid[i] <= `Valid;
					rs_reg1_tag[i] <= cdb3_tag_i;
					rs_reg1_data[i] <= cdb3_data_i;
				end
				else if (write_en_i == `Enable && rs_reg1_tag[i] == write_tag_i) begin
					rs_reg1_valid[i] <= `Valid;
					rs_reg1_tag[i] <= write_tag_i;
					rs_reg1_data[i] <= write_data_i;
				end
			end
			if (rs_valid[i] == `Valid && rs_reg2_valid[i] == `Invalid) begin
				if (cdb1_en_i == `Enable && rs_reg2_tag[i] == cdb1_tag_i) begin
					rs_reg2_valid[i] <= `Valid;
					rs_reg2_tag[i] <= cdb1_tag_i;
					rs_reg2_data[i] <= cdb1_data_i;
				end
				else if (cdb2_en_i == `Enable && rs_reg2_tag[i] == cdb2_tag_i) begin
					rs_reg2_valid[i] <= `Valid;
					rs_reg2_tag[i] <= cdb2_tag_i;
					rs_reg2_data[i] <= cdb2_data_i;
				end
				else if (cdb3_en_i == `Enable && rs_reg2_tag[i] == cdb3_tag_i) begin
					rs_reg2_valid[i] <= `Valid;
					rs_reg2_tag[i] <= cdb3_tag_i;
					rs_reg2_data[i] <= cdb3_data_i;
				end
				else if (write_en_i == `Enable && rs_reg2_tag[i] == write_tag_i) begin
					rs_reg2_valid[i] <= `Valid;
					rs_reg2_tag[i] <= write_tag_i;
					rs_reg2_data[i] <= write_data_i;
				end
			end
		end

		if (valid == `Null) begin
			ALU_en_o <= `Disable;
			op_o <= `Null;
			reg1_o <= `Null;
			reg2_o <= `Null;
			des_o <= `Null;
			imm_o <= `Null;
			pc_o <= `Null;
		end
		else
		for (i = 0; i < `RSsize; i = i + 1) begin
			if (valid[i] == `Valid) begin
				ALU_en_o <= `Enable;
				op_o <= rs_op[i];
				pc_o <= rs_pc[i];
				reg1_o <= rs_reg1_data[i];
				reg2_o <= rs_reg2_data[i];
				des_o <= rs_des[i];
				imm_o <= rs_imm[i];
				rs_valid[i] <= `Invalid;
				/*
				rs_op[i] <= `Null;
				rs_pc[i] <= `Null;
				rs_des[i] <= `Null;
				rs_reg1_valid <= `Invalid;
				rs_reg2_valid <= `Invalid;
				rs_reg1_tag[i] <= `Null;
				rs_reg2_tag[i] <= `Null;
				rs_reg1_data[i] <= `Null;
				rs_reg2_data[i] <= `Null;*/
			end
		end

		if (we_i == `Enable && empty != `Null) begin
			for (i = 0; i < `RSsize; i = i + 1) begin
				if (empty[i] == `Nonempty) begin
					rs_valid[i] <= `Valid;
					rs_op[i] <= op_i;
					rs_imm[i] <= imm_i;
					rs_pc[i] <= pc_i;
					rs_des[i] <= des_i;
					rs_reg1_valid[i] <= reg1_valid_i;
					rs_reg2_valid[i] <= reg2_valid_i;
					rs_reg1_tag[i] <= reg1_tag_i;
					rs_reg2_tag[i] <= reg2_tag_i;
					rs_reg1_data[i] <= reg1_data_i;
					rs_reg2_data[i] <= reg2_data_i;
				end
			end
		end
	end
end

endmodule
