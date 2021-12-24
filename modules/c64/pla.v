module pla (
           input[15:0] A,
           input _CHAREN,  _HIRAM,  _LORAM,
           input _CAS,
           input VA12, VA13, _VA14,
           input _AEC,  BA,
           input _GAME,  _EXROM,  R__W,
           output ROMH ,ROML, GR_W , CHAROM, KERNAL , BASIC , CASRAM,
           output CIA1,CIA2,SID,VIC,COLOR_RAM,IO1,IO2
       );

wire I_O;
wire A8 = A[8];
wire A9 = A[9];
wire A10 = A[10];
wire A11 = A[11];
wire A12 = A[12];
wire A13 = A[13];
wire A14 = A[14];
wire A15 = A[15];

assign VIC = I_O && !A11 && !A10;
assign SID = I_O && !A11 &&  A10;
assign COLOR_RAM = I_O &&  A11 &&  !A10;

assign CIA1 = I_O && A11 && A10 && !A9 && !A8;
assign CIA2 = I_O && A11 && A10 && !A9 &&  A8;
assign IO1  = I_O && A11 && A10 &&  A9 && !A8;
assign IO2  = I_O && A11 && A10 &&  A9 &&  A8;

// "Created by JED2AHDL ABEL 4.10 on Wed Jul 19 15:37:23 1995
//
//TITLE
//'PLA chip in old version of Commodore 64'
//
//        c64pla device 'f100';
//
//"Device is a Signetics/Mullard/Phillips 82S100


//"Pin and Node Declarations
//          FE,  A13,  A14,  A15               PIN   1, 2, 3, 4;
//          _VA14,  _CHAREN,  _HIRAM,  _LORAM  PIN   5, 6, 7, 8;
//          _CAS,  ROMH,  ROML,  I_O           PIN   9,10,11,12;
//          GR_W,  GND,  CHAROM,  KERNAL       PIN  13,14,15,16;
//          BASIC,  CASRAM,  _OE,  VA12        PIN  17,18,19,20;
//          VA13,  _GAME,  _EXROM,  R__W       PIN  21,22,23,24;
//          _AEC,  BA,  A12,  VCC              PIN  25,26,27,28;
//
//        CASRAM ISTYPE 'Neg';
//        ROMH,ROML,I_O,GR_W,CHAROM,KERNAL,BASIC,CASRAM ISTYPE 'Com';
//        ROMH,ROML,I_O,GR_W,CHAROM,KERNAL,BASIC,CASRAM ISTYPE 'Invert';
//        X,K,Z,C,P,U,D = .X.,.K.,.Z.,.C.,.P.,.U.,.D.;
//EQUATIONS

wire Q7 = (_HIRAM && A15 && !A14 && A13 && !_AEC && R__W && !_EXROM && !_GAME
           || A15 && A14 && A13 && !_AEC && _EXROM && !_GAME
           || _AEC && _EXROM && !_GAME && VA13 && VA12 );

wire Q6 = (_LORAM && _HIRAM && A15 && !A14 && !A13 && !_AEC && R__W && !_EXROM
           || A15 && !A14 && !A13 && !_AEC && _EXROM && !_GAME );

wire Q5 = (_HIRAM && _CHAREN && A15 && A14 && !A13 && A12 && !_AEC && (BA || !R__W) && (!_EXROM || _GAME )
           || _LORAM && _CHAREN && A15 && A14 && !A13 && A12 && !_AEC && (BA || !R__W) && (!_EXROM || _GAME )
           || A15 && A14 && !A13 && A12 && !_AEC && (BA || !R__W ) && _EXROM && !_GAME );

wire Q3 = (_LORAM && !_CHAREN && A15 && A14 && !A13 && A12 && !_AEC && R__W && _GAME
           || _HIRAM && !_CHAREN && A15 && A14 && !A13 && A12 && !_AEC && R__W && (!_EXROM || _GAME )
           || _VA14 && _AEC && _GAME && !VA13 && VA12
           || _VA14 && _AEC && !_EXROM && !_GAME && !VA13 && VA12 );

wire Q2 = (_HIRAM && A15 && A14 && A13 && !_AEC && R__W && (!_EXROM || _GAME ) );

wire Q1 = (_LORAM && _HIRAM && A15 && !A14 && A13 && !_AEC && R__W && _GAME );

assign ROMH = Q7;
assign ROML = Q6;
assign I_O = Q5;
assign GR_W = (!_CAS && A15 && A14 && !A13 && A12 && !_AEC && !R__W );
assign CHAROM = Q3;
assign KERNAL = Q2;
assign BASIC = Q1;
assign CASRAM = !(_CAS || Q1 || Q2 || Q3 || Q5 || Q6 || Q7
                  || _EXROM && !_GAME && !A15 &&  A14
                  || _EXROM && !_GAME && !A15 && !A14 &&  A12
                  || _EXROM && !_GAME && !A15 && !A14 &&  A13
                  || _EXROM && !_GAME &&  A15 && !A14 &&  A13
                  || _EXROM && !_GAME &&  A15 &&  A14 && !A13 && !A12 );
endmodule
