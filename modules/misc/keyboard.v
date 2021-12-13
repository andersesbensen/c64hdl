module keyboard (
           input clk,
           input reset,
           input[7:0] data,
           input data_rdy, //New data is ready in data, set for one clock cycle

           input[7:0] scan_in,
           output[7:0] scan_out
       );

//https://techdocs.altium.com/display/FPGA/PS2+Keyboard+Scan+Codes
reg[7:0] key_matrix[7:0]; //keymatix, each bit represent one key
reg press;
reg extended;

wire[7:0] row0 = scan_in[0] ? 8'hff : key_matrix[0];
wire[7:0] row1 = scan_in[1] ? 8'hff : key_matrix[1];
wire[7:0] row2 = scan_in[2] ? 8'hff : key_matrix[2];
wire[7:0] row3 = scan_in[3] ? 8'hff : key_matrix[3];
wire[7:0] row4 = scan_in[4] ? 8'hff : key_matrix[4];
wire[7:0] row5 = scan_in[5] ? 8'hff : key_matrix[5];
wire[7:0] row6 = scan_in[6] ? 8'hff : key_matrix[6];
wire[7:0] row7 = scan_in[7] ? 8'hff : key_matrix[7];

assign scan_out = row0 & row1 & row2 & row3 & row4 & row5 & row6 & row7;

always @(posedge clk) begin
    if(reset) begin
        press <= 0;
        extended <=0;
        key_matrix[0] <=8'hff;
        key_matrix[1] <=8'hff;
        key_matrix[2] <=8'hff;
        key_matrix[3] <=8'hff;
        key_matrix[4] <=8'hff;
        key_matrix[5] <=8'hff;
        key_matrix[6] <=8'hff;
        key_matrix[7] <=8'hff;
    end

    if(data_rdy)
    begin
        if(data == 8'hF0)
            press<=1;
        else if(data == 8'hE0)
            extended<=1;
        else begin
            press<=0;
            extended<=0;
            case(data)
                //row 0
                8'h66: key_matrix[0][0]<= press; //Backspace
                8'h5A: key_matrix[0][1]<= press; //Return
                8'h6B: key_matrix[0][2]<= press; //cursor left/right
                8'h83: key_matrix[0][3]<= press; //F7
                8'h05: key_matrix[0][4]<= press; //F1
                8'h04: key_matrix[0][5]<= press; //F3
                8'h03: key_matrix[0][6]<= press; //F5
                8'h72: key_matrix[0][7]<= press; //up/down
                //row 1
                8'h26: key_matrix[1][0]<= press; //3
                8'h1d: key_matrix[1][1]<= press; //w
                8'h1c: key_matrix[1][2]<= press; //a
                8'h25: key_matrix[1][3]<= press; //4
                8'h1a: key_matrix[1][4]<= press; //z
                8'h1b: key_matrix[1][5]<= press; //s
                8'h24: key_matrix[1][6]<= press; //e
                8'h12: key_matrix[1][7]<= press; //left shift
                //row2
                8'h2e: key_matrix[2][0]<= press; //5
                8'h2d: key_matrix[2][1]<= press; //R
                8'h23: key_matrix[2][2]<= press; //D
                8'h36: key_matrix[2][3]<= press; //6
                8'h21: key_matrix[2][4]<= press; //C
                8'h2b: key_matrix[2][5]<= press; //F
                8'h2c: key_matrix[2][6]<= press; //T
                8'h22: key_matrix[2][7]<= press; //X

                //row3
                8'h3d: key_matrix[3][0]<= press; //7
                8'h35: key_matrix[3][1]<= press; //Y
                8'h34: key_matrix[3][2]<= press; //G
                8'h3e: key_matrix[3][3]<= press; //8
                8'h32: key_matrix[3][4]<= press; //B
                8'h33: key_matrix[3][5]<= press; //H
                8'h3c: key_matrix[3][6]<= press; //U
                8'h2a: key_matrix[3][7]<= press; //V

                //row4
                8'h46: key_matrix[4][0]<= press; //9
                8'h43: key_matrix[4][1]<= press; //I
                8'h3B: key_matrix[4][2]<= press; //J
                8'h45: key_matrix[4][3]<= press; //0
                8'h3A: key_matrix[4][4]<= press; //M
                8'h42: key_matrix[4][5]<= press; //K
                8'h44: key_matrix[4][6]<= press; //O
                8'h31: key_matrix[4][7]<= press; //N

                //row5
                8'h79: key_matrix[5][0]<= press; //+
                8'h4D: key_matrix[5][1]<= press; //P
                8'h4B: key_matrix[5][2]<= press; //L
                8'h7B: key_matrix[5][3]<= press; //-
                8'h71: key_matrix[5][4]<= press; //.
                8'h4C: key_matrix[5][5]<= press; //:
                8'h52: key_matrix[5][6]<= press; //@
                8'h41: key_matrix[5][7]<= press; //,

                //row6
                8'h0e : key_matrix[6][0]<= press; //$
                8'h5D : key_matrix[6][1]<= press; //\
                8'h4C : key_matrix[6][2]<= press; //;
                8'h6C : if(extended) key_matrix[6][3]<= press; // Clear/Home
                8'h59 : key_matrix[6][4]<= press; // Right shift
                8'h55 : key_matrix[6][5]<= press; // =
                8'h75 : if(extended) key_matrix[6][6]<= press; // Up arrow
                8'ha4 : if(extended) key_matrix[6][7]<= press; // slash

                //row7
                8'h16 : key_matrix[7][0]<= press; // 1
                8'h6b : key_matrix[7][1]<= press; // (left arrow)
                8'h14 : key_matrix[7][2]<= press; // (Control)
                8'h1e : key_matrix[7][3]<= press; // 2
                8'h29 : key_matrix[7][4]<= press; // space
                8'h26 : key_matrix[7][5]<= press; // Commodore
                8'h15 : key_matrix[7][6]<= press; // Q
                8'h76 : key_matrix[7][7]<= press; // Run stop
                default :
                    ;
            endcase
        end
    end
end
endmodule

