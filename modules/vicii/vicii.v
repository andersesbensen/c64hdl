
/**
* VIC II bus timing
*
* cycle|   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |
*------|-------|-------|-------|-------|-------|-------|-------|-------|
*      | ______________________________                                |
* phi0 |                               |                               |
*      |                               |______________________________ |
*------|-------|-------|-------|-------|-------|-------|-------|-------|
*      | c-addr| c-addr| c-addr| c-data| g-addr| g-data|       | c-addr 
*      |                 
*/


module vicii (
           output[7:0] do,
           input[11:0] di,
           input[5:0] ai,
           output[13:0] ao,
           output irq_o, //This is inverted compared to the real vic
           input lp,
           input cs,
           input we,
           output ba, //This is inverted compared to the real vic
           output color_out,
           output[5:0] sync_lumen,
           output aec,
           input dot_clk,
           input color_clock,
           output reg phi0,
           input reset
       );
//public registers
wire[8:0] MX[7:0];
wire[7:0] MY[7:0];
wire ECM,BMM,DEN,RSEL;
wire[2:0] Y;
reg[8:0] RC;
wire[7:0] LPX,LPY; //lightpen
wire[7:0] ME; //Mib Enable
wire RES,MCM,CSEL;
wire[2:0] X;
wire[7:0] MYE;// MIB Y-expand
wire[3:0] VM1; //Memory Pointers note CB1[0] is not used
wire[3:0] CB1; //Memory Pointers note CB1[0] is not used
reg     ILP, IMMC,IMCB,IRST; // Interrupt Register
wire ELP, EMMC,EMCB,ERST; // Enable Interrupt Register
wire[7:0] MDP; //MIB-DATA Priority
wire[7:0] MMC; //MIB Multicolor Sel
wire[7:0] MXE; //MIB X-expand
wire[7:0] MM; // MIB-MIB Collision
wire[7:0] MD; //MIB-DATA Collision
wire[3:0] EC; //Exterior Color
wire[3:0] B0; //Bkgd #0 Color
wire[3:0] B1; //Bkgd #0 Color
wire[3:0] B2; //Bkgd #0 Color
wire[3:0] B3; //Bkgd #0 Color
wire[3:0] MM0; //MIB Multicolor #0
wire[3:0] MM1; //MIB Multicolor #1
wire[3:0] MC[7:0]; //M0C3 M0C2 M0C1 M0C0 MIB 0 Color

/*Internal registers*/
reg[8:0] Xc; //Pixel X 0-504
reg[2:0] RCs; //scrolled versio of RC
//HORIZONTAL DECODES
//NAME SET CLEAR FUNCTION
reg HSYNC; //416 452 Horizontal sync pulse
reg HEQ1; // 178 196 Horizontal equalization pulse 1
reg HEQ2; // 434 452 Horizontal equalization pulse 2
reg HBLANK; // 396 496 Blanks video during horiz retrace
reg BURST; // 456 492 Gates reference color burst
reg BKDE38; // 35 339 Enables 38 column background
reg BKDE40; // 28 348 Enables 40 colunn background
reg BOL; // 508 4 Begin line (internal clock)
reg EOL; // 340 346 End line (internal clock)
reg VINC; // 404 412 Increment vertical counter
reg CW; // 12 332 Enable character £etch
reg VMBA; // 496 332 Buss avail for character fetch
reg REFW; // 484 12 Enable dynamic ram refresh
reg SPBA; // 336 376 Buss avail for sprite #0 fetch

// VERTICAL  DECODES
reg VSYNC; // 17 20 Enables vertical sync
reg VEQ; // 14 , 23 Enables vertical equalazation
reg VBLANK; // 13 24 Blanks video during vert retrace
reg VSW24; // 55 247 Enables 24 row screen window
reg VSW25; // 51 251 Enables 25 row screen window
reg EEVMF; // 48 248 Enables character fetch

