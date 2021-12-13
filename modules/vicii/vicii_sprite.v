
module vicii_sprite #(parameter number = 0)
       (
           input clk,
           input reset,
           input[7:0] di,
           input[3:0] VM1,
           input[8:0] Xc,
           input[7:0] Yc,
           input[8:0] X,
           input[7:0] Y,
           input[3:0] SC, //Sprite color
           input[3:0] SMC0, //Sprite multicolor
           input[3:0] SMC1, //Sprite multucolor
           input MCM,
           output reg[13:0] ao,
           output reg ba,
           output reg pixel_enable,
           output reg[3:0] pixel
       );

//Sprites
reg[7:0] MP; //Sprite pointer
reg[5:0] MC; //Access counter
reg[23:0] data; //data shift register
reg[4:0] cnt;   //horizontal counter, ie how many times did we shift
localparam sc = 336  + number*16 ;

always @(posedge clk )begin
    if(reset)begin
        ba <=0;
        MC <=63;
        ao <=0;
        pixel_enable <=0;
        cnt<=24;
    end
    
    // Address generation
    if(Xc == sc)begin
        ao <= {VM1[3:0],{7'b1111111},number[2:0] };
        ba <=1;

        //Check if we should start to draw sprite
        if( Yc == Y )begin
            MC <=0;
        end
    end
    else if( Xc == (sc + 2) )begin //Store the Memory pointer
        MP[7:0] <= di[7:0];
        ao <= 0;
        if (MC == 63)begin //Are we already drawing the sprite?
            ba <=0;
        end
    end
    else if( (Xc == (sc+4)) & ba)begin
        ao <= {MP[7:0],MC[5:0] };
        MC <= MC +1;
    end
    else if( (Xc == (sc+6)) & ba)begin
        data[23:16] <= di[7:0];
    end
    else if( (Xc == (sc+8)) & ba)begin
        ao <= {MP[7:0],MC[5:0] };
        MC <= MC +1;
    end
    else if( (Xc == (sc+10)) & ba)begin
        data[15:8] <= di[7:0];
    end
    else if( (Xc == (sc+12)) & ba)begin
        ao <= {MP[7:0],MC[5:0] };
        MC <= MC +1;
    end
    else if( Xc == (sc+14) & ba)begin
        data[7:0] <= di[7:0];
        ao <= 0;
    end
    else if( Xc == (sc+16) & ba)begin
        ba <=0;
    end

    //Are we active
    if(MC != 63)begin
        if( Xc == X)begin
            cnt<= 0;
        end
        if(cnt != 24)begin
            cnt<= cnt + 1;
            if(MCM)begin
                case(data[23:22])
                    1:
                        pixel <=SMC0; //Sprite multicolor 0
                    2:
                        pixel <=SC; //Sprite color
                    3:
                        pixel <=SMC1; //Sprite multicolor 0
                endcase
                pixel_enable <= (data[23:22] != 0);
                if(Xc[0])
                    data<= data<<2;
            end
            else begin
                pixel <= SC;
                pixel_enable <= (data[23] != 0);
                data<= data<<1;
            end
        end
        else
            pixel_enable <= 0;
    end
end

endmodule
