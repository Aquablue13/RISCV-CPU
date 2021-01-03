`include "Definitions.v"

module RegFile(
	input wire clk,
	input wire rst,
	input wire rdy,
	input wire clear,

	//ID
	input wire reg1_re_i,
	input wire[`NameBus] reg1_addr_i,
	input wire reg2_re_i,
	input wire[`NameBus] reg2_addr_i,

	input wire rd_we_i,
	input wire[`NameBus] rd_addr_i,
	input wire[`TagBus] rd_tag_i,

	//Dispatch
    output reg reg1_valid_o,
    output reg[`TagBus] reg1_tag_o,
    output reg[`DataBus] reg1_data_o,
    output reg reg2_valid_o,
    output reg[`TagBus] reg2_tag_o,
    output reg[`DataBus] reg2_data_o,

    //ROB
    input wire write_en_i,
    input wire[`NameBus] write_addr_i,
    input wire[`TagBus] write_tag_i,
    input wire[`DataBus] write_data_i

    //gdb
 //   output reg reached
/*
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
    input wire[`DataBus] cdb3_data_i*/
);

reg[`DataBus] regs[`RegBus];
reg[`TagBus] tags[`RegBus];
reg[`RegBus] vas;

//reg aaa, bbb;

always @(posedge clk) begin
	if (rst || clear) begin
		// reset
		vas <= 32'hffffffff;
	//	reached <= `Fail;
	end
	else if (rdy) begin
		if (rd_we_i == `Enable) begin
			tags[rd_addr_i] <= rd_tag_i;
		end
			
		if (write_en_i == `Enable && write_addr_i != `Null) begin
			regs[write_addr_i] <= write_data_i;
		//	vas[write_addr_i] <= `Valid;
		//	reached <= `Suc;
		end
		else begin
		//	reached <= `Fail;
		end
			
		if (rd_we_i == `Enable && write_en_i == `Enable && rd_addr_i == write_addr_i)
			vas[write_addr_i] <= `Invalid;
		else begin
			if (rd_we_i == `Enable)
				vas[rd_addr_i] <= `Invalid;
			if (write_en_i == `Enable && tags[write_addr_i] == write_tag_i) begin
				vas[write_addr_i] <= `Valid;
			//	aaa <= tags[write_addr_i];
			//	bbb <= write_tag_i;
			end
		end
	end
end

always @(*) begin
	if (rst || clear) begin
		// reset
		reg1_valid_o = `Invalid;
		reg1_tag_o = `Null;
		reg1_data_o = `Null;
	end
	else if (reg1_re_i == `Disable) begin
		reg1_valid_o = `Invalid;
		reg1_tag_o = `Null;
		reg1_data_o = `Null;
	end
	else if (reg1_addr_i == `Null) begin
		reg1_valid_o = `Valid;
		reg1_tag_o = `Null;
		reg1_data_o = `Null;
	end/*
	else if (cdb1_en_i == `Enable && tags[reg1_addr_i] == cdb1_tag_i) begin
		reg1_valid_o = `Valid;
		reg1_tag_o = `Null;
		reg1_data_o = cdb1_data_i;
	end
	else if (cdb2_en_i == `Enable && tags[reg1_addr_i] == cdb2_tag_i) begin
		reg1_valid_o = `Valid;
		reg1_tag_o = `Null;
		reg1_data_o = cdb2_data_i;
	end
	else if (cdb3_en_i == `Enable && tags[reg1_addr_i] == cdb3_tag_i) begin
		reg1_valid_o = `Valid;
		reg1_tag_o = `Null;
		reg1_data_o = cdb3_data_i;
	end*/
	else if (write_en_i == `Enable && reg1_addr_i == write_addr_i && tags[reg1_addr_i] == write_tag_i) begin
		reg1_valid_o = `Valid;
		reg1_tag_o = `Null;
		reg1_data_o = write_data_i;
	end
	else begin
		reg1_valid_o = vas[reg1_addr_i];
		reg1_tag_o = tags[reg1_addr_i];
		reg1_data_o = regs[reg1_addr_i];
	end
end

always @(*) begin
	if (rst || clear) begin
		// reset
		reg2_valid_o = `Invalid;
		reg2_tag_o = `Null;
		reg2_data_o = `Null;
	end
	else if (reg2_re_i == `Disable) begin
		reg2_valid_o = `Invalid;
		reg2_tag_o = `Null;
		reg2_data_o = `Null;
	end
	else if (reg2_addr_i == `Null) begin
		reg2_valid_o = `Valid;
		reg2_tag_o = `Null;
		reg2_data_o = `Null;
	end/*
	else if (cdb1_en_i == `Enable && tags[reg2_addr_i] == cdb1_tag_i) begin
		reg2_valid_o = `Valid;
		reg2_tag_o = `Null;
		reg2_data_o = cdb1_data_i;
	end
	else if (cdb2_en_i == `Enable && tags[reg2_addr_i] == cdb2_tag_i) begin
		reg2_valid_o = `Valid;
		reg2_tag_o = `Null;
		reg2_data_o = cdb2_data_i;
	end
	else if (cdb3_en_i == `Enable && tags[reg2_addr_i] == cdb3_tag_i) begin
		reg2_valid_o = `Valid;
		reg2_tag_o = `Null;
		reg2_data_o = cdb3_data_i;
	end*/
	else if (write_en_i == `Enable && reg2_addr_i == write_addr_i && tags[reg2_addr_i] == write_tag_i) begin
		reg2_valid_o = `Valid;
		reg2_tag_o = `Null;
		reg2_data_o = write_data_i;
	end
	else begin
		reg2_valid_o = vas[reg2_addr_i];
		reg2_tag_o = tags[reg2_addr_i];
		reg2_data_o = regs[reg2_addr_i];
	end
end

endmodule
