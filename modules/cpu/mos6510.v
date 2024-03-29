// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.


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


reg [7:0] PD_wrap; //IO direction
reg [7:0] PO_wrap; //Delay PO output to negative edge

always @(negedge phi2) begin
    if(AEC) DI_wrap2 <= DI;    
    //There a pullups on the outpus, ie when a port is not an output its
    //high
    
end

always @(posedge phi2)
begin
    PO <= (PO_wrap & PD_wrap) | (PI & ~PD_wrap);    

    if(reset) begin
        PO_wrap <= 0;
        PD_wrap <= 0;
    end
    else if(WE & RDY)
    case ( AB )
        0: begin 
            PD_wrap <= DO;
            //$display("bank %x %x eff %x",PO_wrap, DO,  (DO & PO_wrap) |  ~DO );
        end
        1: begin
            PO_wrap <= DO ;
            //$display("bank %x %x eff %x",DO , PD_wrap,  (PD_wrap & DO) |  ~PD_wrap );
        end
    endcase
    else
        if(RDY)
        case ( AB )
            0: DI_wrap <= PD_wrap;
            1: DI_wrap <= (PO_wrap & PD_wrap) | (PI & ~PD_wrap);
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
