// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/*
 * keyboard.cpp
 *
 *  Created on: Mar 4, 2017
 *      Author: aes
 */

#include <SDL2/SDL.h>
#include <iostream>
typedef struct {
    uint32_t ibm;
    uint32_t ps1_make, ps1_break;
    uint32_t ps2_make, ps2_break;
    uint32_t ps3_make, ps3_break;
    const char* base_case;
    const char* upper_case;
} key_map_t;

const key_map_t key_map[] = {
{ 1           , 0x29, 0xA9                   , 0x0E, 0xF00E                      , 0x0E, 0xF00E             ,"`            ","~          " },
{ 2           , 0x02, 0x82                   , 0x16, 0xF016                      , 0x16, 0xF016             ,"1            ","!          " },
{ 3           , 0x03, 0x83                   , 0x1E, 0xF01E                      , 0x1E, 0xF01E             ,"2            ","@          " },
{ 4           , 0x04, 0x84                   , 0x26, 0xF026                      , 0x26, 0xF026             ,"3            ","#          " },
{ 5           , 0x05, 0x85                   , 0x25, 0xF025                      , 0x25, 0xF025             ,"4            ","$          " },
{ 6           , 0x06, 0x86                   , 0x2E, 0xF02E                      , 0x2E, 0xF02E             ,"5            ","%          " },
{ 7           , 0x07, 0x87                   , 0x36, 0xF036                      , 0x36, 0xF036             ,"6            ","^          " },
{ 8           , 0x08, 0x88                   , 0x3D, 0xF03D                      , 0x3D, 0xF03D             ,"7            ","&          " },
{ 9           , 0x09, 0x89                   , 0x3E, 0xF03E                      , 0x3E, 0xF03E             ,"8            ","*          " },
{ 10          , 0x0A, 0x8A                   , 0x46, 0xF046                      , 0x46, 0xF046             ,"9            ","(          " },
{ 11          , 0x0B, 0x8B                   , 0x45, 0xF045                      , 0x45, 0xF045             ,"0            ",")          " },
{ 12          , 0x0C, 0x8C                   , 0x4E, 0xF04E                      , 0x4E, 0xF04E             ,"-            ","_          " },
{ 13          , 0x0D, 0x8D                   , 0x55, 0xF055                      , 0x55, 0xF055             ,"=            ","+          " },
{ 15          , 0x0E, 0x8E                   , 0x66, 0xF066                      , 0x66, 0xF066             ,"Backspace    ","           " },
{ 16          , 0x0F, 0x8F                   , 0x0D, 0xF00D                      , 0x0D, 0xF00D             ,"Tab          ","           " },
{ 17          , 0x10, 0x90                   , 0x15, 0xF015                      , 0x15, 0xF015             ,"q            ","Q          " },
{ 18          , 0x11, 0x91                   , 0x1D, 0xF01D                      , 0x1D, 0xF01D             ,"w            ","W          " },
{ 19          , 0x12, 0x92                   , 0x24, 0xF024                      , 0x24, 0xF024             ,"e            ","E          " },
{ 20          , 0x13, 0x93                   , 0x2D, 0xF02D                      , 0x2D, 0xF02D             ,"r            ","R          " },
{ 21          , 0x14, 0x94                   , 0x2C, 0xF02C                      , 0x2C, 0xF02C             ,"t            ","T          " },
{ 22          , 0x15, 0x95                   , 0x35, 0xF035                      , 0x35, 0xF035             ,"y            ","Y          " },
{ 23          , 0x16, 0x96                   , 0x3C, 0xF03C                      , 0x3C, 0xF03C             ,"u            ","U          " },
{ 24          , 0x17, 0x97                   , 0x43, 0xF043                      , 0x43, 0xF043             ,"i            ","I          " },
{ 25          , 0x18, 0x98                   , 0x44, 0xF044                      , 0x44, 0xF044             ,"o            ","O          " },
{ 26          , 0x19, 0x99                   , 0x4D, 0xF04D                      , 0x4D, 0xF04D             ,"p            ","P          " },
{ 27          , 0x1A, 0x9A                   , 0x54, 0xF054                      , 0x54, 0xF054             ,"[            ","{          " },
{ 28          , 0x1B, 0x9B                   , 0x5B, 0xF05B                      , 0x5B, 0xF05B             ,"]            ","}          " },
{ 30          , 0x3A, 0xBA                   , 0x58, 0xF058                      , 0x58, 0xF058             ,"Caps Lock    ","           " },
{ 31          , 0x1E, 0x9E                   , 0x1C, 0xF01C                      , 0x1C, 0xF01C             ,"a            ","A          " },
{ 32          , 0x1F, 0x9F                   , 0x1B, 0xF01B                      , 0x1B, 0xF01B             ,"s            ","S          " },
{ 33          , 0x20, 0xA0                   , 0x23, 0xF023                      , 0x23, 0xF023             ,"d            ","D          " },
{ 34          , 0x21, 0xA1                   , 0x2B, 0xF02B                      , 0x2B, 0xF02B             ,"f            ","F          " },
{ 35          , 0x22, 0xA2                   , 0x34, 0xF034                      , 0x34, 0xF034             ,"g            ","G          " },
{ 36          , 0x23, 0xA3                   , 0x33, 0xF033                      , 0x33, 0xF033             ,"h            ","H          " },
{ 37          , 0x24, 0xA4                   , 0x3B, 0xF03B                      , 0x3B, 0xF03B             ,"j            ","J          " },
{ 38          , 0x25, 0xA5                   , 0x42, 0xF042                      , 0x42, 0xF042             ,"k            ","K          " },
{ 39          , 0x26, 0xA6                   , 0x4B, 0xF04B                      , 0x4B, 0xF04B             ,"l            ","L          " },
{ 40          , 0x27, 0xA7                   , 0x4C, 0xF04C                      , 0x4C, 0xF04C             ,";            ",":          " },
{ 41          , 0x28, 0xA8                   , 0x52, 0xF052                      , 0x52, 0xF052             ,"'            ","\"          " },
{ 43          , 0x1C, 0x9C                   , 0x5A, 0xF05A                      , 0x5A, 0xF05A             ,"Enter        ","Enter      " },
{ 44          , 0x2A, 0xAA                   , 0x12, 0xF012                      , 0x12, 0xF012             ,"Left Shift   ","           " },
{ 46          , 0x2C, 0xAC                   , 0x1A, 0xF01A                      , 0x1A, 0xF01A             ,"z            ","Z          " },
{ 47          , 0x2D, 0xAD                   , 0x22, 0xF022                      , 0x22, 0xF022             ,"x            ","X          " },
{ 48          , 0x2E, 0xAE                   , 0x21, 0xF021                      , 0x21, 0xF021             ,"c            ","C          " },
{ 49          , 0x2F, 0xAF                   , 0x2A, 0xF02A                      , 0x2A, 0xF02A             ,"v            ","V          " },
{ 50          , 0x30, 0xB0                   , 0x32, 0xF032                      , 0x32, 0xF032             ,"b            ","B          " },
{ 51          , 0x31, 0xB1                   , 0x31, 0xF031                      , 0x31, 0xF031             ,"n            ","N          " },
{ 52          , 0x32, 0xB2                   , 0x3A, 0xF03A                      , 0x3A, 0xF03A             ,"m            ","M          " },
{ 53          , 0x33, 0xB3                   , 0x41, 0xF041                      , 0x41, 0xF041             ,"\"           ","<          " },
{ 54          , 0x34, 0xB4                   , 0x49, 0xF049                      , 0x49, 0xF049             ,".            ",">          " },
{ 55          , 0x35, 0xB5                   , 0x4A, 0xF04A                      , 0x4A, 0xF04A             ,"/            ","?          " },
{ 57          , 0x36, 0xB6                   , 0x59, 0xF059                      , 0x59, 0xF059             ,"Right Shift  ","           " },
{ 58          , 0x1D, 0x9D                   , 0x14, 0xF014                      , 0x11, 0xF011             ,"Left Ctrl    ","           " },
{ 60          , 0x38, 0xB8                   , 0x11, 0xF011                      , 0x19, 0xF019             ,"Left Alt     ","           " },
{ 61          , 0x39, 0xB9                   , 0x29, 0xF029                      , 0x29, 0xF029             ,"Spacebar     ","           " },
{ 62          , 0xE038, 0xE0B8             , 0xE011, 0xE0F011                , 0x39, 0xF039             ,"Right Alt    ","           " },
{ 64          , 0xE01D, 0xE09D             , 0xE014, 0xE0F014                , 0x58, 0xF058             ,"Right Ctrl   ","           " },
{ 75          , 0xE052, 0xE0D2             , 0xE070, 0xE0F070                , 0x67, 0xF067             ,"Insert       ","           " },
{ 76          , 0xE04B, 0xE0CB             , 0xE071, 0xE0F071                , 0x64, 0xF064             ,"Delete       ","           " },
{ 79          , 0xE04B, 0xE0CB             , 0xE06B, 0xE0F06B                , 0x61, 0xF061             ,"Left Arrow   ","           " },
{ 80          , 0xE047, 0xE0C7             , 0xE06C, 0xE0F06C                , 0x6E, 0xF06E             ,"Home         ","           " },
{ 81          , 0xE04F, 0xE0CF             , 0xE069, 0xE0F069                , 0x65, 0xF065             ,"End          ","           " },
{ 83          , 0xE048, 0xE0C8             , 0xE075, 0xE0F075                , 0x63, 0xF063             ,"Up Arrow     ","           " },
{ 84          , 0xE050, 0xE0D0             , 0xE072, 0xE0F072                , 0x60, 0xF060             ,"Down Arrow   ","           " },
{ 85          , 0xE049, 0xE0C9             , 0xE07D, 0xE0F07D                , 0x6F, 0xF06F             ,"Page Up      ","           " },
{ 86          , 0xE051, 0xE0D1             , 0xE07A, 0xE0F07A                , 0x6D, 0xF06D             ,"Page Down    ","           " },
{ 89          , 0xE04D, 0xE0CD             , 0xE074, 0xE0F074                , 0x6A, 0xF06A             ,"Right Arrow  ","           " },
{ 90          , 0x45, 0xC5                   , 0x77, 0xF077                      , 0x76, 0xF076             ,"Num Lock     ","           " },
{ 91          , 0x47, 0xC7                   , 0x6C, 0xF06C                      , 0x6C, 0xF06C             ,"Keypad 7     ","           " },
{ 92          , 0x4B, 0xCB                   , 0x6B, 0xF06B                      , 0x6B, 0xF06B             ,"Keypad 4     ","           " },
{ 93          , 0x4F, 0xCF                   , 0x69, 0xF069                      , 0x69, 0xF069             ,"Keypad 1     ","           " },
{ 95          , 0xE035, 0xE0B5             , 0xE04A, 0xE0F04A                , 0x77, 0xF077             ,"Keypad /     ","           " },
{ 96          , 0x48, 0xC8                   , 0x75, 0xF075                      , 0x75, 0xF075             ,"Keypad 8     ","           " },
{ 97          , 0x4C, 0xCC                   , 0x73, 0xF073                      , 0x73, 0xF073             ,"Keypad 5     ","           " },
{ 98          , 0x50, 0xD0                   , 0x72, 0xF072                      , 0x72, 0xF072             ,"Keypad 2     ","           " },
{ 99          , 0x52, 0xD2                   , 0x70, 0xF070                      , 0x70, 0xF070             ,"Keypad 0     ","           " },
{ 100         , 0x37, 0xB7                   , 0x7C, 0xF07C                      , 0x7E, 0xF07E             ,"Keypad *     ","           " },
{ 101         , 0x49, 0xC9                   , 0x7D, 0xF07D                      , 0x7D, 0xF07D             ,"Keypad 9     ","           " },
{ 102         , 0x4D, 0xCD                   , 0x74, 0xF074                      , 0x74, 0xF074             ,"Keypad 6     ","           " },
{ 103         , 0x51, 0xD1                   , 0x7A, 0xF07A                      , 0x7A, 0xF07A             ,"Keypad 3     ","           " },
{ 104         , 0x53, 0xD3                   , 0x71, 0xF071                      , 0x71, 0xF071             ,"Keypad .     ","           " },
{ 105         , 0x4A, 0xCA                   , 0x7B, 0xF07B                      , 0x84, 0xF084             ,"Keypad -     ","           " },
{ 106         , 0x4E, 0xCE                   , 0x79, 0xF079                      , 0x7C, 0xF07C             ,"Keypad +     ","           " },
{ 108         , 0xE01C, 0xE09C             , 0xE05A, 0xE0F05A                , 0x79, 0xF079             ,"Keypad Enter ","           " },
{ 110         , 0x01, 0x81                   , 0x76, 0xF076                      , 0x08, 0xF008             ,"Esc          ","           " },
{ 112         , 0x3B, 0xBB                   , 0x05, 0xF005                      , 0x07, 0xF007             ,"F1           ","           " },
{ 113         , 0x3C, 0xBC                   , 0x06, 0xF006                      , 0x0F, 0xF00F             ,"F2           ","           " },
{ 114         , 0x3D, 0xBD                   , 0x04, 0xF004                      , 0x17, 0xF017             ,"F3           ","           " },
{ 115         , 0x3E, 0xBE                   , 0x0C, 0xF00C                      , 0x1F, 0xF01F             ,"F4           ","           " },
{ 116         , 0x3F, 0xBF                   , 0x03, 0xF003                      , 0x27, 0xF027             ,"F5           ","           " },
{ 117         , 0x40, 0xC0                   , 0x0B, 0xF00B                      , 0x2F, 0xF02F             ,"F6           ","           " },
{ 118         , 0x41, 0xC1                   , 0x83, 0xF083                      , 0x37, 0xF037             ,"F7           ","           " },
{ 119         , 0x42, 0xC2                   , 0x0A, 0xF00A                      , 0x3F, 0xF03F             ,"F8           ","           " },
{ 120         , 0x43, 0xC3                   , 0x01, 0xF001                      , 0x47, 0xF047             ,"F9           ","           " },
{ 121         , 0x44, 0xC4                   , 0x09, 0xF009                      , 0x4F, 0xF04F             ,"F10          ","           " },
{ 122         , 0x57, 0xD7                   , 0x78, 0xF078                      , 0x56, 0xF056             ,"F11          ","           " },
{ 123         , 0x58, 0xD8                   , 0x07, 0xF007                      , 0x5E, 0xF05E             ,"F12          ","           " },
//{ 124         , 0xE02AE037, 0xE0B7E0AA , 0xE012E07C, 0xE0F07CE0F012 , 0x57, 0xF057             ,"Print Screen ","           " },
{ 125         , 0x46, 0xC6                   , 0x7E, 0xF07E                      , 0x5F, 0xF05F             ,"Scroll Lock  ","           " },
{ 126         , 0xE11D45, 0xE19DC5       , 0xE11477E1, 0xF014F077       , 0x62, 0xF062             ,"Pause Break  ","           " },
{ 29    , 0x2B, 0xAB                   , 0x5D, 0xF05D                      , 0x5C, 0xF05C ,"\\            ","           " },
{}
};


