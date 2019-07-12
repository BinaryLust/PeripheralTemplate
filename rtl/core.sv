

// interface definition
interface coreIo;
    // clocks and resets
    logic          clk;
    logic          reset;
    
    
    // device register inputs
    logic  [31:0]  counter1In;
    logic  [31:0]  counter2In;
    
    
    // device registers (and outputs)
    logic  [31:0]  counter1;
    logic  [31:0]  counter2;


    // device register control signals
    logic          counter1We;  // write enable
    logic          counter2We;  // write eanble
    logic          counter1Re;  // read enable (only needed in some cases)
    logic          counter2Re;  // read enable (only needed in some cases)
    logic          irq;         // interrupt request


    // modport list (used to define signal direction for specific situations)
    modport in (
        input   clk,
        input   reset,
        input   counter1In,
        input   counter2In,
        output  counter1,
        output  counter2,
        input   counter1We,
        input   counter2We,
        input   counter1Re,
        input   counter2Re,
        output  irq
    );

    modport out (
        output  clk,
        output  reset,
        output  counter1In,
        output  counter2In,
        input   counter1,
        input   counter2,
        output  counter1We,
        output  counter2We,
        output  counter1Re,
        output  counter2Re,
        input   irq
    );

endinterface


// core code
module core(
    coreIo.in io
    );


    // internal logic signals
    logic  [31:0]  counter1Next;
    logic  [31:0]  counter2Next;


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            // reset conditions
            io.counter1 <= 32'b0;
            io.counter2 <= 32'b0;
        end else begin
            // default conditions
            io.counter1 <= counter1Next;
            io.counter2 <= counter2Next;
        end
    end


    // combinational logic block
    always_comb begin
        // default conditions
        io.irq = 1'b0;


        // counter1 logic
        if(io.counter1We)
            counter1Next = io.counter1In;
        else
            counter1Next = io.counter1 + 32'b1;


        // counter2 logic
        if(io.counter2We)
            counter2Next = io.counter2In;
        else
            counter2Next = io.counter2 + 32'b1;


        // interrupt triggering logic
        if(!io.counter1[7:0] || !io.counter2[15:0])  io.irq = 1'b1;
    end


endmodule

