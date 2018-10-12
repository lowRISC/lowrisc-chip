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
               input wire         pixel2_clk,
               output reg [7:0]   red,
               output reg [7:0]   green,
               output reg [7:0]   blue,

               output wire        vsyn,
               output reg         hsyn,

               output wire [63:0] doutb,
               input wire  [63:0] dinb,
               input wire  [14:0] addrb,
               input wire  [7:0]  web,
               input wire         enb,
               input wire         clk_data,
               input wire         irst
               );

   parameter rwidth = 14;

   integer                       i;
   
   wire                          m0 = 1'b0;
   
   reg                           hstart, hstop, vstart, vstop;
   reg [12:6]                    offhreg, offhreg1;
   reg [5:3]                     offpixel, offpixel1;
   reg [11:5]                    offvreg;
   reg [4:1]                     vrow;
   reg [4:0]                     divreg, divreg0, hdiv;
   reg [6:0]                     xcursor, ycursor, xcursor0, ycursor0, cursorvreg, cursorvreg0;
   reg [11:0]                    hstartreg, hsynreg, hstopreg, vstartreg,
                                 vstopreg, vpixstartreg,
                                 vpixstopreg, hpixstartreg, hpixstopreg, hpixreg, vpixreg,
                                 hstartreg0, hsynreg0, hstopreg0, vstartreg0,
                                 vstopreg0, vpixstartreg0,
                                 vpixstopreg0, hpixstartreg0, hpixstopreg0, hpixreg0, vpixreg0;
   wire [63:0]                   dout, dout0;
   wire [15:0]                   dout16 = dout >> {offhreg1[7:6],4'b0000};
   reg [15:0]                    dout16_1;
   wire                          cursor = (offvreg[10:5] == ycursor[6:0]) && (offhreg[12:6] == xcursor[6:0]) && (vrow==cursorvreg);
   
   // 100 MHz / 2100 is 47.6kHz.  Divide by further 788 to get 60.4 Hz.
   // Aim for 1024x768 non interlaced at 60 Hz.  
   
   reg [11:0]                    hreg, vreg;

   reg                           bitmapped_pixel, bitmapped_pixel1, addrb14;
   
   reg [7:0]                     red_in, green_in, blue_in;

   reg [23:0]                    palette0[0:15], palette[0:15];
                  
   dualmem ram1(.clka(pixel2_clk),
                .dina(8'b0), .addra({offvreg[10:5],offhreg[12:8]}), .wea(8'b0), .douta(dout), .ena(1'b1),
                .clkb(~clk_data), .dinb(dinb), .addrb(addrb[13:3]), .web(web), .doutb(dout0), .enb(enb&~addrb[14]));

   always @(posedge clk_data)
   if (irst)
     begin
        cursorvreg0 <= 10;
        xcursor0 <= 0;
        ycursor0 <= 32;
        hstartreg0 <= 2048;
        hsynreg0 <= 2048+20;
        hstopreg0 <= 2100-1;
        vstartreg0 <= 768;
        vstopreg0 <= 768+19;
        vpixstartreg0 <= 16;
        vpixstopreg0 <= 16+768;
        hpixstartreg0 <= 128*3;
        hpixstopreg0 <= 128*3+256*6;
        hpixreg0 <= 5;
        vpixreg0 <= 11;
        divreg0 <= 1;
     end
   else
     begin
        addrb14 <= addrb[14];
        if (web && enb && addrb[14] && ~addrb[13])
          casez (addrb[8:3])
            6'd1: cursorvreg0 <= dinb[6:0];
            6'd2: xcursor0 <= dinb[6:0];
            6'd3: ycursor0 <= dinb[6:0];
            6'd4: hstartreg0 <= dinb[11:0];
            6'd5: hsynreg0 <= dinb[11:0];
            6'd6: hstopreg0 <= dinb[11:0];
            6'd7: vstartreg0 <= dinb[11:0];
            6'd8: vstopreg0 <= dinb[11:0];
            6'd11: vpixstartreg0 <= dinb[11:0];
            6'd12: vpixstopreg0 <= dinb[11:0];
            6'd13: hpixstartreg0 <= dinb[11:0];
            6'd14: hpixstopreg0 <= dinb[11:0];
            6'd15: hpixreg0 <= dinb[11:0];
            6'd16: vpixreg0 <= dinb[11:0];
            6'd17: divreg0 <= dinb[3:0];
            default:;
          endcase
        if (web && enb && addrb[14] && ~addrb[13] && addrb[8])
            palette0[addrb[6:3]] <= dinb[23:0];
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
        red <= 0;
        green <= 0;
        blue <= 0;
        bitmapped_pixel <= 0;
        offhreg <= 0;
        offvreg <= 0;
        offpixel <= 0;
        vrow <= 0;
     end
   else
     begin
        offhreg1 <= offhreg;
        offpixel1 <= offpixel;
        dout16_1 <= dout16;
        bitmapped_pixel1 <= bitmapped_pixel;
        cursorvreg <= cursorvreg0;
	xcursor <= xcursor0;
	ycursor <= ycursor0;
        hstartreg <= hstartreg0;
        hsynreg <= hsynreg0;
        hstopreg <= hstopreg0;
        vstartreg <= vstartreg0;
        vstopreg <= vstopreg0;
        vpixstartreg <= vpixstartreg0;
        vpixstopreg <= vpixstopreg0;
        hpixstartreg <= hpixstartreg0;
        hpixstopreg <= hpixstopreg0;
        hpixreg <= hpixreg0;
        vpixreg <= vpixreg0;
        divreg <= divreg0;
        for (i = 0; i < 16; i=i+1)
          palette[i] = palette0[i];
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

        red <= red_in;         
        blue <= blue_in;
        green <= green_in;

        if (vreg >= vpixstartreg && vreg < vpixstopreg)
          begin
             if (hreg >= hpixstartreg && hreg < hpixstopreg)
               begin
                  if (hdiv == divreg)
                    begin
                       if (offpixel == hpixreg)
                         begin
                            offpixel <= 0;
                            offhreg <= offhreg+1;
                         end
                       else
                         offpixel <= offpixel+1;
                       hdiv <= 0;
                    end
                  else
                    hdiv = hdiv + 1;
                  bitmapped_pixel <= 1;
               end
             else
               begin
                  hdiv <= 0;
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
             offvreg <= 0;
             bitmapped_pixel <= 0;
          end

     end

   assign vsyn = vstart;

   wire [7:0] pixels_out, fout;
   reg [3:0]  faddr;

   always @(web)
     case(web)
       8'h01: faddr = 0;
       8'h02: faddr = 1;
       8'h04: faddr = 2;
       8'h08: faddr = 3;
       8'h10: faddr = 4;
       8'h20: faddr = 5;
       8'h40: faddr = 6;
       8'h80: faddr = 7;
       default: faddr = 8;
   endcase // case (web)
   
   assign doutb = addrb14 ? {fout,fout,fout,fout,fout,fout,fout,fout} : dout0;
   wire [7:0] font_in = dinb >> {faddr[2:0],3'b000};
                  
   chargen_7x5_rachel the_rachel(
    .clk(pixel2_clk),
    .ascii(dout16[7:0]),
    .row(vrow),
    .pixels_out(pixels_out),
    .font_clk(~clk_data),
    .font_out(fout),
    .font_addr({addrb[10:3],faddr[2:0]}),
    .font_in(font_in),
    .font_en(enb & addrb[14] & addrb[13]),
    .font_we(~faddr[3]));
   
   wire       pixel = pixels_out[3'd7 ^ offpixel1] || cursor;

   always @(dout16_1 or pixel or bitmapped_pixel1)
     {red_in,green_in,blue_in} = bitmapped_pixel1 ? palette[pixel ? dout16_1[11:8]: dout16_1[14:12]] : 24'b0;
   
endmodule