/*
 Insert/Delete Return  cursor left/right F7  F1  F3  F5  cursor up/down
 3 W A 4 Z S E left Shift
 5 R D 6 C F T X
 7 Y G 8 B H U V
 9 I J 0 M K O N
 + (plus)  P L – (minus) . (period)  : (colon) @ (at)  , (comma)
 £ (pound) * (asterisk)  ; (semicolon) Clear/Home  right Shift (Shift Lock)  = (equal) ↑ (up arrow)  / (slash)
 1 ← (left arrow)  Control 2 Space Commodore Q Run/Stop
 */

int by_scancode(int scancode)
{
  int i=0; 
  while(key_map[i].ibm) {
    if(key_map[i].ps1_make == scancode) {
      scancode = key_map[i].ps2_make; 
      break;
    }
    i++;
  }
  
  switch (scancode)
  {
    //row 0
  case 0x66:
    return 000; //Backspace
  case 0x5A:
    return 001; //Return
  case 0x6B:
    return 002; //cursor left/right
  case 0x83:
    return 003; //F7
  case 0x05:
    return 004; //F1
  case 0x04:
    return 005; //F3
  case 0x03:
    return 006; //F5
  case 0x72:
    return 007; //up/down
  //row 1
  case 0x26:
    return 010; //3
  case 0x1d:
    return 011; //w
  case 0x1c:
    std::cout << " A press" << std::endl;
    return 012; //a
  case 0x25:
    return 013; //4
  case 0x1a:
    return 014; //z
  case 0x1b:
    return 015; //s
  case 0x24:
    return 016; //e
  case 0x12:
    return 017; //left shift
  //row2
  case 0x2e:
    return 020; //5
  case 0x2d:
    return 021; //R
  case 0x23:
    return 022; //D
  case 0x36:
    return 023; //6
  case 0x21:
    return 024; //C
  case 0x2b:
    return 025; //F
  case 0x2c:
    return 026; //T
  case 0x22:
    return 027; //X

  //row3
  case 0x3d:
    return 030; //7
  case 0x35:
    return 031; //Y
  case 0x34:
    return 032; //G
  case 0x3e:
    return 033; //8
  case 0x32:
    return 034; //B
  case 0x33:
    return 035; //H
  case 0x3c:
    return 036; //U
  case 0x2a:
    return 037; //V

  //row4
  case 0x46:
    return 040; //9
  case 0x43:
    return 041; //I
  case 0x3B:
    return 042; //J
  case 0x45:
    return 043; //0
  case 0x3A:
    return 044; //M
  case 0x42:
    return 045; //K
  case 0x44:
    return 046; //O
  case 0x31:
    return 047; //N

  //row5
  case 0x79:
    return 050; //+
  case 0x4D:
    return 051; //P
  case 0x4B:
    return 052; //L
  case 0x7B:
    return 053; //-
  case 0x71:
    return 054; //.
  case 0xe04c:
    return 055; //:
  case 0x52:
    return 056; //@
  case 0x41:
    return 057; //,

  //row6
  case 0x0e:
    return 060; //$
  case 0x5D:
    return 061; //
  case 0x4C:
    return 062; //;
  case 0xe06C:
    return 063; // Clear/Home
  case 0x59:
    return 064; // Right shift
  case 0x55:
    return 065; // =
  case 0xe075:
    return 066; // Up arrow
  case 0xe0a4:
    return 067; // slash

  //row7
  case 0x16:
    return 070; // 1
  case 0xe06b:
    return 071; // (left arrow)
  case 0x14:
    return 072; // (Control)
  case 0x1e:
    return 073; // 2
  case 0x29:
    return 074; // space
  case 0xe026:
    return 075; // Commodore
  case 0x15:
    return 076; // Q
  case 0x76:
    return 077; // Run stop
  default:
    return 000;
  }

}

