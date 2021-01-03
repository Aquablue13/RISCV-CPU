`include "Definitions.v"

module InstQueue(
	input wire clk,
	input wire rst,
    input wire rdy,
    input wire clear,

    //IF
    input wire we_i,
    input wire[`InstBus] inst_i,
    input wire[`AddrBus] pc_i,
    input wire bp_i,
    output reg full_o,

    //ID
    input wire re_i,
    output reg[`InstBus] inst_o,
    output reg[`AddrBus] pc_o,
    output reg bp_o,
    output reg empty_o
);

reg[`IQPBus] head, tail;
reg[`InstBus] queue_inst[`IQlenBus];
reg[`AddrBus] queue_pc[`IQlenBus];
reg queue_bp[`IQlenBus];

wire[`IQPBus] head_n, tail_n, tail_nxt, tail_nnxt;

assign head_n = (re_i == `Enable) ? ((head == `IQMaxm) ? `Null : head + re_i) : head;
assign tail_n = (we_i == `Enable) ? ((tail == `IQMaxm) ? `Null : tail + we_i) : tail;
assign tail_nxt = (tail_n == `IQMaxm) ? `Null : tail_n + `QStep;
assign tail_nnxt = (tail_nxt == `IQMaxm) ? `Null : tail_nxt + `QStep;
/*
always @(*) begin
	if (rdy) begin
		if (head_n == tail_n) begin
			empty_o <= `Empty;
		end
		else begin
			empty_o <= `Nonempty;
		end
	//	empty_o = (head_n == tail_n) ? `Empty : `Nonempty;
	//	full_o = (tail_nxt == head_n) ? `Full : `Notfull;
	end 
end*/

always @(posedge clk) begin
	if (rst || clear) begin
		// reset
		head <= `Null;
		tail <= `Null;
		empty_o <= `Empty;
		full_o <= `Notfull;
	end
	else if (rdy) begin
		empty_o <= (head_n == tail_n) ? `Empty : `Nonempty;
		full_o <= (tail_nnxt == head_n || tail_nxt == head_n) ? `Full : `Notfull;

		if (we_i == `Enable) begin
			queue_inst[tail] <= inst_i;
			queue_pc[tail] <= pc_i;
			queue_bp[tail] <= bp_i;
		end
		
		if (head_n == tail && we_i == `Enable) begin
			inst_o <= inst_i;
			pc_o <= pc_i;
			bp_o <= bp_i;
		end
		else begin
			inst_o <= queue_inst[head_n];
			pc_o <= queue_pc[head_n];
			bp_o <= queue_bp[head_n];
		end
		head <= head_n;
		tail <= tail_n;
	end
end

endmodule