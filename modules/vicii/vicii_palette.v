// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.


module vicii_palette (
           input[3:0] pixel,
           output reg [4:0] luma,
           output reg [4:0] chroma,
           output reg chroma_en
       );

always @(*) begin
    case(pixel)
        0: begin chroma <=  0; chroma_en<=0; luma <=  0; end // black
        1: begin chroma <=  0; chroma_en<=0; luma <= 31; end // white
        2: begin chroma <= 5'h09; chroma_en<=1; luma <= 10; end // red
        3: begin chroma <= 5'h18; chroma_en<=1; luma <= 20; end // cyan
        4: begin chroma <= 5'h02; chroma_en<=1; luma <= 12; end // purple
        5: begin chroma <= 5'h12; chroma_en<=1; luma <= 16; end // green
        6: begin chroma <=  0; chroma_en<=1; luma <=  8; end // blue
        7: begin chroma <= 5'h0d; chroma_en<=1; luma <= 24; end // yellow
        8: begin chroma <= 5'h0a; chroma_en<=1; luma <= 12; end // orange
        9: begin chroma <= 5'h0b; chroma_en<=1; luma <=  8; end // brown
        10:begin chroma <= 5'h09; chroma_en<=1; luma <= 16; end // light red
        11:begin chroma <=  0; chroma_en<=0; luma <= 10; end // dark grey
        12:begin chroma <=  0; chroma_en<=0; luma <= 15; end // grey
        13:begin chroma <= 5'h12; chroma_en<=1; luma <= 24; end // light green
        14:begin chroma <=  0; chroma_en<=1; luma <= 15; end // light blue
        15:begin chroma <=  0; chroma_en<=0; luma <= 20; end // light grey
    endcase
end

endmodule