/*
  The lower order 10 bits are provided
  by an internal counter (VC9-VC0) which steps through the 1000
  character locations.
*/
reg[9:0] VC;
reg[9:0] VCBASE;

reg[5:0] VMLI; //index into the line ram
reg[11:0] D[39:0]; //line ram
reg[4:0] pixel[7:0]; //raster data, MSB is foregrund flag
reg[7:0]  g_data;
reg[11:0] c_data;

//Sprites
wire[13:0]  sp_ao[7:0]; //sprite address
wire[7:0]   sp_ba; //bad line for each sprite
wire[7:0]   sp_pixel_enable; //tramsperity bit
wire [3:0]  sp_pixel[7:0];        //pixel output

reg[13:0] vic_ao;


wire [4:0] chroma; // color phase adjustment
wire [4:0] luma;   // luma
wire chroma_en;   // color phase enable

reg[7:0] do_reg;

wire[8:0] RASTER_WATCH;
reg g_access;
reg g_access_enable;
reg vic_enable;
reg even;



localparam C_ADDR_PASE = 0;
localparam C_DATA_PASE = 2;
localparam D_ADDR_PASE = 4;
localparam D_DATA_PASE = 6;

integer i;
integer fd;
integer frame;
initial begin
    Xc=0;
    RC=0;
    VC=0;
    VMLI=0;
    frame=0;
    fd = 0 ;
    even = 0;
    for (i =0  ; i < 40 ;i=i+1 ) begin
        D[i] = 0;
    end
end
wire BKDE = (CSEL ? BKDE40 : BKDE38);
wire VSW  = (RSEL ? VSW25 : VSW24);

assign do = (cs && aec) ? do_reg : 0;

assign ao = vic_ao |
       sp_ao[0]| sp_ao[1]| sp_ao[2]| sp_ao[3]|
       sp_ao[4]| sp_ao[5]| sp_ao[6]| sp_ao[7];
wire vic_ba = ((RC[2:0] == (Y[2:0])) && vic_enable && EEVMF && VMBA);
assign ba = vic_ba || (sp_ba !=0);

wire d_access = (vic_ba);
assign irq_o =  ((ELP && ILP) || (EMMC && IMMC) || (EMCB && IMCB) || (ERST && IRST) );
assign aec = !( g_access | ba );

wire[4:0] current_pixel = pixel[X]; 
wire fg_enable = current_pixel[4]; // Is foreground pixel?

genvar n;

//Regiter bank
reg[7:0] R[46:0];


