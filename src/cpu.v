// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "Definitions.v"

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
  	input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	
  	input  wire                 io_buffer_full, // 1 if uart buffer is full

  	output wire [31:0]		   	  dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire clear;

//MemCtrl <-> ICache
wire IC_en, IC_valid;
wire[`AddrBus] IC_addr;
wire[`InstBus] IC_inst;

//MemCtrl <-> LSB
wire data_issaved, LSB_en_mc, LSB_wr, LSB_valid_mc;
wire[`AddrBus] LSB_addr;
wire[`LenBus] LSB_len;
wire[`DataBus] LSB_data, LSB_result;

//MemCtrl <-> ram

//ICache <-> IF
wire IF_en, IF_valid;
wire[`AddrBus] IF_addr;
wire[`InstBus] IF_inst;

//IF <-> InstQueue
wire iq_full, iq_we, iq_bp_i;
wire[`InstBus] iq_inst_i;
wire[`AddrBus] iq_pc_i;

//IF <-> ROB
wire commit_pc_en;
wire commit_isjalr;
wire commit_pc_judge;
wire commit_pc_bp;
wire[`AddrBus] commit_pc, commit_oripc;

//InstQueue <-> ID
wire iq_empty, iq_re, iq_bp_o;
wire[`InstBus] iq_inst_o;
wire[`AddrBus] iq_pc_o;

//ID <-> ROB
wire ROB_valid_t;
wire[`TagBus] ROB_tag;
wire ROB_we, ROB_valid;
wire[`NameBus] ROB_addr;
wire[`TypeBus] ROB_type;
wire ROB_bp;

//ID <-> ALURS & LoadStoreRS & BranchRS
wire ALURS_valid, LS_RS_valid, Branch_RS_valid;

//ID <-> RegFile
wire id_reg1_re, id_reg2_re, id_rd_we;
wire[`NameBus] id_reg1_addr, id_reg2_addr, id_rd_addr;
wire[`TagBus] id_rd_tag; 

//ID <-> Dispatch
wire disp_en;
wire[`OpBus] id_op;
wire[`DataBus] id_imm;
wire[`AddrBus] id_pc;
wire[`TagBus] id_des;
wire id_bp;
//wire[`TimeBus] id_time;

//RegFile <-> Dispatch
wire disp_reg1_valid, disp_reg2_valid;
wire[`TagBus] disp_reg1_tag, disp_reg2_tag;
wire[`DataBus] disp_reg1_data, disp_reg2_data;

//RegFile <-> ROB
wire write_en;
wire[`NameBus] write_addr;
wire[`TagBus] write_tag;
wire[`DataBus] write_data;

//Dispatch <-> ROB
wire ROB_reg1_re, ROB_reg2_re;
wire ROB_reg1_valid, ROB_reg2_valid;
wire[`TagBus] ROB_reg1_tag, ROB_reg2_tag;
wire[`DataBus] ROB_reg1_data, ROB_reg2_data;

//Dispatch <-> RS
wire RS_we;
wire[`OpBus] RS_op;
wire[`DataBus] RS_imm;
wire[`AddrBus] RS_pc;
wire[`TagBus] RS_des;
wire RS_reg1_valid, RS_reg2_valid;
wire[`TagBus] RS_reg1_tag, RS_reg2_tag;
wire[`DataBus] RS_reg1_data, RS_reg2_data;

//Dispatch <-> LoadStoreRS
wire LS_RS_we;
wire[`OpBus] LS_RS_op;
wire[`DataBus] LS_RS_imm;
wire[`TagBus] LS_RS_des;
//wire[`TimeBus] LS_RS_time;
wire LS_RS_reg1_valid, LS_RS_reg2_valid;
wire[`TagBus] LS_RS_reg1_tag, LS_RS_reg2_tag;
wire[`DataBus] LS_RS_reg1_data, LS_RS_reg2_data;

//Dispatch <-> BranchRS
wire Branch_RS_we;
wire[`OpBus] Branch_RS_op;
wire[`DataBus] Branch_RS_imm;
wire[`AddrBus] Branch_RS_pc;
wire[`TagBus] Branch_RS_des;
wire Branch_RS_bp;
wire Branch_RS_reg1_valid, Branch_RS_reg2_valid;
wire[`TagBus] Branch_RS_reg1_tag, Branch_RS_reg2_tag;
wire[`DataBus] Branch_RS_reg1_data, Branch_RS_reg2_data;

