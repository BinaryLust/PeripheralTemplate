

// register map
// address //   bits    //  registers       // type   //  access type  // value meaning
//       0      [31:0]      counter            data       read/write
//       1      [0]         count enable       config     read/write    (1 for enable, 0 for disable)
//       1      [1]         count direction    config     read/write    (1 for up,     0 for down)
//       1      [2]         count int enable   config     read/write    (1 for enable, 0 for disable)
//       2      [0]         count < 1000       status     read only     (1 for yes,    0 for no)


// interface definition
interface avalonIo;
    logic          clk;
    logic          reset;
    logic          read;
    logic          write;
    logic  [1:0]   address;
    logic  [31:0]  dataIn;
    logic          readValid;
    logic  [31:0]  dataOut;
    logic          irq;


    modport in (
        input   clk,
        input   reset,
        input   read,
        input   write,
        input   address,
        input   dataIn,
        output  readValid,
        output  dataOut,
        output  irq
    );

endinterface


module avalonCore(
    avalonIo.in io
    );


    // internal logic signals
    coreIo cIo();
    logic  [1:0]  address; // registered address from the previous cycle


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            address      <= 2'b0;
            io.readValid <= 1'b0;
        end else begin
            address      <= io.address;
            io.readValid <= io.read;
        end
    end


    // combinational logic block
    always_comb begin
        // default logic values
        io.dataOut          = 32'd0;
        cIo.counterRe       = 1'b0;
        cIo.counterWe       = 1'b0;
        cIo.counterConfigRe = 1'b0;
        cIo.counterConfigWe = 1'b0;
        cIo.counterStatusRe = 1'b0;


        // device register read/write signal generation
        case(io.address)
            2'd0: begin
                      if(io.write) cIo.counterWe       = 1'b1;
                      if(io.read)  cIo.counterRe       = 1'b1;
                  end
            2'd1: begin
                      if(io.write) cIo.counterConfigWe = 1'b1;
                      if(io.read)  cIo.counterConfigRe = 1'b1;
                  end
            2'd2: begin
                      if(io.read)  cIo.counterStatusRe = 1'b1;
                  end
            default: ; // use already assigned default values
        endcase


        // input data bit to device register input bit mapping (for writes)
        cIo.counterIn    = io.dataIn;
        cIo.counterEnIn  = io.dataIn[0];
        cIo.counterDirIn = io.dataIn[1];
        cIo.counterIreIn = io.dataIn[2];


        // device register output bit to output data bit mapping (for reads)
        case(address)
            2'd0: io.dataOut = cIo.counterOut;
            2'd1: io.dataOut = {29'b0, cIo.counterIreOut, cIo.counterDirOut, cIo.counterEnOut};
            2'd2: io.dataOut = {31'b0, cIo.counterLT1000Out};
            default: ; // use already assigned default values
        endcase
    end


    // other logic assignments
    assign cIo.clk   = io.clk;
    assign cIo.reset = io.reset;
    assign io.irq    = cIo.counterIrqOut;


    // instantiate the core
    core
    core(
        .io  (cIo)
    );


endmodule

