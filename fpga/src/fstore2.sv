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
               input wire         pxl_clk,
               output reg [7:0]   red,
               output reg [7:0]   green,
               output reg [7:0]   blue,

               output wire        vsyn,
               output reg         hsyn,

               output reg [63:0]  doutg,
               output wire [63:0] doutb,
               input wire [63:0]  hid_wrdata,
               input wire [19:0]  hid_addr,
               input wire [7:0]   hid_we,
               input wire [7:0]   one_hot_data_addr,
               input wire         hid_en,
               input wire         clk_i,
               input wire         rst_ni
               );

   parameter rwidth = 14;

   integer                       i;
   
   wire                          m0 = 1'b0;
   
   reg                           hstart, hstop, vstart, vstop;
   reg [12:6]                    offhreg, offhreg1;
   reg [5:3]                     offpixel, offpixel1;
   reg [11:5]                    offvreg;
   reg [11:0]                    offgpixel, offgpixel_1;
   reg [18:4]                    offgreg, offgreg_1;
   reg [4:1]                     vrow;
   reg [4:0]                     divreg, divreg0, hdiv;
   reg [6:0]                     xcursor, ycursor, xcursor0, ycursor0, cursorvreg, cursorvreg0, modereg, modereg0;
   reg [11:0]                    hstartreg, hsynreg, hstopreg, vstartreg,
                                 vstopreg, vpixstartreg,
                                 vpixstopreg, hpixstartreg, hpixstopreg, hpixreg, vpixreg,
                                 hstartreg0, hsynreg0, hstopreg0, vstartreg0,
                                 vstopreg0, vpixstartreg0,
                                 vpixstopreg0, hpixstartreg0, hpixstopreg0, hpixreg0, vpixreg0;
   reg [7:0]                     ghlimit, ghlimit0;
   reg [18:0]                    addrb_1;
   wire [63:0]                   dout, dout0;
//   wire [15:0]                   dout16 = dout >> {offhreg1[7:6],4'b0000};
//   reg [15:0]                    dout16_1;
   wire                          cursor = (offvreg[10:5] == ycursor[6:0]) && (offhreg[12:6] == xcursor[6:0]) && (vrow==cursorvreg);
   
   // 100 MHz / 2100 is 47.6kHz.  Divide by further 788 to get 60.4 Hz.
   // Aim for 1024x768 non interlaced at 60 Hz.  
   
   reg [11:0]                    hreg, vreg;

   reg                           bitmapped_pixel, bitmapped_pixel1;
   
   reg [7:0]                     red_in, green_in, blue_in;

   reg [23:0]                    palette0[0:15], palette[0:15];