//(ALURS & LoadStoreRS & BranchRS) & ROB <-> CDB(ALU & LSB & Branch)
wire cdbALU_en;
wire[`TagBus] cdbALU_tag;
wire[`DataBus] cdbALU_data;
wire cdbLSB_en;
wire[`TagBus] cdbLSB_tag;
wire[`DataBus] cdbLSB_data;
wire cdbBranch_en;
wire[`TagBus] cdbBranch_tag;
wire[`DataBus] cdbBranch_data;
wire[`AddrBus] cdbBranch_pc;
wire[`AddrBus] cdbBranch_oripc;
wire cdbBranch_judge;

//ALURS <-> ALU
wire ALU_en;
wire[`OpBus] ALU_op;
wire[`DataBus] ALU_reg1, ALU_reg2, ALU_imm;
wire[`TagBus] ALU_des;
wire[`AddrBus] ALU_pc;

//LoadStoreRS <-> LSB
wire LSB_en;
wire[`OpBus] LSB_op;
wire[`DataBus] LSB_reg1, LSB_reg2, LSB_imm;
wire[`TagBus] LSB_des;
wire[`AddrBus] LSB_pc;

wire LSB_valid;

//BranchRS <-> Branch
wire Branch_en;
wire[`OpBus] Branch_op;
wire[`DataBus] Branch_reg1, Branch_reg2, Branch_imm;
wire[`TagBus] Branch_des;
wire[`AddrBus] Branch_pc;
wire Branch_bp;

