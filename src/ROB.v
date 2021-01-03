module ROB(
	input wire clk,
    input wire rst,
    input wire rdy,

    output reg clear,

    //ID
    output reg ROB_valid_o,

    output reg[`TagBus] ID_tag_o,
    input wire we_i,
    input wire ID_valid_i,
    input wire[`NameBus] ID_addr_i,
    input wire[`TypeBus] ID_type_i,
    input wire ID_bp_i,

    //LoadStoreBuffer
    output reg commit_en_o,

	//Dispatch
    input wire reg1_re_i,
    input wire[`TagBus] reg1_tag_i,
    output reg reg1_valid_o,
    output reg[`DataBus] reg1_data_o,
    input wire reg2_re_i,
    input wire[`TagBus] reg2_tag_i,
    output reg reg2_valid_o,
    output reg[`DataBus] reg2_data_o,

    //Regfile & (ALURS & LoadStoreRS & BranchRS)
    output reg write_en_o,
    output reg[`NameBus] write_addr_o,
    output reg[`TagBus] write_tag_o,
    output reg[`DataBus] write_data_o,

    //CDB
    input wire cdb_en_i,
    input wire[`TagBus] cdb_tag_i,
    input wire[`DataBus] cdb_data_i,

   	input wire cdb_LS_en_i,
    input wire[`TagBus] cdb_LS_tag_i,
    input wire[`DataBus] cdb_LS_data_i,

    input wire cdb_Branch_en_i,
    input wire[`TagBus] cdb_Branch_tag_i,
    input wire cdb_Branch_judge_i,
    input wire[`AddrBus] cdb_Branch_pc_i,
    input wire[`AddrBus] cdb_Branch_oripc_i,
    input wire[`DataBus] cdb_Branch_data_i,

    //IF
    output reg IF_en_o,
    output reg IF_isjalr_o,
    output reg IF_judge_o,
    output reg IF_bp_o,
    output reg[`AddrBus] IF_pc_o,
    output reg[`AddrBus] IF_oripc_o
);

reg[`ROBPBus] head, tail;
reg[`ROBlenBus] vas;
reg[`NameBus] addr[`ROBlenBus];
reg[`TypeBus] type[`ROBlenBus];
reg[`DataBus] data[`ROBlenBus];
reg judge[`ROBlenBus];
reg[`AddrBus] pc[`ROBlenBus];
reg[`AddrBus] oripc[`ROBlenBus];
reg bp[`ROBlenBus];

reg LasMove;