// Sprite register assignment
generate for(n=0; n < 8; n=n+1) begin : sprite_regs
        assign MX[n][7:0] = R[n*2];
        assign MY[n]      = R[n*2+1];
        assign MX[n][8]   = R[8'h10][n];
        assign MC[n]      = R[8'h27+n];
    end
endgenerate

assign MDP = R[8'h1B];
assign MMC = R[8'h1C];
assign MXE = R[8'h1D];
assign MM = R[8'h1E];
assign MD = R[8'h1F];

assign MM0 = R[8'h25][3:0];
assign MM1 = R[8'h26][3:0];
assign MYE = R[8'h17];
assign ME =  R[8'h15];


//Pointers
assign VM1 = R[8'h18][7:4];
assign CB1 = R[8'h18][3:0];

// Interupt enable
assign ELP  = R[8'h1A][3];
assign EMMC = R[8'h1A][2];
assign EMCB = R[8'h1A][1];
assign ERST = R[8'h1A][0];


//Color registers
assign EC =  R[8'h20][3:0];
assign B0 =  R[8'h21][3:0];
assign B1 =  R[8'h22][3:0];
assign B2 =  R[8'h23][3:0];
assign B3 =  R[8'h24][3:0];

// Generic registers
assign RASTER_WATCH[8] = R[8'h11][7];
assign ECM  = R[8'h11][6];
assign BMM  = R[8'h11][5];
assign DEN = R[8'h11][4];
assign RSEL = R[8'h11][3];
assign Y = R[8'h11][2:0];

assign RASTER_WATCH[7:0] = R[8'h12];

assign RES = R[8'h16][5];
assign MCM  = R[8'h16][4];
assign CSEL = R[8'h16][3];
assign X    = R[8'h16][2:0];


//Register read write
always @(posedge dot_clk)
begin
    if(Xc[2:0] == 3)
        phi0 <=1;
    else if(Xc[2:0] == 7)
        phi0 <=0;

    if(reset) begin
        for (i =0  ; i < 46 ;i=i+1 ) begin
            R[i] <= 0;
        end

        ILP <=0;
        IMMC <=0;
        IMCB <=0;
        IRST <=0;
        EEVMF<=0;
        VMBA<=0;
        vic_ao <=0;
        RCs <=0;
        VC<= 0;
        VCBASE<=0;
        VSYNC <=0;
        HSYNC <=0;
        VBLANK<=0;
        HBLANK<=0;
        VEQ<=0;
        HEQ1<=0;
        HEQ2<=0;
        vic_enable <=0;
        g_access_enable <=0;
    end

    if(we && cs && aec && (Xc[2:0] == 4))
    begin
        $display("vic write %h %h",ai,di);
        case (ai)
            /*
                When an interrupts occurs, the
                corresponding bit in the latch is set. To clear it, the processor has to
                write a "1" there "by hand".
            */
            8'h19: begin
                /*if(di[0]) IRST <=0;
                if(di[1]) IMCB <=0;
                if(di[2]) IMMC <=0;
                if(di[3]) ILP  <=0;*/
                IRST <=0;
                IMCB <=0;
                IMMC <=0;
                ILP  <=0;
            end
            default:
                R[ai] <= di;

        endcase
    end 

    //Read registers   
    if(!we && cs && aec )
    case (ai)
        8'h11: do_reg <=  { RC[8], R[ai][6:0] };
        8'h12: do_reg <=  RC[7:0];
        8'h16: do_reg <=  {2'b11, RES,MCM,CSEL,X};
        8'h19: do_reg <=  { irq_o ,3'b111,ILP, IMMC,IMCB,IRST};
        8'h1A: do_reg <=  {4'b1111,ELP, EMMC,EMCB,ERST};
        default:
            if(ai >= 8'h20)
                do_reg <= {4'b1111,R[ai][3:0]};
            else if (ai >= 8'h2f)
                do_reg <= 8'hff;  
            else
                do_reg <= R[ai];
    endcase
    else 
        do_reg <= 0;

    if((Xc[2:0] == 4) ) begin
        if(VINC ) begin
            // VERTICAL  DECODES
            even <= !even;

            //if(RC == 261) RC  <=0;// Resets vertical count to zero
            if(RC == 311) begin
                RC <= 0; //PAL
                VCBASE <=0;
                g_access_enable <=0;
                vic_enable <=0;
            end else begin
                RC <= RC + 1;
                RCs <= RCs + 1;
            end

            if(RC == (17+312-32-1)) VSYNC  <= 1; if(RC == (20+312-32-1)) VSYNC  <= 0;
            if(RC == (14+312-32-1)) VEQ    <= 1; if(RC == (23+312-32-1)) VEQ    <= 0;
            if(RC == (13+312-32-1)) VBLANK <= 1; if(RC == (24+312-32-1)) VBLANK <= 0;
            if(RC == (55-1)) VSW24 <= 1; if(RC == (247-1)) VSW24 <= 0;
            if(RC == (51-1)) VSW25 <= 1; if(RC == (251-1)) VSW25 <= 0;
            if(RC == (48-1)) EEVMF <= 1; if(RC == (248-1)) EEVMF <= 0;

        end
    end

    //At the start of a line
    if(Xc == 0) begin
        if((RC == RASTER_WATCH)) IRST <= 1;

        VMLI <= 0;

        if(EEVMF & (RC[2:0] == Y[2:0]))
            VCBASE <= VC;
        else
            VC <= VCBASE;

    end
    if(RC == (48)) vic_enable <= DEN;        

    //End of line
    //PAL version only has 63 cycles pr line
    if(Xc == 503) begin
        Xc <=0;
    end else
        Xc <= Xc + 1;


    //d access
    if( d_access ) begin
        RCs <= 0;
        g_access_enable <= 1;

        if(Xc[2:0] == D_ADDR_PASE) begin
            vic_ao[13:0] <= { VM1[3:0], VC[9:0] };
        end
        if(Xc[2:0] == D_DATA_PASE) begin
            D[VMLI] <= di;
        end
    end

    //g access
    if(g_access_enable & CW & (Xc[2:0] == C_ADDR_PASE) ) begin
        g_access <= 1;

        //In ECM mode the two MSB of D is uesd for color info
        vic_ao[13:0] <= ECM ? {CB1[3:1], 2'b0,D[VMLI][5:0], RCs[2:0] } :
              BMM ? {CB1[3],             VC[9:0], RCs[2:0] } :
              {CB1[3:1],      D[VMLI][7:0], RCs[2:0] };
    end

    if( g_access_enable & CW & (Xc[2:0] == C_DATA_PASE) ) begin
        g_data <= di[7:0];
        c_data <= D[VMLI];
        VMLI <= VMLI + 1;
        VC <= VC + 1;
    end else if(MCM) begin
        //In multicolor more we do a doub3'b000le shift every second cycle
        if(Xc[0] == 0) g_data <= g_data<<2;
    end else
        g_data <= g_data<<1;

    if(Xc[2:0] == 2) begin
        g_access <= 0;
    end

    if(Xc == 335) vic_ao <=0;

    // Horizontal decodes
    if(Xc == (416-16)) HSYNC <= 1; if(Xc == (452-16)) HSYNC <= 0;
    if(Xc == (396-16)) HBLANK <= 1;if(Xc == (496-16)) HBLANK <= 0;
    if(Xc == (456-16)) BURST <= 1; if(Xc == (492-16)) BURST <= 0;
    if(Xc == 178-16) HEQ1 <= 1;  if(Xc == 196-16) HEQ1 <= 0;
    if(Xc == 434-16) HEQ2 <= 1;  if(Xc == 452-16) HEQ2 <= 0;

    //if(Xc == 35) BKDE38 <= 1; if(Xc == 339) BKDE38 <= 0;
    //if(Xc == 28) BKDE40 <= 1; if(Xc == 348) BKDE40 <= 0;
    if(Xc == 26) BKDE38 <= 1; if(Xc == 330) BKDE38 <= 0;
    if(Xc == 19) BKDE40 <= 1; if(Xc == 339) BKDE40 <= 0;

    if(Xc == 500) BOL <= 1;   if(Xc ==   0) BOL <= 0;
    //if(Xc == 508) BOL <= 1;   if(Xc == 4) BOL <= 0;
    if(Xc == 340) EOL <= 1;   if(Xc == 346) EOL <= 0;
    if(Xc == 404) VINC <= 1;  if(Xc == 412) VINC <= 0;
    if(Xc == 12) CW <= 1;     if(Xc == 332) CW <= 0;
    if(Xc == 496) VMBA <= 1;  if(Xc == 332) VMBA <= 0;
    if(Xc == 484) REFW <= 1;  if(Xc == 12) REFW <= 0;
    if(Xc == 336) SPBA <= 1;  if(Xc == 376) SPBA <= 0;

    //pixel generation
    if( (ECM==0) && (BMM==0) && (MCM == 0) ) //Textmode
        pixel[0] <= g_data[7] ? c_data[11:8] : B0[3:0];
    else if( (ECM==1) && (BMM==0) && (MCM == 0) ) //ECM text mode
        if( g_data[7] )
            pixel[0] <=  c_data[11:8];
        else case (c_data[7:6])
            0: pixel[0] <= B0[3:0];
            1: pixel[0] <= B1[3:0];
            2: pixel[0] <= B2[3:0];
            3: pixel[0] <= B3[3:0];
        endcase
    else if( (ECM==0) && (BMM==1) && (MCM == 0) ) //Bitmap mode
        pixel[0] <= g_data[7] ? c_data[7:4] : c_data[3:0];
    else if( (ECM==0) && (BMM==0) && (MCM == 1) ) //Multicolor textmode
        if( c_data[11]==0 )
            pixel[0] <= g_data[7] ? c_data[10:8] : B0[3:0];
        else
        case (g_data[7:6])
            0: pixel[0] <= B0[3:0];
            1: pixel[0] <= B1[3:0];
            2: pixel[0] <= B2[3:0];
            3: pixel[0] <= {1'b0,c_data[10:8]};
        endcase
    else if( (ECM==0) && (BMM==1) && (MCM == 1) ) //Multicolor bitmap mode
    case (g_data[7:6])
        0: pixel[0] <= B0[3:0];
        1: pixel[0] <= c_data[7:4];
        2: pixel[0] <= c_data[3:0];
        3: pixel[0] <= c_data[11:8];
    endcase

    //Set the foreground flag
    pixel[0][4] <= g_data[7];

    //delay line used for scrolling
    pixel[1] <= pixel[0];
    pixel[2] <= pixel[1];
    pixel[3] <= pixel[2];
    pixel[4] <= pixel[3];
    pixel[5] <= pixel[4];
    pixel[6] <= pixel[5];
    pixel[7] <= pixel[6];

    // A collision of sprites among themselves is detected as soon as two or more
    // sprite data sequencers output a non-transparent pixel in the course of
    // display generation (this can also happen somewhere outside of the visible
    // screen area). In this case, the MxM bits of all affected sprites are set in
    // register $d01e and (if allowed, see section 3.12.), an interrupt is
    // generated. The bits remain set until the register is read by the processor
    // and are cleared automatically by the read access.
    if((sp_pixel_enable & (sp_pixel_enable - 1) != 0)) begin
        IMMC <= 1;
        R[8'h1e] <= sp_pixel_enable;
    end


    // A collision of sprites and other graphics data is detected as soon as one
    // or more sprite data sequencers output a non-transparent pixel and the
    // graphics data sequencer outputs a foreground pixel in the course of display
    // generation. In this case, the MxD bits of the affected sprites are set in
    // register $d01f and (if allowed, see section 3.12.), an interrupt is
    // generated. As with the sprite-sprite collision, the bits remain set until
    // the register is read by the processor.
    if(fg_enable && (0!=sp_pixel_enable)) begin
        IMCB<= 1;
        R[8'h1f] <= sp_pixel_enable;
    end
end


// 8 sprite instances
generate for(n=0; n < 8; n=n+1) begin : sprites
        vicii_sprite #(.number(n)) sprite(
                         .clk(dot_clk),
                         .reset(reset || !ME[n]),
                         .di(di[7:0]),
                         //.di(8'haa),
                         .VM1(VM1),
                         .Xc(Xc),
                         .Yc(RC[8:0]),
                         .XE(MXE[n]),
                         .YE(MYE[n]),
                         .X(MX[n]),
                         .Y({1'b0,MY[n]}),
                         .SC(MC[n]),
                         .SMC0(MM0),
                         .SMC1(MM1),
                         .MCM(MMC[n]),
                         .ao(sp_ao[n]),
                         .ba(sp_ba[n]),
                         .pixel_enable(sp_pixel_enable[n]),
                         .pixel(sp_pixel[n])
                     );
    end
endgenerate


// Generate the final pixel which is a combination of sprites
// and standard display
wire[3:0] final_pixel =
    sp_pixel_enable[0] && (!MDP[0] >= fg_enable) ? sp_pixel[0] :
    sp_pixel_enable[1] && (!MDP[1] >= fg_enable) ? sp_pixel[1] :
    sp_pixel_enable[2] && (!MDP[2] >= fg_enable) ? sp_pixel[2] :
    sp_pixel_enable[3] && (!MDP[3] >= fg_enable) ? sp_pixel[3] :
    sp_pixel_enable[4] && (!MDP[4] >= fg_enable) ? sp_pixel[4] :
    sp_pixel_enable[5] && (!MDP[5] >= fg_enable) ? sp_pixel[5] :
    sp_pixel_enable[6] && (!MDP[6] >= fg_enable) ? sp_pixel[6] :
    sp_pixel_enable[7] && (!MDP[7] >= fg_enable) ? sp_pixel[7] :
    current_pixel;

//sync signal
wire sync = (HSYNC & !VSYNC) | (VEQ & ((HEQ1 | HEQ2)^VSYNC) );

//Are we in the screen area
wire[3:0] pixel_and_border = (BKDE & VSW & vic_enable) ? final_pixel : EC;

reg[31:0] color_carrier;
always @(posedge color_clock) begin
    if(reset)
        color_carrier <= 32'h0000ffff;
    else
        color_carrier <= {color_carrier[30:0],color_carrier[31]};
end

assign color_out =
       (!VBLANK & BURST) ? (even ? color_carrier[11] : color_carrier[31-11]) :
       (!(HBLANK | VBLANK) & chroma_en ) ? (even ? color_carrier[chroma] : color_carrier[31-chroma]):
       0;


assign sync_lumen = sync ? 0 :
       (HBLANK | VBLANK) ? 19 : (luma + 19) ;

vicii_palette vicii_palette_i (
                  .pixel(pixel_and_border),
                  .luma(luma),
                  .chroma(chroma),
                  .chroma_en(chroma_en)
              );

// Debug dump to file
`ifdef XILINX_SIMULATOR
integer f;
reg [10*8:1]  filename;
reg [23:0]  color_table [15:0];

initial begin

    color_table[0] =  24'h000000; //black
    color_table[1] =  24'hFFFFFF; //white
    color_table[2] =  24'h68372B; //red
    color_table[3] =  24'h70A4B2; //cyan
    color_table[4] =  24'h6F3D86; //purple
    color_table[5] =  24'h588D43; //green
    color_table[6] =  24'h352879; //blue
    color_table[7] =  24'hB8C76F; //yellow
    color_table[8] =  24'h6F4F25; //orange
    color_table[9] =  24'h433900; //brown
    color_table[10] =  24'h9A6759; //light red
    color_table[11] =  24'h444444; //drak gray
    color_table[12] =  24'h6C6C6C; //grey
    color_table[13] =  24'h9AD284; //light green
    color_table[14] =  24'h6C5EB5; //light blue
    color_table[15] =  24'h959595; //light gray
end

always @(posedge dot_clk ) begin
    if(VINC & (RC == 0) & (Xc[2:0]) == 0) begin
        $fclose(f);
        $sformat(filename, "file%0d.ppm", frame);
        $display("New frame %s",filename);
        f = $fopen(filename,"w");
        $fwrite(f,"P3\n");
        $fwrite(f,"504 312\n");
        $fwrite(f,"255\n");
        frame = frame +1;
    end

    if (sp_ba>0)
        $fwrite(f,"0 255 0\n");
    else if( HSYNC | VSYNC)
        $fwrite(f,"255 255 255\n");
    else if (BURST)
        $fwrite(f,"100 0 0\n");
    else if (VBLANK | HBLANK)
        $fwrite(f,"10 10 10\n");
    else begin
        $fwrite(f,"%0d %0d %0d\n",
                color_table[pixel_and_border][23:16],
                color_table[pixel_and_border][15:8],
                color_table[pixel_and_border][7:0]);

    end
end
`endif 

endmodule
