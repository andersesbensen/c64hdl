#include "Vc64.h"
#include "verilated.h"
#include <verilated_vcd_c.h>

#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>
#include <png.h>
#include <queue>

#include <SDL2/SDL.h>


int by_scancode(int scancode);
int by_sdl_scancode(int scancode);

const png_color palette[16] = {
    {0x00, 0x00, 0x00}, // black
    {0xFF, 0xFF, 0xFF}, // white
    {0x68, 0x37, 0x2B}, // red
    {0x70, 0xA4, 0xB2}, // cyan
    {0x6F, 0x3D, 0x86}, // purple
    {0x58, 0x8D, 0x43}, // green
    {0x35, 0x28, 0x79}, // blue
    {0xB8, 0xC7, 0x6F}, // yellow
    {0x6F, 0x4F, 0x25}, // orange
    {0x43, 0x39, 0x00}, // brown
    {0x9A, 0x67, 0x59}, // light red
    {0x44, 0x44, 0x44}, // drak gray
    {0x6C, 0x6C, 0x6C}, // grey
    {0x9A, 0xD2, 0x84}, // light green
    {0x6C, 0x5E, 0xB5}, // light blue
    {0x95, 0x95, 0x95}, // light gray
};


SDL_Texture * screen_texture;
SDL_Renderer * renderer;
static uint8_t screen_buffer[312][512];
uint32_t screen_buffer2[312][504];

vluint64_t sim_time = 0;
int audio_cnt =0;
uint16_t audio_buf[512];
uint8_t key_matrix[8];