//LoadStoreBuffer <-> ROB
wire LS_commit_en;

  MemCtrl MemCtrl(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    .io_buffer_full(io_buffer_full),

    //ICache
    .inst_en_i(IC_en),
    .inst_addr_i(IC_addr),
    .inst_valid_o(IC_valid),
    .inst_o(IC_inst),

    //LoadStoreBuffer
    .data_en_i(LSB_en_mc),
    .data_wr_i(LSB_wr),
    .data_addr_i(LSB_addr),
    .data_len_i(LSB_len),
    .data_i(LSB_data),
    .data_valid_o(LSB_valid_mc),
    .data_o(LSB_result),

    //ram
    .mem_i(mem_din),
    .mem_wr_o(mem_wr),
    .mem_addr_o(mem_a),
    .mem_o(mem_dout)
  );

  ICache ICache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    //MemCtrl
    .mc_inst_valid_i(IC_valid),
    .mc_inst_i(IC_inst),
    .mc_inst_en_o(IC_en),
    .mc_inst_addr_o(IC_addr),

    //IF
    .inst_en_i(IF_en),
    .inst_addr_i(IF_addr),
    .inst_valid_o(IF_valid),
    .inst_o(IF_inst)
  );

  IF IF(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    //ICache
    .inst_valid_i(IF_valid),
    .inst_i(IF_inst),
    .inst_en_o(IF_en),
    .inst_addr_o(IF_addr),

    //InstQueue
    .iq_full_i(iq_full),
    .iq_en_o(iq_we),
    .iq_inst_o(iq_inst_i),
    .iq_pc_o(iq_pc_i),
    .iq_bp_o(iq_bp_i),

    //ROB
    .commit_en_i(commit_pc_en),
    .commit_isjalr_i(commit_isjalr),
    .commit_judge_i(commit_pc_judge),
    .commit_bp_i(commit_pc_bp),
    .commit_pc_i(commit_pc),
    .commit_oripc_i(commit_oripc)

    //dbg
//  .dbg_o(dbgreg_dout)
  );

  InstQueue InstQueue(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //IF
    .we_i(iq_we),
    .inst_i(iq_inst_i),
    .pc_i(iq_pc_i),
    .bp_i(iq_bp_i),
    .full_o(iq_full),

    //ID
    .re_i(iq_re),
    .inst_o(iq_inst_o),
    .pc_o(iq_pc_o),
    .bp_o(iq_bp_o),
    .empty_o(iq_empty)
  );

  ID ID(
    //stall
    .iq_empty_i(iq_empty),
    .ROB_valid_i(ROB_valid_t),
    .RS_valid_i(ALURS_valid),
    .LS_RS_valid_i(LS_RS_valid),
    .Branch_RS_valid_i(Branch_RS_valid),

    //InstQueue
    .inst_i(iq_inst_o),
    .pc_i(iq_pc_o),
    .iq_re_o(iq_re),
    .bp_i(iq_bp_o),

    //RegFile
    .reg1_re_o(id_reg1_re),
    .reg1_o(id_reg1_addr),
    .reg2_re_o(id_reg2_re),
    .reg2_o(id_reg2_addr),
    .rd_we_o(id_rd_we),
    .rd_addr_o(id_rd_addr),
    .rd_tag_o(id_rd_tag),

    //Dispatch
    .disp_en_o(disp_en),
    .op_o(id_op),
    .imm_o(id_imm),
    .pc_o(id_pc),
    .des_o(id_des),
    .bp_o(id_bp),
//    .time_o(id_time),

    //ROB
    .ROB_tag_i(ROB_tag),
    .ROB_we_o(ROB_we),
    .ROB_valid_o(ROB_valid),
    .ROB_addr_o(ROB_addr),
    .ROB_type_o(ROB_type),
    .ROB_bp_o(ROB_bp)
  );

  RegFile RegFile(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //ID
    .reg1_re_i(id_reg1_re),
    .reg1_addr_i(id_reg1_addr),
    .reg2_re_i(id_reg2_re),
    .reg2_addr_i(id_reg2_addr),
    .rd_we_i(id_rd_we),
    .rd_addr_i(id_rd_addr),
    .rd_tag_i(id_rd_tag),

    //Dispatch
    .reg1_valid_o(disp_reg1_valid),
    .reg1_tag_o(disp_reg1_tag),
    .reg1_data_o(disp_reg1_data),
    .reg2_valid_o(disp_reg2_valid),
    .reg2_tag_o(disp_reg2_tag),
    .reg2_data_o(disp_reg2_data),

    //ROB
    .write_en_i(write_en),
    .write_addr_i(write_addr),
    .write_tag_i(write_tag),
    .write_data_i(write_data)
  );

  Dispatch Dispatch(
    //ID
    .disp_en_i(disp_en),
    .op_i(id_op),
    .imm_i(id_imm),
    .pc_i(id_pc),
    .des_i(id_des),
    .bp_i(id_bp),
//    .time_i(id_time),

    //RegFile
    .reg1_valid_i(disp_reg1_valid),
    .reg1_tag_i(disp_reg1_tag),
    .reg1_data_i(disp_reg1_data),
    .reg2_valid_i(disp_reg2_valid),
    .reg2_tag_i(disp_reg2_tag),
    .reg2_data_i(disp_reg2_data),

    //ROB
    .ROB_reg1_re_o(ROB_reg1_re),
    .ROB_reg1_tag_o(ROB_reg1_tag),
    .ROB_reg1_valid_i(ROB_reg1_valid),
    .ROB_reg1_data_i(ROB_reg1_data),
    .ROB_reg2_re_o(ROB_reg2_re),
    .ROB_reg2_tag_o(ROB_reg2_tag),
    .ROB_reg2_valid_i(ROB_reg2_valid),
    .ROB_reg2_data_i(ROB_reg2_data),

    //RS
    .RS_we_o(RS_we),
    .op_o(RS_op),
    .imm_o(RS_imm),
    .pc_o(RS_pc),
    .des_o(RS_des),
    .reg1_valid_o(RS_reg1_valid),
    .reg1_tag_o(RS_reg1_tag),
    .reg1_data_o(RS_reg1_data),
    .reg2_valid_o(RS_reg2_valid),
    .reg2_tag_o(RS_reg2_tag),
    .reg2_data_o(RS_reg2_data),

    //LoadStoreRS
    .LS_RS_we_o(LS_RS_we),
    .LS_op_o(LS_RS_op),
    .LS_imm_o(LS_RS_imm),
    .LS_des_o(LS_RS_des),
//    .LS_time_o(LS_RS_time),
    .LS_reg1_valid_o(LS_RS_reg1_valid),
    .LS_reg1_tag_o(LS_RS_reg1_tag),
    .LS_reg1_data_o(LS_RS_reg1_data),
    .LS_reg2_valid_o(LS_RS_reg2_valid),
    .LS_reg2_tag_o(LS_RS_reg2_tag),
    .LS_reg2_data_o(LS_RS_reg2_data),

    //BranchRS
    .Branch_RS_we_o(Branch_RS_we),
    .Branch_op_o(Branch_RS_op),
    .Branch_imm_o(Branch_RS_imm),
    .Branch_pc_o(Branch_RS_pc),
    .Branch_des_o(Branch_RS_des),
    .Branch_bp_o(Branch_RS_bp),
    .Branch_reg1_valid_o(Branch_RS_reg1_valid),
    .Branch_reg1_tag_o(Branch_RS_reg1_tag),
    .Branch_reg1_data_o(Branch_RS_reg1_data),
    .Branch_reg2_valid_o(Branch_RS_reg2_valid),
    .Branch_reg2_tag_o(Branch_RS_reg2_tag),
    .Branch_reg2_data_o(Branch_RS_reg2_data)
  );

  /***
    RS
  ***/

  ALURS ALURS(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //Dispatch
    .we_i(RS_we),
    .op_i(RS_op),
    .imm_i(RS_imm),
    .pc_i(RS_pc),
    .des_i(RS_des),
    .reg1_valid_i(RS_reg1_valid),
    .reg1_tag_i(RS_reg1_tag),
    .reg1_data_i(RS_reg1_data),
    .reg2_valid_i(RS_reg2_valid),
    .reg2_tag_i(RS_reg2_tag),
    .reg2_data_i(RS_reg2_data),

    //ID
    .RS_valid_o(ALURS_valid),

    //CDB
    //ALU
    .cdb1_en_i(cdbALU_en),
    .cdb1_tag_i(cdbALU_tag),
    .cdb1_data_i(cdbALU_data),
    //LSB
    .cdb2_en_i(cdbLSB_en),
    .cdb2_tag_i(cdbLSB_tag),
    .cdb2_data_i(cdbLSB_data),
    //Branch
    .cdb3_en_i(cdbBranch_en),
    .cdb3_tag_i(cdbBranch_tag),
    .cdb3_data_i(cdbBranch_data),
    //ROB
    .write_en_i(write_en),
    .write_tag_i(write_tag),
    .write_data_i(write_data),

    //ALU
    .ALU_en_o(ALU_en),
    .op_o(ALU_op),
    .reg1_o(ALU_reg1),
    .reg2_o(ALU_reg2),
    .des_o(ALU_des),
    .imm_o(ALU_imm),
    .pc_o(ALU_pc)
  );

  LoadStoreRS LoadStoreRS(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //Dispatch
    .we_i(LS_RS_we),
    .op_i(LS_RS_op),
    .imm_i(LS_RS_imm),
    .des_i(LS_RS_des),
//    .time_i(LS_RS_time),
    .reg1_valid_i(LS_RS_reg1_valid),
    .reg1_tag_i(LS_RS_reg1_tag),
    .reg1_data_i(LS_RS_reg1_data),
    .reg2_valid_i(LS_RS_reg2_valid),
    .reg2_tag_i(LS_RS_reg2_tag),
    .reg2_data_i(LS_RS_reg2_data),

    //ID
    .RS_valid_o(LS_RS_valid),

    //CDB
    //ALU
    .cdb1_en_i(cdbALU_en),
    .cdb1_tag_i(cdbALU_tag),
    .cdb1_data_i(cdbALU_data),
    //LSB
    .cdb2_en_i(cdbLSB_en),
    .cdb2_tag_i(cdbLSB_tag),
    .cdb2_data_i(cdbLSB_data),
    //Branch
    .cdb3_en_i(cdbBranch_en),
    .cdb3_tag_i(cdbBranch_tag),
    .cdb3_data_i(cdbBranch_data),
    //ROB
    .write_en_i(write_en),
    .write_tag_i(write_tag),
    .write_data_i(write_data),

    //LSB
    .LSB_valid_i(LSB_valid),
    .LSB_en_o(LSB_en),
    .op_o(LSB_op),
    .reg1_o(LSB_reg1),
    .reg2_o(LSB_reg2),
    .des_o(LSB_des),
    .imm_o(LSB_imm)
  );

  BranchRS BranchRS(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //Dispatch
    .we_i(Branch_RS_we),
    .op_i(Branch_RS_op),
    .imm_i(Branch_RS_imm),
    .pc_i(Branch_RS_pc),
    .des_i(Branch_RS_des),
    .bp_i(Branch_RS_bp),
    .reg1_valid_i(Branch_RS_reg1_valid),
    .reg1_tag_i(Branch_RS_reg1_tag),
    .reg1_data_i(Branch_RS_reg1_data),
    .reg2_valid_i(Branch_RS_reg2_valid),
    .reg2_tag_i(Branch_RS_reg2_tag),
    .reg2_data_i(Branch_RS_reg2_data),

    //ID
    .RS_valid_o(Branch_RS_valid),

    //CDB
    //ALU
    .cdb1_en_i(cdbALU_en),
    .cdb1_tag_i(cdbALU_tag),
    .cdb1_data_i(cdbALU_data),
    //LSB
    .cdb2_en_i(cdbLSB_en),
    .cdb2_tag_i(cdbLSB_tag),
    .cdb2_data_i(cdbLSB_data),
    //Branch
    .cdb3_en_i(cdbBranch_en),
    .cdb3_tag_i(cdbBranch_tag),
    .cdb3_data_i(cdbBranch_data),
    //ROB
    .write_en_i(write_en),
    .write_tag_i(write_tag),
    .write_data_i(write_data),

    //Branch
    .Branch_en_o(Branch_en),
    .op_o(Branch_op),
    .reg1_o(Branch_reg1),
    .reg2_o(Branch_reg2),
    .des_o(Branch_des),
    .imm_o(Branch_imm),
    .pc_o(Branch_pc),
    .bp_o(Branch_bp)
  );

  ALU ALU(
    //ALURS
    .ALU_en_i(ALU_en),
    .op_i(ALU_op),
    .reg1_i(ALU_reg1),
    .reg2_i(ALU_reg2),
    .des_i(ALU_des),
    .imm_i(ALU_imm),
    .pc_i(ALU_pc),

    //CDB (-> RS & ROB)
    .cdb_en_o(cdbALU_en),
    .cdb_tag_o(cdbALU_tag),
    .cdb_data_o(cdbALU_data)
  );

  LoadStoreBuffer LoadStoreBuffer(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //LoadStoreRS
    .LSB_valid_o(LSB_valid),
    .LSB_en_i(LSB_en),
    .op_i(LSB_op),
    .reg1_i(LSB_reg1),
    .reg2_i(LSB_reg2),
    .des_i(LSB_des),
    .imm_i(LSB_imm),

    //MemCtrl
    .data_valid_i(LSB_valid_mc),
    .data_i(LSB_result),
    .data_en_o(LSB_en_mc),
    .data_wr_o(LSB_wr),
    .data_addr_o(LSB_addr),
    .data_len_o(LSB_len),
    .data_o(LSB_data),

    //ROB
    .commit_en_i(LS_commit_en),

    //CDB (-> RS & ROB)
    .cdb_en_o(cdbLSB_en),
    .cdb_tag_o(cdbLSB_tag),
    .cdb_data_o(cdbLSB_data)
  );

  Branch Branch(

    //BranchRS
    .Branch_en_i(Branch_en),
    .op_i(Branch_op),
    .reg1_i(Branch_reg1),
    .reg2_i(Branch_reg2),
    .des_i(Branch_des),
    .imm_i(Branch_imm),
    .pc_i(Branch_pc),
    .bp_i(Branch_bp),

    //CDB (-> RS & ROB)
    .cdb_en_o(cdbBranch_en),
    .cdb_tag_o(cdbBranch_tag),
    .cdb_judge_o(cdbBranch_judge),
    .cdb_pc_o(cdbBranch_pc),
    .cdb_oripc_o(cdbBranch_oripc),
    .cdb_data_o(cdbBranch_data)
  );


  /***
    ROB
  ***/

  ROB ROB(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clear(clear),

    //ID
    .ROB_valid_o(ROB_valid_t),

    .ID_tag_o(ROB_tag),
    .we_i(ROB_we),
    .ID_valid_i(ROB_valid),
    .ID_addr_i(ROB_addr),
    .ID_type_i(ROB_type),
    .ID_bp_i(ROB_bp),

    //LoadStoreBuffer
    .commit_en_o(LS_commit_en),

    //Dispatch
    .reg1_re_i(ROB_reg1_re),
    .reg1_tag_i(ROB_reg1_tag),
    .reg1_valid_o(ROB_reg1_valid),
    .reg1_data_o(ROB_reg1_data),
    .reg2_re_i(ROB_reg2_re),
    .reg2_tag_i(ROB_reg2_tag),
    .reg2_valid_o(ROB_reg2_valid),
    .reg2_data_o(ROB_reg2_data),

    //Regfile
    .write_en_o(write_en),
    .write_addr_o(write_addr),
    .write_tag_o(write_tag),
    .write_data_o(write_data),

    //CDB
    .cdb_en_i(cdbALU_en),
    .cdb_tag_i(cdbALU_tag),
    .cdb_data_i(cdbALU_data),

    .cdb_LS_en_i(cdbLSB_en),
    .cdb_LS_tag_i(cdbLSB_tag),
    .cdb_LS_data_i(cdbLSB_data),

    .cdb_Branch_en_i(cdbBranch_en),
    .cdb_Branch_tag_i(cdbBranch_tag),
    .cdb_Branch_judge_i(cdbBranch_judge),
    .cdb_Branch_pc_i(cdbBranch_pc),
    .cdb_Branch_oripc_i(cdbBranch_oripc),
    .cdb_Branch_data_i(cdbBranch_data),

    //IF
    .IF_en_o(commit_pc_en),
    .IF_isjalr_o(commit_isjalr),
    .IF_judge_o(commit_pc_judge),
    .IF_bp_o(commit_pc_bp),
    .IF_pc_o(commit_pc),
    .IF_oripc_o(commit_oripc)
);

endmodule