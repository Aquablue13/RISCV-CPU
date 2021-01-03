`include "Definitions.v"

module LoadStoreBuffer(
	input wire clk,
	input wire rst,
	input wire rdy,
	input wire clear,

	//LoadStoreRS
	output reg LSB_valid_o,
	input wire LSB_en_i,
    input wire[`OpBus] op_i,
    input wire[`DataBus] reg1_i,
    input wire[`DataBus] reg2_i,
    input wire[`TagBus] des_i,
    input wire[`DataBus] imm_i,

    //MemCtrl
    input wire data_valid_i,
    input wire[`DataBus] data_i,
    output reg data_en_o,
    output reg data_wr_o,
    output reg[`AddrBus] data_addr_o,
    output reg[`LenBus] data_len_o,
    output reg[`DataBus] data_o,

    //ROB
    input wire commit_en_i,

    //CDB (-> RS & ROB)
    output reg cdb_en_o,
    output reg[`TagBus] cdb_tag_o,
    output reg[`DataBus] cdb_data_o
);

reg[`LSBTBus] Thead, Ttail, ROBP;
reg[`OpBus] op[`LSBLenBus];
reg[`AddrBus] addr[`LSBLenBus];
reg[`TagBus] rd[`LSBLenBus];
reg[`DataBus] data[`LSBLenBus];

wire[`LSBTBus] Thead_n;
wire[`LSBPBus] head_n, head, tail;
//, wr_head;

//reg[`LSBLenBus] wr_Thead;

assign Thead_n = Thead + data_valid_i;
assign head_n = Thead_n[`LSBPBus];
assign head = Thead[`LSBPBus];
assign tail = Ttail[`LSBPBus];
/*assign wr_head = wr_Thead[`LSBPBus];

always @(*) begin
	if (rdy && issaved_i == `Suc) begin
		wr_Thead = wr_Thead + `Enable;
	end
end*/

always @(*) begin
	LSB_valid_o = ((Ttail - Thead) < (`LSBLen - 1));
end

always @(posedge clk) begin
	if (rst || clear) begin
		// reset
		Thead <= `Null;
	//	wr_Thead <= `Null;
		Ttail <= `Null;
		ROBP <= `Null;
		data_en_o <= `Disable;
		cdb_en_o <= `Disable;
		cdb_tag_o <= `Null;
		cdb_data_o <= `Null;
	end
	else if (rdy) begin
		ROBP <= ROBP + commit_en_i;
		Ttail <= Ttail + LSB_en_i;
		Thead <= Thead + data_valid_i;
		if (LSB_en_i == `Enable) begin
			op[tail] <= op_i;
			addr[tail] <= reg1_i + imm_i;
			data[tail] <= reg2_i;
			rd[tail] <= des_i;
		end

		if (Thead_n < Ttail && ROBP > Thead_n) begin
			case (op[head_n])
				`LB, `LBU: begin
					data_en_o <= `Enable;
					data_wr_o <= `Read;
					data_len_o <= 3'b001;
					data_addr_o <= addr[head_n];
				end
				`LH, `LHU: begin
					data_en_o <= `Enable;
					data_wr_o <= `Read;
					data_len_o <= 3'b010;
					data_addr_o <= addr[head_n];
				end
				`LW: begin
					data_en_o <= `Enable;
					data_wr_o <= `Read;
					data_len_o <= 3'b100;
					data_addr_o <= addr[head_n];
				end
				`SB: begin
					data_en_o <= `Enable;
					data_wr_o <= `Write;
					data_len_o <= 3'b001;
					data_o <= {24'b0, data[head_n][7 : 0]};
					data_addr_o <= addr[head_n];
				end
				`SH: begin
					data_en_o <= `Enable;
					data_wr_o <= `Write;
					data_len_o <= 3'b010;
					data_o <= {16'b0, data[head_n][15 : 0]};
					data_addr_o <= addr[head_n];
				end
				`SW: begin
					data_en_o <= `Enable;
					data_wr_o <= `Write;
					data_len_o <= 3'b100;
					data_o <= data[head_n][31 : 0];
					data_addr_o <= addr[head_n];
				end
				default: begin
					data_en_o <= `Disable;
				end
			endcase
		end
		else begin
			data_en_o <= `Disable;
		end

		if (data_valid_i == `Valid) begin
			case (op[head])
				`LB: begin
					cdb_en_o <= `Enable;
					cdb_tag_o <= rd[head];
					cdb_data_o <= {{24{data_i[7]}}, data_i[7 : 0]};
				end
				`LH: begin
					cdb_en_o <= `Enable;
					cdb_tag_o <= rd[head];
					cdb_data_o <= {{16{data_i[15]}}, data_i[15 : 0]};
				end
				`LW: begin
					cdb_en_o <= `Enable;
					cdb_tag_o <= rd[head];
					cdb_data_o <= data_i;
				end
				`LBU: begin
					cdb_en_o <= `Enable;
					cdb_tag_o <= rd[head];
					cdb_data_o <= {24'b0, data_i[7 : 0]};
				end
				`LHU: begin
					cdb_en_o <= `Enable;
					cdb_tag_o <= rd[head];
					cdb_data_o <= {16'b0, data_i[15 : 0]};
				end
				`SB, `SH, `SW: begin
					cdb_en_o <= `Enable;
					cdb_tag_o <= rd[head];
				end
				default:
					cdb_en_o <= `Disable;
			endcase
		end
		else begin
			cdb_en_o <= `Disable;
		end
	end
end

endmodule