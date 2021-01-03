`include "Definitions.v"

module ICache(
	input wire clk,
    input wire rst,
    input wire rdy,

    //MemCtrl
    input wire mc_inst_valid_i,
    input wire[`InstBus] mc_inst_i,
    output reg mc_inst_en_o,
    output reg[`AddrBus] mc_inst_addr_o,

    //IF
    input wire inst_en_i,
    input wire[`AddrBus] inst_addr_i,
    output reg inst_valid_o,
    output reg[`InstBus] inst_o
);

reg[`ICacheTagLenBus] tag[`ICacheSizeBus];
reg[`InstBus] inst[`ICacheSizeBus];
reg[`ICacheSizeBus] vas;

always @(posedge clk) begin
	if (rst) begin
		// reset
		vas <= `Null;
	end
	else if (rdy && mc_inst_valid_i == `Valid) begin
		vas[inst_addr_i[`ICacheIndexBus]] <= `Valid;
		tag[inst_addr_i[`ICacheIndexBus]] <= inst_addr_i[`ICacheTagBus];
		inst[inst_addr_i[`ICacheIndexBus]] <= mc_inst_i;
	end
end

always @(*) begin
	if (rst) begin
		// reset
		inst_valid_o = `Disable;
		inst_o = `Null;
		mc_inst_en_o = `Disable;
		mc_inst_addr_o = `Null;
	end
	else if (rdy && inst_en_i == `Enable) begin
		if (vas[inst_addr_i[`ICacheIndexBus]] == `Valid &&
		    tag[inst_addr_i[`ICacheIndexBus]] == inst_addr_i[`ICacheTagBus]) begin
			inst_valid_o = `Enable;
			inst_o = inst[inst_addr_i[`ICacheIndexBus]];
			mc_inst_en_o = `Disable;
			mc_inst_addr_o = `Null;
		end else
		if (mc_inst_valid_i == `Valid) begin
			inst_valid_o = `Enable;
			inst_o = mc_inst_i;
			mc_inst_en_o = `Disable;
			mc_inst_addr_o = `Null;
		end
		else begin
			mc_inst_en_o = `Enable;
			mc_inst_addr_o = inst_addr_i;
			inst_valid_o = `Disable;
			inst_o = `Null;
		end
	end
	else begin
		inst_valid_o = `Disable;
		inst_o = `Null;
		mc_inst_en_o = `Disable;
		mc_inst_addr_o = `Null;
	end
end

endmodule