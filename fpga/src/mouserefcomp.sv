`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent RO
// Engineer: Mircea Dabacan
// 
// Create Date:    12:57:12 03/01/2008
// Module Name:    MouseRefComp
// Project Name:   PmodPS2_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.2
// Description: This is the structural VHDL code of the 
//              Digilent Mouse Reference Component.
//              It instantiates three components:
//                - ps2interface
//                - mouse_controller
//                - resolution_mouse_informer
//
// Revision: 
// Revision 0.01 - File Created
// Revision 1.00 - Converted from VHDL to Verilog (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
// 										  Define Module
// =======================================================================================
module MouseRefComp(
		CLK,
		RESOLUTION,
		RST,
		SWITCH,
		LEFT,
		MIDDLE,
		NEW_EVENT,
		RIGHT,
		XPOS,
		YPOS,
		ZPOS,
		PS2_CLK,
		PS2_DATA
);

// =======================================================================================
// 										Port Declarations
// =======================================================================================
   input        CLK;
   input        RESOLUTION;
   input        RST;
   input        SWITCH;
   output       LEFT;
   output       MIDDLE;
   output       NEW_EVENT;
   output       RIGHT;
   output [9:0] XPOS;
   output [9:0] YPOS;
   output [3:0] ZPOS;
   inout        PS2_CLK;
   inout        PS2_DATA;
   
// =======================================================================================
// 							  Parameters, Registers, and Wires
// =======================================================================================
   wire [7:0]   TX_DATA;
   wire         bitSetMaxX;
   wire [9:0]   vecValue;
   wire         bitRead;
   wire         bitWrite;
   wire         bitErr;
   wire         bitSetX;
   wire         bitSetY;
   wire         bitSetMaxY;
   wire [7:0]   vecRxData;
   
// =======================================================================================
// 							  		   Implementation
// =======================================================================================

	//--------------------------------------
	//	  	Mouse Interface Controller
	//--------------------------------------
   mouse_controller MouseCtrlInst(
				.clk(CLK),
				.rst(RST),
				.read(bitRead),
				.write(bitWrite),
				.err(bitErr),
				.setmax_x(bitSetMaxX),
				.setmax_y(bitSetMaxY),
				.setx(bitSetX),
				.sety(bitSetY),
				.value(vecValue[9:0]),
				.rx_data(vecRxData[7:0]),
				.tx_data(TX_DATA[7:0]),
				.left(LEFT),
				.middle(MIDDLE),
				.right(RIGHT),
				.xpos(XPOS[9:0]),
				.ypos(YPOS[9:0]),
				.zpos(ZPOS[3:0]),
				.new_event(NEW_EVENT)
	);
   
	//--------------------------------------
	//	  	  Sets Mouse Position, etc.
	//--------------------------------------
   resolution_mouse_informer ResMouseInfInst(
				.clk(CLK),
				.resolution(RESOLUTION),
				.rst(RST),
				.switch(SWITCH),
				.setmax_x(bitSetMaxX),
				.setmax_y(bitSetMaxY),
				.setx(bitSetX),
				.sety(bitSetY),
				.value(vecValue[9:0])
	);
   
   
	//--------------------------------------
	//	  			PS2 Interface
	//--------------------------------------
   ps2interface Pss2Inst(
				.clk(CLK),
				.rst(RST),
				.tx_data(TX_DATA[7:0]),
				.read(bitRead),
				.write(bitWrite),
				.busy(),
				.err(bitErr),
				.rx_data(vecRxData[7:0]),
				.ps2_clk(PS2_CLK),
				.ps2_data(PS2_DATA)
	);
   
endmodule
