

// interface definition
interface coreIo;
    // clocks and resets
    logic          clk;
    logic          reset;
    
    
    // device register inputs
    logic  [31:0]  counterIn;
    logic          counterEnIn;
    logic          counterDirIn;
    logic          counterIreIn;


    // device register outputs
    logic  [31:0]  counterOut;
    logic          counterEnOut;
    logic          counterDirOut;
    logic          counterIreOut;
    logic          counterLT1000Out; // count is less than 1000 status output (read only)


    // device register control signals
    logic          counterWe;        // counter register write enable
    logic          counterRe;        // counter register read enable (only needed in some cases)
    logic          counterConfigWe;  // counter config register write enable
    logic          counterConfigRe;  // counter config register read enable (only needed in certain cases)
    logic          counterStatusRe;  // counter status register read enable (only needed in certain cases)


    // interrupt request lines
    logic          counterIrqOut;    // counter interrupt request output


    // modport list (used to define signal direction for specific situations)
    modport in (
        input   clk,
        input   reset,
        input   counterIn,
        input   counterEnIn,
        input   counterDirIn,
        input   counterIreIn,
        output  counterOut,
        output  counterEnOut,
        output  counterDirOut,
        output  counterIreOut,
        output  counterLT1000Out,
        input   counterWe,
        input   counterRe,
        input   counterConfigWe,
        input   counterConfigRe,
        input   counterStatusRe,
        output  counterIrqOut
    );

endinterface


// core code
module core(
    coreIo.in io
    );


    // device registers
    logic  [31:0]  counter;       // counter value
    logic          counterEn;     // counter enable
    logic          counterDir;    // counter direction
    logic          counterIre;    // counter interrupt request enable
    logic          counterLT1000; // counter less than 1000


    // hidden registers
    logic          counterIrq;    // counter interrupt request


    // other internal logic signals
    logic  [31:0]  counterNext;
    logic          counterEnNext;
    logic          counterDirNext;
    logic          counterIreNext;
    logic          counterLT1000Next;
    logic          counterIrqNext;


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            // reset conditions
            counter       <= 32'b0;
            counterEn     <= 1'b0;
            counterDir    <= 1'b0;
            counterIre    <= 1'b0;
            counterLT1000 <= 1'b0;
            counterIrq    <= 1'b0;
        end else begin
            // default conditions
            counter       <= counterNext;
            counterEn     <= counterEnNext;
            counterDir    <= counterDirNext;
            counterIre    <= counterIreNext;
            counterLT1000 <= counterLT1000Next;
            counterIrq    <= counterIrqNext;
        end
    end


    // combinational logic block
    always_comb begin
        // default logic values
        counterIrqNext    = 1'b0;                  // do not signal an interrupt
        counterNext       = counter;               // retain old count value
        counterEnNext     = counterEn;             // retain old data
        counterDirNext    = counterDir;            // retain old data
        counterIreNext    = counterIre;            // retain old data
        counterLT1000Next = counterLT1000;         // retain old data


        // counter logic
        if(io.counterWe)
            counterNext = io.counterIn;            // load new count from bus master
        else begin
            if(counterEn) begin                    // if counting is enabled then
                if(counterDir)
                    counterNext = counter + 32'd1; // count up
                else
                    counterNext = counter - 32'd1; // count down
            end
        end


        // config logic
        if(io.counterConfigWe) begin
            counterEnNext  = io.counterEnIn;       // load new config value from bus master
            counterDirNext = io.counterDirIn;      // load new config value from bus master
            counterIreNext = io.counterIreIn;      // load new config value from bus master
        end


        // status logic
        counterLT1000Next = counter < 1000;        // set the less than 1000 status flag if the count is less than 1000


        // interrupt triggering logic
        if(counterIre && &counter[15:0])           // trigger an interrupt if interrupts are enabled and
            counterIrqNext = 1'b1;                 // the lower 16 bits of the counter are set


        // assign output values
        io.counterOut       = counter;
        io.counterEnOut     = counterEn;
        io.counterDirOut    = counterDir;
        io.counterIreOut    = counterIre;
        io.counterLT1000Out = counterLT1000;
        io.counterIrqOut    = counterIrq;

    end


endmodule

