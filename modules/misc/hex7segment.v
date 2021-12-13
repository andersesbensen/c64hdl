module hex7segment(
           input reset,
           input clk,
           input[31:0] segment_number,
           output reg[6:0] disp_seg,
           output reg[7:0] disp_an
       );

reg[31:0] segment_numberL;
reg[13:0] div;
reg[2:0] digit;

wire low_clk = div[13];
always @( posedge clk ) div <= reset ? 0 : div +1;

always @( posedge low_clk ) begin
    if(digit == 7)
        segment_numberL[31:0] <= segment_number[31:0];
    else
        segment_numberL <= segment_numberL >> 4;

    digit <= reset ? 0 : digit + 1;
    disp_an <= 1'b1 << (digit);

    case (segment_numberL[3:0])
        4'h0: disp_seg <= 7'b0111111;
        4'h1: disp_seg <= 7'b0000110;
        4'h2: disp_seg <= 7'b1011011;
        4'h3: disp_seg <= 7'b1001111;
        4'h4: disp_seg <= 7'b1100110;
        4'h5: disp_seg <= 7'b1101101;
        4'h6: disp_seg <= 7'b1111101;
        4'h7: disp_seg <= 7'b0000111;
        4'h8: disp_seg <= 7'b1111111;
        4'h9: disp_seg <= 7'b1101111;
        4'hA: disp_seg <= 7'b1110111;
        4'hB: disp_seg <= 7'b1111100;
        4'hC: disp_seg <= 7'b0111001;
        4'hD: disp_seg <= 7'b1011110;
        4'hE: disp_seg <= 7'b1111001;
        4'hF: disp_seg <= 7'b1110001;
    endcase
end
endmodule
