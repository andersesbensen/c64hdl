
module mos6510(phi2, clk, reset, AB, DI, DO, WE, IRQ, NMI, RDY,PO,PI,AEC );
input phi2;		// CPU clock
input clk;		// CPU clock
input reset;		// reset signal
output [15:0] AB;	// address bus
input [7:0] DI;		// data in, read bus
output [7:0] DO; 	// data out, write bus
output reg [7:0] PO;
input  [7:0] PI;
input AEC;

output WE;		// write enable
input IRQ;		// interrupt request
input NMI;		// non-maskable interrupt request
input RDY;		// Ready signal. Pauses CPU when RDY=0

reg [7:0] DI_wrap;
reg [7:0] DI_wrap2;


reg [7:0] PD; //IO direction
reg [7:0] PO_wrap; //Delay PO output to negative edge

always @(negedge phi2) begin
    if(AEC) DI_wrap2 <= DI;
    PO <= PO_wrap;    
end

always @(posedge phi2)
begin
    if(reset) begin
        //TODO this is no correct the real cpu resets this to 0
        // but there are pullups on the hiram and lowram lines
        PO_wrap <= 8'h37;
        PD <= 8'h37;
    end
    else if(WE & RDY)
    case ( AB )
        0: PD <= DO;
        1: PO_wrap <= DO & PD;
    endcase
    else
        if(RDY)
        case ( AB )
            0: DI_wrap <= PD;
            1: DI_wrap <= (PO_wrap & PD) | (PI & ~PD);
            default:
                DI_wrap <= DI_wrap2;
        endcase

    //$display("CPU a=%h di = %h", AB,DI);
end

//assign DI_wrap = ADDR1 | DI;



cpu cpu_e(
        .clk(phi2),
        .reset(reset),
        .AB(AB),
        .DO(DO),
        .DI(DI_wrap),
        .WE(WE),
        .IRQ(IRQ),
        .NMI(NMI),
        .RDY(RDY)
    );

endmodule
