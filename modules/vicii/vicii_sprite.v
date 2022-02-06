
module vicii_sprite #(parameter number = 0)
       (
           input clk,
           input reset,
           input[7:0] di,
           input[3:0] VM1,
           input[8:0] Xc, //Xcounter
           input[8:0] Yc, //Ycounter
           input[8:0] X,  //Sprite position X
           input[8:0] Y,  //Sprite position Y
           input XE,  //X expand
           input YE,  //Y expand

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
reg[5:0] MCBASE; //Access counter

reg[23:0] data; //data shift register
reg[5:0] xcnt;   //horizontal counter, ie how many times did we shift
reg[5:0] ycnt;   //vertical counter
reg active;

localparam sc = 4+ 336  + number*16 ;

always @(posedge clk )begin
    if(reset)begin
        ba <=0;
        MC <=63;
        ao <=0;
        pixel_enable <=0;
        xcnt<=24;
        active<=0;
    end

    // Address generation
    if(Xc == sc)begin
        ao <= {VM1[3:0],{7'b1111111},number[2:0] };
        ba <=1;

        //Check if we should start to draw sprite
        if( Yc == Y )begin
            MC <=0;
            MCBASE<=0;
            ycnt <=0;
            active <=1;
        end else begin
            MC <= MCBASE;
            ycnt <= ycnt + 1;
        end

    end
    else if( Xc == (sc + 2) )begin //Store the Memory pointer
        MP[7:0] <= di[7:0];
        ao <= 0;
        if (MCBASE == 63)begin //Are we already drawing the sprite?
            ba <=0;
            active <=0;
        end
    end
    else if( (Xc == (sc+4)) && ba)begin
        ao <= {MP[7:0],MC[5:0] };
        MC <= MC +1;
    end
    else if( (Xc == (sc+6)) && ba)begin
        data[23:16] <= di[7:0];
    end
    else if( (Xc == (sc+8)) && ba)begin
        ao <= {MP[7:0],MC[5:0] };
        MC <= MC +1;
    end
    else if( (Xc == (sc+10)) && ba)begin
        data[15:8] <= di[7:0];
    end
    else if( (Xc == (sc+12)) && ba)begin
        ao <= {MP[7:0],MC[5:0] };
        MC <= MC +1;
    end
    else if( (Xc == (sc+14)) && ba)begin
        data[7:0] <= di[7:0];
        ao <= 0;
    end
    else if( (Xc == (sc+16)) && ba)begin
        ba <=0;
        xcnt <=0;

        if(!YE)
            MCBASE <= MC;
        else if(ycnt[0]==1)
            MCBASE <= MC;
    end

    //Are we active
    if(active)begin
        if( (Xc == X) || (xcnt!=0)  )begin
            xcnt <= xcnt + 1;
            if(MCM)begin
                case(data[23:22])
                    0:  //Transparent
                        ;
                    1:
                        pixel <=SMC0; //Sprite multicolor 0
                    2:
                        pixel <=SC; //Sprite color
                    3:
                        pixel <=SMC1; //Sprite multicolor 0
                endcase
                pixel_enable <= (data[23:22] != 0);

                if(  (XE && ((xcnt & 3) ==3 )) ||
                        (!XE && ((xcnt & 1) ==1 ))
                  ) data<= data<<2;
            end
            else begin
                pixel <= SC;
                pixel_enable <= (data[23] != 0);

                if( !XE )
                    data<= data<<1;
                else if (xcnt[0] )
                    data<= data<<1;
            end
        end
    end
end

endmodule
