/*
Copyright 2015-2017 University of Cambridge
Copyright and related rights are licensed under the Solderpad Hardware
License, Version 0.51 (the “License”); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
or agreed to in writing, software, hardware and materials distributed under
this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
*/

// A simple monitor (LCD display) driver with glass TTY behaviour in text mode

module fstore2(
               input wire             pixel2_clk,
               output reg [7:0]  red,
               output reg [7:0]  green,
               output reg [7:0]  blue,

               output wire [11:0]     DVI_D,
               output wire            DVI_DE,
               output wire            DVI_H,
               output wire            DVI_V,
               output wire            DVI_XCLK_N,
               output wire            DVI_XCLK_P,

               output wire            vsyn,
               output reg        hsyn,
               output reg        blank,

               output wire [63:0] doutb,
               input wire  [63:0]  dinb,
               input wire  [11:0] addrb,
               input wire  [7:0] web,
               input wire        enb,
               input wire        clk_data,
               input wire        irst
               );

   parameter rwidth = 14;

   wire                          m0 = 1'b0;
   wire                          dvi_mux;
   assign DVI_XCLK_P = !dvi_mux;  // Chrontel defaults to clock doubling mode
   assign DVI_XCLK_N = dvi_mux;   // where both edges of this mark a 12-bit word.
   //assign DVI_RESET_B = !dvi_reset;

   assign DVI_D[11:8] = (m0 || blank) ? 4'h0 : (dvi_mux) ? red[7:4]: green[3:0];
   assign DVI_D[7:4]  = (m0 || blank) ? 4'h0 : (dvi_mux) ? red[3:0]: blue[7:4];
   assign DVI_D[3:0]  = (m0 || blank) ? 4'h0 : (dvi_mux) ? green[7:4]: blue[3:0];
   assign DVI_H = hsyn;      
   assign DVI_V = vsyn;

   assign DVI_DE = !blank;
   
   reg                           vblank;

   reg                           hstart, hstop, vstart, vstop;
   reg [12:6]                    offhreg;
   reg [5:3]                     offpixel;
   reg [11:5]                    offvreg,scrollv;
   reg [4:1]                     vrow;
   reg [4:0]                     scroll;
   reg [6:0]                     xcursor, ycursor, xcursor0, ycursor0, cursorvreg;
   reg [11:0]                    hstartreg, hsynreg, hstopreg, vstartreg,
                                 vstopreg, vblankstopreg, vblankstartreg, vpixstartreg,
                                 vpixstopreg, hpixstartreg, hpixstopreg, hpixreg, vpixreg;
   wire [63:0]                   dout;
   wire [12:0]                   addra = {offvreg[9:5],offhreg[12:6]};
   wire [15:0]                   dout16 = dout >> {addra[1:0],4'b0000};
   wire                          cursor = (offvreg[9:5] == ycursor[6:0]) && (offhreg[12:6] == xcursor[6:0]) && (vrow==cursorvreg);
   
   // 100 MHz / 2100 is 47.6kHz.  Divide by further 788 to get 60.4 Hz.
   // Aim for 1024x768 non interlaced at 60 Hz.  
   
   reg [11:0]                    hreg, vreg;

   reg                           bitmapped_pixel;
   
   reg [7:0]                    red_in, green_in, blue_in;

   assign dvi_mux = hreg[0];

   dualmem ram1(.clka(pixel2_clk),
                .dina(8'b0), .addra(addra[12:2]), .wea(8'b0), .douta(dout), .ena(1'b1),
                .clkb(~clk_data), .dinb(dinb), .addrb(addrb[10:0]), .web(web), .doutb(doutb), .enb(enb&~addrb[11]));

   always @(posedge clk_data)
   if (irst)
     begin
        scrollv <= 0;
        cursorvreg <= 10;
        xcursor0 <= 0;
        ycursor0 <= 32;
        hstartreg <= 2048;
        hsynreg <= 2048+20;
        hstopreg <= 2100-1;
        vstartreg <= 768;
        vstopreg <= 768+19;
        vblankstopreg <= 16;
        vblankstartreg <= 768+16;
        vpixstartreg <= 16;
        vpixstopreg <= 16+768;
        hpixstartreg <= 128*3;
        hpixstopreg <= 128*3+256*6;
        hpixreg <= 5;
        vpixreg <= 11;
     end
   else
     begin
        if (web && enb && addrb[11])
          casez (addrb[4:0])
            5'd0: scrollv <= dinb[6:0];
//            5'd1: cursorvreg <= dinb[6:0];
            5'd2: xcursor0 <= dinb[6:0];
            5'd3: ycursor0 <= dinb[6:0];
//            5'd4: hstartreg <= dinb[11:0];
//            5'd5: hsynreg <= dinb[11:0];
//            5'd6: hstopreg <= dinb[11:0];
//            5'd7: vstartreg <= dinb[11:0];
//            5'd8: vstopreg <= dinb[11:0];
//            5'd9: vblankstopreg <= dinb[11:0];
//            5'd10: vblankstartreg <= dinb[11:0];
//            5'd11: vpixstartreg <= dinb[11:0];
//            5'd12: vpixstopreg <= dinb[11:0];
//            5'd13: hpixstartreg <= dinb[11:0];
//            5'd14: hpixstopreg <= dinb[11:0];
//            5'd15: hpixreg <= dinb[11:0];
//            5'd16: vpixreg <= dinb[11:0];
          endcase
     end

`ifdef LASTMSG
   
   parameter msgwid = 32;
   
   reg [msgwid*8-1:0]            last_msg;
               
   reg [7:0]                     crnt, msgi;
                     
   // This section generates a message in simulation, it gets trimmed in hardware.
   always @(posedge clk_data)
     if (irst)
       last_msg = {msgwid{8'h20}};
     else
     begin
        if (enb) for (msgi = 0; msgi < 8; msgi=msgi+1)
          if (web[msgi])
            begin
               crnt = dinb >> msgi*8;
               $write("%c", crnt);
               if (crnt==10 || crnt==13) $fflush();
               last_msg = {last_msg[msgwid*8-9:0],crnt};
            end
     end
`endif
   
   always @(posedge pixel2_clk) // or posedge reset) // JRRK - does this need async ?
   if (irst)
     begin
        hreg <= 0;
        hstart <= 0;
        hsyn <= 0;
        hstop <= 0;
        vreg <= 0;
        vstart <= 0;
        vstop <= 0;
        vblank <= 0;
        red <= 0;
        green <= 0;
        blue <= 0;
        bitmapped_pixel <= 0;
        blank <= 0;
        offhreg <= 0;
        offvreg <= 0;
        offpixel <= 0;
        vrow <= 0;
        scroll <= 0;
        scrollv <= 0;
     end
   else
     begin
	xcursor <= xcursor0;
	ycursor <= ycursor0;	
        hreg <= (hstop) ? 0: hreg + 1;
        hstart <= hreg == hstartreg;      
        if (hstart) hsyn <= 1; else if (hreg == hsynreg) hsyn <= 0;
        hstop <= hreg == hstopreg;
        if (hstop) begin
           if (vstop)
             begin
                vreg <= 0;
             end
           else
             vreg <= vreg + 1;
           vstart <= vreg == vstartreg;
           vstop <= vreg == vstopreg;
        end

        vblank <= vreg < vblankstopreg || vreg >= vblankstartreg; 
        
        if (dvi_mux) begin
           red <= red_in;         
           blue <= blue_in;
           green <= green_in;
        end

        if (vreg >= vpixstartreg && vreg < vpixstopreg)
          begin
             if (hreg >= hpixstartreg && hreg < hpixstopreg)
               begin
                  if (&hreg[0])
                    begin
                       if (offpixel == hpixreg)
                         begin
                            offpixel <= 0;
                            offhreg <= offhreg+1;
                         end
                       else
                         offpixel <= offpixel+1;
                    end
                  bitmapped_pixel <= 1;
               end
             else
               begin
                  offpixel <= 0;
                  offhreg <= 0;
                  if (hstop & vreg[0])
                    begin
                       if (vrow == vpixreg)
                         begin
                            vrow <= 0;
                            offvreg <= offvreg+1;
                         end
                       else
                         begin
                            vrow <= vrow + 1;
                         end
                    end
                  bitmapped_pixel <= 0;
               end
          end
        else
          begin
             vrow <= 0;
             offvreg <= scrollv;
             bitmapped_pixel <= 0;
          end

        blank <= hsyn | vsyn | vblank;
        
     end

   assign vsyn = vstart;
   
   wire [7:0] pixels_out;
   chargen_7x5_rachel the_rachel(
    .clk(pixel2_clk),
    .ascii(dout16[7:0]),
    .row(vrow),
    .pixels_out(pixels_out));
   
   wire       pixel = (pixels_out[3'd7 ^ offpixel] || cursor) && bitmapped_pixel;

   always @(dout16 or pixel)
        case(pixel ? dout16[11:8]: dout16[14:12])
            0: {red_in,green_in,blue_in} = 24'h000000;
            1: {red_in,green_in,blue_in} = 24'h0000AA;
            2: {red_in,green_in,blue_in} = 24'h00AA00;
            3: {red_in,green_in,blue_in} = 24'h00AAAA;
            4: {red_in,green_in,blue_in} = 24'hAA0000;
            5: {red_in,green_in,blue_in} = 24'hAA00AA;
            6: {red_in,green_in,blue_in} = 24'hAA5500;
            7: {red_in,green_in,blue_in} = 24'hAAAAAA;
            8: {red_in,green_in,blue_in} = 24'h555555;
            9: {red_in,green_in,blue_in} = 24'h5555FF;
           10: {red_in,green_in,blue_in} = 24'h55FF55;
           11: {red_in,green_in,blue_in} = 24'h55FFFF;
           12: {red_in,green_in,blue_in} = 24'hFF5555;
           13: {red_in,green_in,blue_in} = 24'hFF55FF;
           14: {red_in,green_in,blue_in} = 24'hFFFF55;
           15: {red_in,green_in,blue_in} = 24'hFFFFFF;
       endcase
   
endmodule