wire[`ROBPBus] head_n, tail_n, head_nxt, tail_nxt, tail_nnxt;

assign head_nxt = (head == `ROBMaxm) ? `Null : head + `ROBStep;
assign tail_n = (we_i == `Enable) ? ((tail == `ROBMaxm) ? `Null : tail + we_i) : tail;
assign tail_nxt = (tail_n == `ROBMaxm) ? `Null : tail_n + `ROBStep;
assign tail_nnxt = (tail_nxt == `ROBMaxm) ? `Null : tail_nxt + `ROBStep;

always @(*) begin
	if (reg1_re_i == `Enable) begin
		if (vas[reg1_tag_i] == `Valid) begin
			reg1_valid_o = `Valid;
			reg1_data_o = data[reg1_tag_i];
		end
		else if (cdb_en_i == `Enable && cdb_tag_i == reg1_tag_i) begin
			reg1_valid_o = `Valid;
			reg1_data_o = cdb_data_i;
		end
		else if (cdb_LS_en_i == `Enable && cdb_LS_tag_i == reg1_tag_i) begin
			reg1_valid_o = `Valid;
			reg1_data_o = cdb_LS_data_i;
		end
		else if (cdb_Branch_en_i == `Enable && cdb_Branch_tag_i == reg1_tag_i) begin
			reg1_valid_o = `Valid;
			reg1_data_o = cdb_Branch_data_i;
		end
		else begin
			reg1_valid_o = `Invalid;
			reg1_data_o = `Null;
		end
	end
	else begin
		reg1_valid_o = `Invalid;
		reg1_data_o = `Null;
	end
end

always @(*) begin
	if (reg2_re_i == `Enable) begin
		if (vas[reg2_tag_i] == `Valid) begin
			reg2_valid_o = `Valid;
			reg2_data_o = data[reg2_tag_i];
		end
		else if (cdb_en_i == `Enable && cdb_tag_i == reg2_tag_i) begin
			reg2_valid_o = `Valid;
			reg2_data_o = cdb_data_i;
		end
		else if (cdb_LS_en_i == `Enable && cdb_LS_tag_i == reg2_tag_i) begin
			reg2_valid_o = `Valid;
			reg2_data_o = cdb_LS_data_i;
		end
		else if (cdb_Branch_en_i == `Enable && cdb_Branch_tag_i == reg2_tag_i) begin
			reg2_valid_o = `Valid;
			reg2_data_o = cdb_Branch_data_i;
		end
		else begin
			reg2_valid_o = `Invalid;
			reg2_data_o = `Null;
		end
	end
	else begin
		reg2_valid_o = `Invalid;
		reg2_data_o = `Null;
	end
end

reg dgb;

always @(posedge clk) begin
	if (rst || clear) begin
		// reset
		vas <= `Null;
		head <= `Null;
		tail <= `Null;
		LasMove <= `Disable;
		ROB_valid_o <= `Valid;
		ID_tag_o <= `Null;
		clear <= `Disable;
		commit_en_o <= `Disable;
		IF_en_o <= `Disable;
	end
	else if (rdy) begin
		ID_tag_o <= tail_n;
		tail <= tail_n;
		ROB_valid_o <= (tail_nnxt == head || tail_nxt == head) ? `Invalid : `Valid;

		if ((tail == head && we_i == `Enable && (ID_type_i == `TMem || ID_type_i == `TLoad))
			|| (tail != head && LasMove == `Enable && (type[head] == `TMem || type[head] == `TLoad))) begin
			commit_en_o <= `Enable;
		end
		else begin
			commit_en_o <= `Disable;
		end

		if (we_i == `Enable) begin
			vas[tail] <= ID_valid_i;
			addr[tail] <= ID_addr_i;
			type[tail] <= ID_type_i; 
			bp[tail] <= ID_bp_i;
		end

		if (tail != head && vas[head] == `Valid) begin
			dgb <= `Suc;
			if (type[head] == `TReg || type[head] == `TLoad) begin
				write_en_o <= `Enable;
				write_addr_o <= addr[head];
				write_tag_o <= head;
				write_data_o <= data[head];
				IF_en_o <= `Disable;
			end
			else if (type[head] == `TPc) begin
				IF_en_o <= `Enable;
				IF_bp_o <= bp[head];
				IF_isjalr_o <= `No;
				if (judge[head] == `Suc) begin
					IF_judge_o <= `Suc;
					IF_pc_o <= pc[head];
					IF_oripc_o <= oripc[head];
				end
				else begin
					IF_judge_o <= `Fail;
					IF_pc_o <= pc[head];
					IF_oripc_o <= oripc[head];
				end
				if (judge[head] == bp[head]) begin
					clear <= `Disable;
				end
				else begin
					clear <= `Enable;
				end
				write_en_o <= `Disable;
			end
			else if (type[head] == `TBoth) begin
				write_en_o <= `Enable;
				write_addr_o <= addr[head];
				write_tag_o <= head;
				write_data_o <= data[head];
				if (judge[head] == `Suc) begin
					IF_en_o <= `Enable;
					IF_isjalr_o <= `Yes;
					IF_pc_o <= pc[head];
					IF_oripc_o <= oripc[head];
					clear <= `Enable;
				end
				else begin
					IF_en_o <= `Disable;
					IF_isjalr_o <= `No;
					IF_pc_o <= `Null;
					IF_oripc_o <= `Null;
					clear <= `Disable;
				end
			end
			else if (type[head] == `TMem) begin
			//	write_en_o <= `Disable;
				IF_en_o <= `Disable;
			end
			else begin
				IF_en_o <= `Disable;
			end
			head <= head_nxt;
			LasMove <= `Enable;
		end
		else begin
			dgb <= `Fail;
			write_en_o <= `Disable;
			IF_en_o <= `Disable;
			LasMove <= `Disable;
		//	commit_en_o <= `Disable;
			/*
			write_addr_o <= `Null;
			write_tag_o <= `Null;
			write_data_o <= `Null;*/
		end

		if (cdb_en_i == `Enable) begin
			vas[cdb_tag_i] <= `Valid;
			data[cdb_tag_i] <= cdb_data_i;
			judge[cdb_tag_i] <= `Fail;
		end
		if (cdb_LS_en_i == `Enable) begin
			vas[cdb_LS_tag_i] <= `Valid;
			data[cdb_LS_tag_i] <= cdb_LS_data_i;
			judge[cdb_LS_tag_i] <= `Fail;
		end
		if (cdb_Branch_en_i == `Enable) begin
			vas[cdb_Branch_tag_i] <= `Valid;
			data[cdb_Branch_tag_i] <= cdb_Branch_data_i;
			pc[cdb_Branch_tag_i] <= cdb_Branch_pc_i;
			oripc[cdb_Branch_tag_i] <= cdb_Branch_oripc_i;
			judge[cdb_Branch_tag_i] <= cdb_Branch_judge_i;
		end
		
	end
end

endmodule