

/*
* Lowpass filter 
* Eliptic filter with cutoff of 0.042 times clock freqency
* with 141Mhz this is 5.0Mhz
*/
module filter (
    input clk,
    input reset,
    input  signed[6:0] x0,
    output signed[6:0] out
);

    localparam signed [15:0] a0 = 16384;
    localparam signed [15:0] a1 = -47115;
    localparam signed [15:0] a2 = 45220;
    localparam signed [15:0] a3 = 14484;

    localparam signed [15:0] b0 = 46;
    localparam signed [15:0] b1 = -44;
    localparam signed [15:0] b2 = -44;
    localparam signed [15:0] b3 = 46;

    reg signed[31:0] y0;
    reg signed[31:0] y1;
    reg signed[31:0] y2;
    reg signed[31:0] y3;

    reg signed[15:0] x1;
    reg signed[15:0] x2;
    reg signed[15:0] x3;

    assign out = y0 > 63 ? 63  :
                 y0 <-63 ? -63 :
                 y0;

    always @(posedge clk ) begin
        if(reset) begin
            y0 <= 0;
            y1 <= 0;
            y2 <= 0;
            y3 <= 0;

            x1 <= 0;
            x2 <= 0;
            x3 <= 0;
            
        end else begin
;
            
            y0 <=( a0 * x0 + a1 * x1 + a2*x2 + a3*x3
                -b1 * y1 - b2 * y2 - b3*y3 ) >>>14;

            y1 <= y0;
            y2 <= y1;
            y3 <= y2;

            x1 <= x0;
            x2 <= x1;
            x3 <= x2;            
        end


    end

endmodule