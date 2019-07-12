

// interface definition
interface avalonIo;
    logic          clk;
    logic          reset;
    logic          read;
    logic          write;
    logic          address;
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


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            io.readValid <= 1'b0;
        end else begin
            io.readValid <= io.read;
        end
    end


    // combinational logic block
    always_comb begin
        // defaults
        io.dataOut     = 32'd0;
        io.irq         = cIo.irq;
        cIo.clk        = io.clk;
        cIo.reset      = io.reset;
        cIo.counter1We = 1'b0;
        cIo.counter2We = 1'b0;
        cIo.counter1Re = 1'b0;
        cIo.counter2Re = 1'b0;

        
        // input data to device register input bit mapping
        cIo.counter1In = io.dataIn;
        cIo.counter2In = io.dataIn;


        // device register output bit to output data mapping and control signal generation
        case(io.address)
            1'd0: begin
                      io.dataOut = cIo.counter1;
                      if(io.read)  cIo.counter1Re = 1'b1;
                      if(io.write) cIo.counter1We = 1'b1;
                  end
            1'd1: begin
                      io.dataOut = cIo.counter2;
                      if(io.read)  cIo.counter2Re = 1'b1;
                      if(io.write) cIo.counter2We = 1'b1;
                  end
        endcase
    end


    // instantiate the core
    core
    core(
        .io  (cIo)
    );


endmodule