/*   
   dualmem ram1(.clka(pxl_clk),
                .dina(8'b0), .addra({offvreg[10:5],offhreg[12:8]}), .wea(8'b0), .douta(dout), .ena(1'b1),
                .clkb(~clk_i), .dinb(hid_wrdata), .addrb(hid_addr[13:3]), .web(hid_we), .doutb(dout0), .enb(hid_en & one_hot_data_addr[7] & ~hid_addr[14]));
*/
   
   parameter graphmax = 15;
   
   genvar                        r;
   logic [63:0]                  fstore_rddata, doutfb[graphmax-1:0], doutpix[graphmax-1:0];
   logic [3:0]                   doutpix4;
   logic [18:4]                  gaddra_1, gaddra = offgreg[18:4]+offgpixel[11:4];
                 
   always_comb
     begin:onehot
        integer i;
        doutg = 64'b0;
        fstore_rddata = 64'b0;
        for (i = 0; i < graphmax; i++)
          begin
	     doutg |= addrb_1[18:15] == r ? doutfb[i] : 64'b0;
	     fstore_rddata |= (gaddra_1[18:15] == i) && (offgpixel_1[11:4] < ghlimit) ? doutpix[i] : 64'b0;
          end
     end
   generate for (r = 0; r < graphmax; r=r+1)
     dualmem4 ram1(.clka(pxl_clk),
                  .dina(8'b0),
                  .addra(gaddra[14:4]),
                  .wea(8'b0),
                  .douta(doutpix[r]),
                  .ena(gaddra[18:15]==r),
                  .clkb(clk_i),
                  .dinb(hid_wrdata),
                  .addrb(hid_addr[14:3]),
                  .web(hid_we),
                  .doutb(doutfb[r]),
                  .enb(hid_en && (hid_addr[18:15]==r) && hid_addr[19]));
   endgenerate

   always @(posedge clk_i)
   if (~rst_ni)
     begin
        ghlimit0 <= 32;
        modereg0 <= 0;
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
        addrb_1 <= hid_addr;
        if (hid_we && hid_en & one_hot_data_addr[7] && hid_addr[14] && ~hid_addr[13])
          casez (hid_addr[8:3])
            6'd0: modereg0 <= hid_wrdata[6:0];
            6'd1: cursorvreg0 <= hid_wrdata[6:0];
            6'd2: xcursor0 <= hid_wrdata[6:0];
            6'd3: ycursor0 <= hid_wrdata[6:0];
            6'd4: hstartreg0 <= hid_wrdata[11:0];
            6'd5: hsynreg0 <= hid_wrdata[11:0];
            6'd6: hstopreg0 <= hid_wrdata[11:0];
            6'd7: vstartreg0 <= hid_wrdata[11:0];
            6'd8: vstopreg0 <= hid_wrdata[11:0];
            6'd11: vpixstartreg0 <= hid_wrdata[11:0];
            6'd12: vpixstopreg0 <= hid_wrdata[11:0];
            6'd13: hpixstartreg0 <= hid_wrdata[11:0];
            6'd14: hpixstopreg0 <= hid_wrdata[11:0];
            6'd15: hpixreg0 <= hid_wrdata[11:0];
            6'd16: vpixreg0 <= hid_wrdata[11:0];
            6'd17: divreg0 <= hid_wrdata[3:0];
            6'd18: ghlimit0 <= hid_wrdata[7:0];
            default:;
          endcase
        if (hid_we && hid_en & one_hot_data_addr[7] && hid_addr[14] && ~hid_addr[13] && hid_addr[8])
            palette0[hid_addr[6:3]] <= hid_wrdata[23:0];
     end

`ifdef LASTMSG
   
   parameter msgwid = 32;
   
   reg [msgwid*8-1:0]            last_msg;
               
   reg [7:0]                     crnt, msgi;
                     
   // This section generates a message in simulation, it gets trimmed in hardware.
   always @(posedge clk_i)
     if (~rst_ni)
       last_msg = {msgwid{8'h20}};
     else
     begin
        if (hid_en & one_hot_data_addr[7]) for (msgi = 0; msgi < 8; msgi=msgi+1)
          if (hid_we[msgi])
            begin
               crnt = hid_wrdata >> msgi*8;
               $write("%c", crnt);
               if (crnt==10 || crnt==13) $fflush();
               last_msg = {last_msg[msgwid*8-9:0],crnt};
            end
     end
`endif
   
   always @(posedge pxl_clk) // or posedge reset) // JRRK - does this need async ?
   if (~rst_ni)
     begin
        modereg <= 0;
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
        doutpix4 <= fstore_rddata >> {offgpixel_1[3:0],2'b00};
        modereg <= modereg0;
        offhreg1 <= offhreg;
        offgpixel_1 <= offgpixel;
        gaddra_1 <= gaddra;
        offpixel1 <= offpixel;
//        dout16_1 <= dout16;
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
        ghlimit <= ghlimit0;
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
                       offgpixel <= offgpixel+1;
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
                  offgpixel <= 0;
                  offhreg <= 0;
                  if (hstop)
                    begin
                       offgreg <= offgreg + ghlimit;
                       if (vreg[0])
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
                    end
                  bitmapped_pixel <= 0;
               end
          end
        else
          begin
             vrow <= 0;
             offvreg <= 0;
             offgreg <= 0;
             bitmapped_pixel <= 0;
          end

     end

   assign vsyn = vstart;

/*                  
   wire [7:0] pixels_out, fout;
   reg [3:0]  faddr;

   always @(hid_we)
     case(hid_we)
       8'h01: faddr = 0;
       8'h02: faddr = 1;
       8'h04: faddr = 2;
       8'h08: faddr = 3;
       8'h10: faddr = 4;
       8'h20: faddr = 5;
       8'h40: faddr = 6;
       8'h80: faddr = 7;
       default: faddr = 8;
   endcase // case (hid_we)
   
   assign doutb = addrb_1[14] ? {fout,fout,fout,fout,fout,fout,fout,fout} : dout0;
   wire [7:0] font_in = hid_wrdata >> {faddr[2:0],3'b000};

   chargen_7x5_rachel the_rachel(
    .clk(pxl_clk),
    .ascii(dout16[7:0]),
    .row(vrow),
    .pixels_out(pixels_out),
    .font_clk(~clk_i),
    .font_out(fout),
    .font_addr({hid_addr[10:3],faddr[2:0]}),
    .font_in(font_in),
    .font_en(hid_en & one_hot_data_addr[7] & hid_addr[14] & hid_addr[13]),
    .font_we(~faddr[3]));
   
     wire pixel = pixels_out[3'd7 ^ offpixel1] || cursor;
     wire [3:0] colour = pixel ? dout16_1[11:8]: dout16_1[14:12];
*/
     
     assign
       {blue_in,green_in,red_in} = bitmapped_pixel1 ? palette[doutpix4] : 24'b0;
   
endmodule