int by_sdl_scancode(int keycode)
{
  //printf("Key %x\n", keycode);
  //return by_scancode(keycode);
  switch (keycode)
  {
  //row 0
  case SDL_SCANCODE_BACKSPACE: //Insert/Delete
    return 000;
  case SDL_SCANCODE_RETURN: //Return
    return 001;
  case SDL_SCANCODE_RIGHT: //cursor left/right
    return 002;
  case SDL_SCANCODE_F7: //F7
    return 003;
  case SDL_SCANCODE_F1: //F1
    return 004;
  case SDL_SCANCODE_F3: //F3
    return 005;
  case SDL_SCANCODE_F5: //F5
    return 006;
  case SDL_SCANCODE_UP: //cursor up/down
    return 007;
  //row1
  case SDL_SCANCODE_3:
    return 010;
  case SDL_SCANCODE_W:
    return 011;
  case SDL_SCANCODE_A:
    return 012;
  case SDL_SCANCODE_4:
    return 013;
  case SDL_SCANCODE_Z:
    return 014;
  case SDL_SCANCODE_S:
    return 015;
  case SDL_SCANCODE_E:
    return 016;
  case SDL_SCANCODE_LSHIFT: // left shift
    return 017;
    //row2
  case SDL_SCANCODE_5:
    return 020;
  case SDL_SCANCODE_R:
    return 021;
  case SDL_SCANCODE_D:
    return 022;
  case SDL_SCANCODE_6:
    return 023;
  case SDL_SCANCODE_C:
    return 024;
  case SDL_SCANCODE_F:
    return 025;
  case SDL_SCANCODE_T:
    return 026;
  case SDL_SCANCODE_X:
    return 027;

    //row3
  case SDL_SCANCODE_7:
    return 030;
  case SDL_SCANCODE_Y:
    return 031;
  case SDL_SCANCODE_G:
    return 032;
  case SDL_SCANCODE_8:
    return 033;
  case SDL_SCANCODE_B:
    return 034;
  case SDL_SCANCODE_H:
    return 035;
  case SDL_SCANCODE_U:
    return 036;
  case SDL_SCANCODE_V:
    return 037;

    //row4
  case SDL_SCANCODE_9:
    return 040;
  case SDL_SCANCODE_I:
    return 041;
  case SDL_SCANCODE_J:
    return 042;
  case SDL_SCANCODE_0:
    return 043;
  case SDL_SCANCODE_M:
    return 044;
  case SDL_SCANCODE_K:
    return 045;
  case SDL_SCANCODE_O:
    return 046;
  case SDL_SCANCODE_N:
    return 047;

    //row5
  case SDL_SCANCODE_KP_PLUS: //(plus)
    return 050;
  case SDL_SCANCODE_P:
    return 051;
  case SDL_SCANCODE_L:
    return 052;
  case SDL_SCANCODE_KP_MINUS: //(minus)
    return 053;
  case SDL_SCANCODE_PERIOD: //(period)
    return 054;
  case SDL_SCANCODE_COMPUTER: //(colon)
    return 055;
  case SDL_SCANCODE_KP_AT: //(at)
    return 056;
  case SDL_SCANCODE_COMMA: // comma
    return 057;

    //row6
  case SDL_SCANCODE_TAB: //(pound)
    return 060;
  case SDL_SCANCODE_KP_DIVIDE: //asterisk
    return 061;
  case SDL_SCANCODE_SEMICOLON: // (semicolon)
    return 062;
  case SDL_SCANCODE_ESCAPE: //( Clear/Home )
    return 063;
  case SDL_SCANCODE_CAPSLOCK: // //right Shift (Shift Lock)
    return 064;
  case SDL_SCANCODE_EQUALS: //(equal)
    return 065;
  case SDLK_PAGEUP: //(up arrow)
    return 066;
  case SDL_SCANCODE_SLASH: // (slash)
    return 067;

    //row7
  case SDL_SCANCODE_1: //
    return 070;
  case SDL_SCANCODE_LEFT: // (left arrow)
    return 071;
  case SDL_SCANCODE_LCTRL: // (Control)
    return 072;
  case SDL_SCANCODE_2: //
    return 073;
  case SDL_SCANCODE_SPACE: // Space
    return 074;
  case SDL_SCANCODE_APP1: //(Commodore)
    return 075;
  case SDL_SCANCODE_Q:
    return 076;
  case SDL_SCANCODE_APP2: // (Run/Stop)
    return 077;
  default:
    return 0xFF;
  }
}
