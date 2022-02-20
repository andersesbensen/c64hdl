#include "Vc64.h"
#include "verilated.h"
#include <verilated_vcd_c.h>

#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>
#include <png.h>
#include <queue>

void frame_dump(int HSYNC, int VSYNC, int pixel)
{
    static int last_HSYNC;
    static int last_VSYNC;
    static int Xc;
    static uint8_t pixel_row[512];
    static png_structp png_ptr = 0;
    static FILE *fp;
    static int frame;

    memset(pixel_row, sizeof(pixel_row), 0);
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

    if (!last_VSYNC && VSYNC)
    {
        frame++;
        if (png_ptr)
        {
            png_write_end(png_ptr, NULL);
            fclose(fp);
        }
        std::string filename = "frame_" + std::to_string(frame) + ".png";
        std::cout << filename << "\r";
        std::cout.flush();
        fp = fopen(filename.c_str(), "wb");
        png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
        png_infop info_ptr;
        info_ptr = png_create_info_struct(png_ptr);

        png_init_io(png_ptr, fp);
        png_set_IHDR(png_ptr, info_ptr, 512, 312,
                     8, PNG_COLOR_TYPE_PALETTE, PNG_INTERLACE_NONE,
                     PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
        png_set_PLTE(png_ptr, info_ptr, palette, 16);

        png_write_info(png_ptr, info_ptr);
    }

    if (!last_HSYNC && HSYNC && png_ptr)
    {
        Xc = 0;
        png_write_row(png_ptr, (png_bytep)pixel_row);
    }

    pixel_row[Xc & 0x1ff] = (HSYNC || VSYNC) ? 0 : pixel & 0xf;
    last_HSYNC = HSYNC;
    last_VSYNC = VSYNC;
    Xc++;
}

vluint64_t sim_time = 0;
int main(int argc, char **argv, char **env)
{
    uint8_t cart[1024 * 8];
    bool cart_read = false;
    const char *vcd = nullptr;
    int opt;
    int timeout = 0;

    std::ifstream prg;
    std::deque<std::pair<uint16_t, uint8_t>> dma_in;

    int prg_offset;
    int last_phi;
    while ((opt = getopt(argc, argv, "t:c:d:p:")) != -1)
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
        if (top.debug_status_valid)
        {
            break;
        }

        if (top.dot_clk)
        {
            frame_dump(top.c64__DOT__vicii_e__DOT__HSYNC,
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
                std::cout << top.Ai << "," << (int)top.Di << std::endl;
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

        if (sim_time == 4000000)
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
        if ((timeout > 0) && (sim_time > (timeout * 2)))
        {
            std::cout << "timeout" << std::endl;
            top.debug_status = 1;
            break;
        }
    }
    m_trace.close();

    std::cout << "Exit code " << (int)top.debug_status << std::endl;

    exit(top.debug_status);
}