void update_screen(int HSYNC, int VSYNC, int pixel) {
    static int Xc;
    static int Yc;
    static int last_HSYNC;
    static int last_VSYNC;
    static uint32_t* sb = (uint32_t*)screen_buffer2;
    if (!last_HSYNC && HSYNC)
    {
        Xc = 0;
        Yc++;
    }

    if (!last_VSYNC && VSYNC) {
        Yc =0;
        sb = (uint32_t*)screen_buffer2;
        SDL_UpdateTexture(screen_texture, NULL, sb, 504 * sizeof(int32_t));
        SDL_RenderCopy(renderer, screen_texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    uint8_t p = (HSYNC || VSYNC) ? 0 : pixel & 0xf;
    screen_buffer[Yc][Xc & 0x1ff] = p;
    const png_color* c = &palette[p];
    *sb++ = (c->red<<24) | (c->green<<16) | (c->blue<<8) | 0xff;

    last_HSYNC = HSYNC;
    last_VSYNC = VSYNC;
    Xc++;

}

void screen_dump(const char* filename)
{
    
    png_structp png_ptr;
    FILE *fp;

    fp = fopen(filename, "wb");
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    png_infop info_ptr;
    info_ptr = png_create_info_struct(png_ptr);

    png_init_io(png_ptr, fp);
    png_set_IHDR(png_ptr, info_ptr, 512, 312,
                    8, PNG_COLOR_TYPE_PALETTE, PNG_INTERLACE_NONE,
                    PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
    png_set_PLTE(png_ptr, info_ptr, palette, 16);
    png_write_info(png_ptr, info_ptr);

    for(int r=0; r < 312; r++) {
        png_write_row(png_ptr, (png_bytep)screen_buffer[r]);
    }

    png_write_end(png_ptr, NULL);
    fclose(fp);
}

void mixaudio(void *unused, Uint8 *stream, int len) {
    memcpy(stream,audio_buf,len);
    audio_cnt=0;
    SDL_Event e;
    e.type = SDL_USEREVENT;
    SDL_PushEvent( &e );

}

void
c64_key_press(int key, int state)
{
  if(key < 64) {
    if(state) {
      key_matrix[key /8] |= (1<<(key & 7));
    } else {
      key_matrix[key / 8] &= ~(1<<(key & 7));
    }
  }
}

void
c64_joy_press(uint8_t& joystick, int key, int state) {

  if(key<0 || key>4) return;
  if(state) {
    joystick |= 1<<key;
  } else {
    joystick &= ~(1<<key);
  }
}

int main(int argc, char **argv, char **env)
{
    uint8_t cart[1024 * 8];
    bool cart_read = false;
    const char *vcd = nullptr;
    const char *exit_snapshot = nullptr;
    int opt;
    int timeout = 0;

    std::ifstream prg;
    std::deque<std::pair<uint16_t, uint8_t>> dma_in;

    int prg_offset;
    int last_phi;
    while ((opt = getopt(argc, argv, "t:c:d:p:s:")) != -1)
    {
        switch (opt)
        {
        case 'p':
            prg.open(optarg, std::ios_base::binary);
            uint8_t offset_hi;
            uint8_t offset_lo;
            prg >> offset_lo >> offset_hi;
            prg_offset = (offset_hi << 8) | offset_lo;
            std::cout << "Loading prg to address: "<< std::hex << prg_offset << std::endl;
            break;
        case 'c':
        {
            std::ifstream cart_rom(optarg);
            if (cart_rom.is_open())
            {
                std::cout << "Reading cartrige " << optarg << std::endl;
                cart_rom.read((char *)cart, sizeof(cart));
                cart_read = true;
            }
            else
            {
                exit(1);
            }
        }
        break;
        case 's':
            exit_snapshot = optarg;
            break;
        case 'd':
            vcd = optarg;
            break;
        case 't':
            timeout = atoi(optarg);
            break;

        default: /* '?' */
        {
            fprintf(stderr, "Usage: %s [-t nsecs] [-n] name\n",
                    argv[0]);
            exit(EXIT_FAILURE);
            break;
        }
        }
    }
    Verilated::commandArgs(argc, argv);
    Vc64 top;
    VerilatedVcdC m_trace;



    SDL_Init(SDL_INIT_VIDEO);

    SDL_AudioSpec fmt;
    /* Set 16-bit stereo audio at 22Khz */
    fmt.freq = 11025;
    fmt.format = AUDIO_S16;
    fmt.channels = 1;
    fmt.samples = 512;        /* A good value for games */
    fmt.callback = mixaudio;
    fmt.userdata = NULL;

    /* Open the audio device and start playing sound! */
    SDL_OpenAudio(&fmt, NULL) ;

    SDL_Window * window = SDL_CreateWindow("c64hdl",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        504, 312,
        0);

    // Create a renderer with V-Sync enabled.
    renderer = SDL_CreateRenderer(window,
        -1, SDL_RENDERER_PRESENTVSYNC);

    // Create a streaming texture of size 320 x 240.
    screen_texture = SDL_CreateTexture(renderer,
        SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING,
        504, 312);

    if (vcd)
    {
        Verilated::traceEverOn(true);
        top.trace(&m_trace, 5);
        m_trace.open(vcd);
    }

    top.cass_rd = 1;
    top.cass_sense = 1;
    top.INTRES = 0;
    top.NMI = 0;
    top.IRQ = 0;
    top.DMA = 0;
    top.RW = 0;
    top.Di = 0;
    top.EXTROM_n = !cart_read;
    top.GAME_n = 1;
    top.Ai = 0;
    top.joy_a = 0xff;
    top.joy_b = 0xff;
    top.serial_data_i = 1;
    top.serial_clock_i = 1;

    top.reset = 1;
    for (int i = 0; i < 8; i++)
    {
        top.dot_clk ^= 1;
        top.eval();
    }
    top.reset = 0;

    SDL_PauseAudio(0);

    while (!Verilated::gotFinish())
    {
        if (vcd)
        {
            m_trace.dump(sim_time);
        }
        top.dot_clk ^= 1;

        if (top.ROML)
        {
            top.Di = cart[top.Ao & 0x1fff];
        }
        /*if (top.debug_status_valid)
        {
            break;
        }*/

        if (top.dot_clk)
        {
            update_screen(top.c64__DOT__vicii_e__DOT__HSYNC,
                       top.c64__DOT__vicii_e__DOT__VSYNC,
                       top.c64__DOT__vicii_e__DOT__pixel_out);
        }
        
        if (last_phi && !top.phi2 && !top.BA)
        {
            if (dma_in.size()!=0)
            {
                auto c = dma_in.front();
                top.Ai = c.first;
                top.Di = c.second;
                //std::cout << top.Ai << "," << (int)top.Di << std::endl;
                top.DMA = 1;
                top.RW = 1;
                dma_in.pop_front();
            }
            else
            {
                top.RW = 0;
                top.DMA = 0;
            }
        }
        last_phi = top.phi2;

        if (prg.is_open() && (sim_time == 4000000))
        {
            prg.seekg(0, std::ios::end);
            size_t length = prg.tellg()-2;
            prg.seekg(2, std::ios::beg);

            char* data = new char[length];
            prg.read(data,length);
            for(int i=0; i < length; i++) {
                dma_in.push_back(std::make_pair(prg_offset++, data[i]));
            }
            delete[] data;

            //Type run
            dma_in.push_back(std::make_pair(631, 'R'));
            dma_in.push_back(std::make_pair(632, 'U'));
            dma_in.push_back(std::make_pair(633, 'N'));
            dma_in.push_back(std::make_pair(634, '\r'));
            dma_in.push_back(std::make_pair(198, 4));
        }
 
        top.eval();
        sim_time++;
        if ((timeout > 0) && (sim_time > (timeout * 2*8)))
        {
            std::cout << "timeout" << std::endl;
            top.debug_status = 1;
            break;
        }

        int key = 0xff;
        for(int i=0; i < 8; i++) {
            if( (top.keyboard_ROW & (1<<i)) == 0) {
            key &= ~key_matrix[i];
            }
        }
        top.keyboard_COL = key;

        //Chekc if we should quit
        if((sim_time & 0x3ff) == 0) {
            SDL_Event event;
            if (SDL_PollEvent(&event)) {  // poll until all events are handled!
                if(event.type == SDL_QUIT) {
                    std::cout << "Stopped" << std::endl;
                    top.debug_status = 2;
                    break;
                } else if((event.type == SDL_KEYDOWN) || (event.type == SDL_KEYUP) ) {
                    bool state = event.type == SDL_KEYDOWN;

                    switch (event.key.keysym.scancode)
                    {
                    case SDL_SCANCODE_KP_8: c64_joy_press(top.joy_b,0,state); break;
                    case SDL_SCANCODE_KP_6: c64_joy_press(top.joy_b,1,state); break;
                    case SDL_SCANCODE_KP_4: c64_joy_press(top.joy_b,2,state); break;
                    case SDL_SCANCODE_KP_2: c64_joy_press(top.joy_b,3,state); break;
                    case SDL_SCANCODE_KP_ENTER: c64_joy_press(top.joy_b,3,state);
                    default:
                        c64_key_press( by_sdl_scancode(event.key.keysym.scancode),state );
                        break;
                    }
                } 
            }

            if(audio_cnt < 512) {
                audio_buf[audio_cnt++] = top.audio<<3;
            } else {
                while( SDL_WaitEvent( &event )) {
                    if(event.type == SDL_USEREVENT) break;
                }
            }
        }
    }
    SDL_CloseAudio();

    m_trace.close();

    if(exit_snapshot) {
        screen_dump(exit_snapshot);
    }
    std::cout << "Exit code " << (int)top.debug_status << std::endl;

    exit(top.debug_status);
}