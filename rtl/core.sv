

// interface definition
interface coreIo;
    // clocks and resets
    logic          clk;
    logic          reset;
    
    
    // device register inputs
    logic  [31:0]  counterIn;
    logic          counterEnIn;
    logic          counterDirIn;
    
    
    // device register outputs
    logic  [31:0]  counterOut;
    logic          counterEnOut;
    logic          counterDirOut;
    logic          counterLT1000Out; // count is less than 1000 status output (read only)


    // device register control signals
    logic          counterWe;       // counter register write enable
    logic          counterRe;       // counter register read enable (only needed in some cases)
    logic          counterConfigWe; // counter config register write enable
    logic          counterConfigRe; // counter config register read enable (only needed in certain cases)
    logic          counterStatusRe; // counter status register read enable (only needed in certain cases)


    // interrupt request lines
    logic          counterIrq;      // counter interrupt request


    // modport list (used to define signal direction for specific situations)
    modport in (
        input   clk,
        input   reset,
        input   counterIn,
        input   counterEnIn,
        input   counterDirIn,
        output  counterOut,
        output  counterEnOut,
        output  counterDirOut,
        output  counterLT1000Out,
        input   counterWe,
        input   counterRe,
        input   counterConfigWe,
        input   counterConfigRe,
        input   counterStatusRe,
        output  counterIrq
    );

endinterface


// core code
module core(
    coreIo.in io
    );


    // device registers
    logic  [31:0]  counter;
    logic          counterEn;
    logic          counterDir;
    logic          counterLT1000;

    // other internal logic signals
    logic  [31:0]  counterNext;
    logic          counterEnNext;
    logic          counterDirNext;
    logic          counterLT1000Next;


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            // reset conditions
            counter       <= 32'b0;
            counterEn     <= 1'b0;
            counterDir    <= 1'b0;
            counterLT1000 <= 1'b0;
        end else begin
            // default conditions
            counter       <= counterNext;
            counterEn     <= counterEnNext;
            counterDir    <= counterDirNext;
            counterLT1000 <= counterLT1000Next;
        end
    end


    // combinational logic block
    always_comb begin
        // default logic values
        io.counterIrq     = 1'b0;           // do not signal an interrupt
        counterNext       = counter;        // retain old count value
        counterEnNext     = counterEn;      // retain old data
        counterDirNext    = counterDir;     // retain old data
        counterLT1000Next = counterLT1000;  // retail old data


        // counter logic
        if(io.counterWe)
            counterNext = io.counterIn;     // load new count from bus master
        else begin
            if(counterEn) begin             // if counting is enabled then
                if(counterDir)
                    counterNext = counter + 32'd1; // count up
                else
                    counterNext = counter - 32'd1; // count down
            end
        end


        // config logic
        if(io.counterConfigWe) begin
            counterEnNext  = io.counterEnIn;  // load new config value from bus master
            counterDirNext = io.counterDirIn; // load new config value from bus master
        end


        // status logic
        counterLT1000Next = counter < 1000; // set the less than 1000 status flag if the count is less than 1000


        // interrupt triggering logic
        if(&counter[15:0])
            io.counterIrq = 1'b1;           // generate an interrupt if the lower 16 bits of the counter are set
    end


    // assign output values
    assign io.counterOut       = counter;
    assign io.counterEnOut     = counterEn;
    assign io.counterDirOut    = counterDir;
    assign io.counterLT1000Out = counterLT1000;


endmodule

