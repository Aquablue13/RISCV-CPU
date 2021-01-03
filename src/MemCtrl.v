`include "Definitions.v"

module MemCtrl(
	input wire clk,
    input wire rst,
    input wire rdy,
    input wire clear,
    
    //uart buffer
    input wire io_buffer_full,
    
    //ICache
    input wire inst_en_i,
    input wire[`AddrBus] inst_addr_i,
    output reg inst_valid_o,
    output reg[`InstBus] inst_o,

    //LoadStoreBuffer
    input wire data_en_i,
    input wire data_wr_i,
    input wire[`AddrBus] data_addr_i,
    input wire[`LenBus] data_len_i,
    input wire[`DataBus] data_i,
    output reg data_valid_o,
    output reg[`DataBus] data_o,

    //ram
    input wire[`RamBus] mem_i,
    output reg mem_wr_o,
    output reg[`AddrBus] mem_addr_o,
    output reg[`RamBus] mem_o
);

reg[`StatusBus] status;
reg[`StageBus] stage;
reg[`DataBus] data;

always @(*) begin
	if (rst || clear) begin
		// reset
		mem_wr_o = `Null;
		mem_addr_o = `Null;
		mem_o = `Null;
	end
	else if (rdy) begin
		case (status)
			`Nope: begin
				mem_wr_o = `Null;
				mem_addr_o = `Null;
				mem_o = `Null;
			end
			`Inst: begin
				case (stage)
					`Done: begin
						mem_wr_o = `Null;
						mem_addr_o = `Null;
						mem_o = `Null;
					end
					default: begin
						mem_wr_o = `Read;
						mem_addr_o = inst_addr_i + stage * `AddrStep;
						mem_o = `Null;
					end
				endcase
			end
			`DataR: begin
				case (stage)
					`Done, `Wait: begin
						mem_wr_o = `Null;
						mem_addr_o = `Null;
						mem_o = `Null;
					end
					default: begin
						if (stage == data_len_i) begin
							mem_wr_o = `Null;
							mem_addr_o = `Null;
							mem_o = `Null;
						end
						else begin
							mem_wr_o = `Read;
							mem_addr_o = data_addr_i + stage * `AddrStep;
							mem_o = `Null;
						end
					end
				endcase
			end
			`DataW: begin
				if (io_buffer_full == `Full) begin
					//Stall
					mem_wr_o = `Null;
					mem_addr_o = `Null;
					mem_o = `Null;
				end
				else
				case (stage)
					`None: begin
						mem_wr_o = `Write;
						mem_addr_o = data_addr_i;
						mem_o = data_i[7 : 0];
					end
					`One: begin
						if (stage == data_len_i) begin
							mem_wr_o = `Null;
							mem_addr_o = `Null;
							mem_o = `Null;
						end
						else begin
							mem_wr_o = `Write;
							mem_addr_o = data_addr_i + stage * `AddrStep;
							mem_o = data_i[15 : 8];
						end
					end
					`Two: begin
						if (stage == data_len_i) begin
							mem_wr_o = `Null;
							mem_addr_o = `Null;
							mem_o = `Null;
						end
						else begin
							mem_wr_o = `Write;
							mem_addr_o = data_addr_i + stage * `AddrStep;
							mem_o = data_i[23 : 16];
						end
					end
					`Three: begin
						mem_wr_o = `Write;
						mem_addr_o = data_addr_i + stage * `AddrStep;
						mem_o = data_i[31 : 24];
					end
					
				//	`Done, `Wait, `NoneWait, `OneWait, `TwoWait: begin
					default: begin
						mem_wr_o = `Null;
						mem_addr_o = `Null;
						mem_o = `Null;
					end
				endcase
			end

			default: begin
				mem_wr_o = `Null;
				mem_addr_o = `Null;
				mem_o = `Null;
			end
		endcase
	end
	else begin
		mem_wr_o = `Null;
		mem_addr_o = `Null;
		mem_o = `Null;
	end
end

always @(posedge clk or negedge rst) begin
	if (rst || clear) begin
		// reset
		status <= `Nope;
		stage <= `None;
		inst_valid_o <= `Invalid;
		data_valid_o <= `Invalid;
	end
	else if (rdy) begin
		case (status)
			`Nope: begin
				if (data_en_i == `Enable) begin
					status <= (data_wr_i == `Read) ? `DataR : `DataW;
					stage <= `None;
				end
				else if (inst_en_i == `Enable) begin
					status <= `Inst;
					stage <= `None;
				end
				else begin
					status <= `Nope;
					stage <= `None;
				end

				inst_valid_o <= `Invalid;
				data_valid_o <= `Invalid;
			end
			`Inst: begin
				case (stage)
					`None: begin
						stage <= stage + `Step;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`One: begin
						data[7 : 0] <= mem_i;
						stage <= stage + `Step;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`Two: begin
						data[15 : 8] <= mem_i;
						stage <= stage + `Step;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`Three: begin
						data[23 : 16] <= mem_i;
						stage <= stage + `Step;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`Done: begin
						data[31 : 24] <= mem_i;
						inst_valid_o <= `Valid;
						inst_o <= {mem_i, data[23 : 0]};
						status <= `Nope;
						stage <= `None;
						data_valid_o <= `Invalid;
					end
				endcase
			end
			`DataR: begin
				case (stage)
					`None: begin
						stage <= stage + `Step;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`One: begin
						data[7 : 0] <= mem_i;
						if (stage == data_len_i) begin
							data_valid_o <= `Valid;
							data_o <= {{24'b0}, mem_i};
							stage <= `Wait;
							inst_valid_o <= `Invalid;
						end
						else begin
							stage <= stage + `Step;
							inst_valid_o <= `Invalid;
							data_valid_o <= `Invalid;
						end
					end
					`Two: begin
						data[15 : 8] <= mem_i;
						if (stage == data_len_i) begin
							data_valid_o <= `Valid;
							data_o <= {{16'b0}, mem_i, data[7 : 0]};
							stage <= `Wait;
							inst_valid_o <= `Invalid;
						end
						else begin
							stage <= stage + `Step;
							inst_valid_o <= `Invalid;
							data_valid_o <= `Invalid;
						end
					end
					`Three: begin
						data[23 : 16] <= mem_i;
						stage <= stage + `Step;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`Done: begin
						data[31 : 24] <= mem_i;
						data_valid_o <= `Valid;
						data_o <= {mem_i, data[23 : 0]};
						stage <= `Wait;
						inst_valid_o <= `Invalid;
					end
					`Wait: begin
						data_valid_o <= `Invalid;
						data_o <= `Null;
						status <= `Nope;
						inst_valid_o <= `Invalid;
					end
				endcase
			end
			`DataW: begin
				if (io_buffer_full == `Full) begin
					//stall
					inst_valid_o <= `Invalid;
					data_valid_o <= `Invalid;
				end
				else
				case (stage)
					`None: begin
						if (stage + `AddrStep == data_len_i) begin
							data_valid_o <= `Valid;
							data_o <= `Null;
							stage <= `Done;
							inst_valid_o <= `Invalid;		
						end
						else begin
							stage <= `NoneWait;
							inst_valid_o <= `Invalid;
							data_valid_o <= `Invalid;
						end
					end
					`NoneWait: begin
						stage <= `One;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`One: begin
						if (stage + `AddrStep == data_len_i) begin
							data_valid_o <= `Valid;
							data_o <= `Null;
							stage <= `Done;
							inst_valid_o <= `Invalid;		
						end
						else begin
							stage <= `OneWait;
							inst_valid_o <= `Invalid;
							data_valid_o <= `Invalid;
						end
					end
					`OneWait: begin
						stage <= `Two;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`Two: begin
						stage <= `TwoWait;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`TwoWait: begin
						stage <= `Three;
						inst_valid_o <= `Invalid;
						data_valid_o <= `Invalid;
					end
					`Three: begin
						data_valid_o <= `Valid;
						data_o <= `Null;
						stage <= `Done;
						inst_valid_o <= `Invalid;	
					end
					`Done: begin
						data_valid_o <= `Invalid;
						data_o <= `Null;
						status <= `Nope;
						inst_valid_o <= `Invalid;
					end
				endcase
			end
		endcase
	end
	else begin
		inst_valid_o <= `Invalid;
		data_valid_o <= `Invalid;
	end
end

endmodule