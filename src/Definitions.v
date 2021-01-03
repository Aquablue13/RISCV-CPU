`define Disable 1'b0
`define Enable 1'b1
`define Invalid 1'b0
`define Valid   1'b1
`define Empty 1'b0
`define Nonempty 1'b1
`define Notfull 1'b0
`define Full 1'b1
`define No 1'b0
`define Yes 1'b1
`define Stall 1'b1

`define Suc 1'b1
`define Fail 1'b0
`define Null 0

`define JALRnum 32'hfffffffe

//MemCtrl
`define StatusBus 1 : 0
`define StageBus 3 : 0
`define LenBus 2 : 0
`define None 4'b0000
`define NoneWait 4'b1000
`define One 4'b0001
`define OneWait 4'b1001
`define Two 4'b0010
`define TwoWait 4'b1010
`define Three 4'b0011
//`define ThreeWait 4'b1011
//`define Four 4'b0100
`define Done 4'b0100
`define Wait 4'b0101
`define Step 4'b0001
`define AddrStep 32'h1
`define Read 1'b0
`define Write 1'b1
`define Nope 2'b00
`define Inst 2'b01
`define DataR 2'b10
`define DataW 2'b11

//ICache
//`define ICacheBus 6 : 0
`define ICacheTagLenBus 6 : 0
`define ICacheSizeBus 511 : 0
`define ICacheTagBus 17 : 11
`define ICacheIndexBus 10 : 2

//IF
`define PcStep 32'h4
`define BPSize 512
`define BPBus `BPSize - 1 : 0
`define BPStatusBus 1 : 0
`define BPIndexBus 10 : 2
`define StronglyNotTaken 2'b00
`define WeaklyNotTaken 2'b01
`define WeaklyTaken 2'b10
`define StronglyTaken 2'b11

//ID
//`define OpTypeBus

//InstQueue
`define IQlen 32    ///////// ?
`define IQlenBus `IQlen - 1 : 0
`define IQPBus 4 : 0
`define QStep 1'b1
`define IQMaxm 5'b11111

//ROB
`define TypeBus 2 : 0
`define TReg 3'b000
`define TPc 3'b001
`define TMem 3'b010
`define TBoth 3'b011
`define TLoad 3'b100
`define ROBlen 16    ///////// ?
`define ROBlenBus `ROBlen - 1 : 0
`define ROBPBus 3 : 0 //!
`define TagBus 3 : 0
`define ROBStep 1'b1
`define ROBMaxm 4'b1111 //!!

//LSB
`define LSBTBus 61 : 0
`define LSBLen 16
`define LSBLenBus `LSBLen - 1 : 0
`define LSBPBus 3 : 0 //!!
`define LSBStep 1'b1

`define RSsize 17

`define AddrBus 31 : 0
`define InstBus 31 : 0
`define DataBus 31 : 0
`define RegBus 31 : 0
`define RamBus 7 : 0
`define NameBus 4 : 0
`define RSBus 0 : `RSsize - 1

//LoadStoreRS
`define LSRSsize 1
`define LSRSBus 0 : `LSRSsize - 1
//`define TimeBus 5 : 0

//`define TimeMax 6'b111111

//Op type
`define OpBus 5 : 0
`define LUI 6'b111111
`define AUIPC 6'b000001
`define JAL 6'b000010
`define JALR 6'b000011
`define BEQ 6'b000100
`define BNE 6'b000101
`define BLT 6'b000110
`define BGE 6'b000111
`define BLTU 6'b001000
`define BGEU 6'b001001
`define LB 6'b001010
`define LH 6'b001011
`define LW 6'b001100
`define LBU 6'b001101
`define LHU 6'b001110
`define SB 6'b001111
`define SH 6'b010000
`define SW 6'b010001
`define ADDI 6'b010010
`define SLLI 6'b010011
`define SLTI 6'b010100
`define SLTIU 6'b010101
`define XORI 6'b010110
`define ORI 6'b010111
`define ANDI 6'b011000
`define SRLI 6'b100011
`define SRAI 6'b100100
`define ADD 6'b011001
`define SUB 6'b011010
`define SLL 6'b011011
`define SLT 6'b011100
`define SLTU 6'b011101
`define XOR 6'b011110
`define OR 6'b011111
`define AND 6'b100000
`define SRL 6'b100001
`define SRA 6'b100010