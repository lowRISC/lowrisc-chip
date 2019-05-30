`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Ulrich Zoltán
// 
// Create Date:    09/18/2006
// Module Name:    resolution_mouse_informer
// Project Name: 	 PmodPS2_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.2
// Description: This module implements the logic that sets the position of the mouse
// 				 when the fpga is powered-up and when the resolution changes. It
// 				 also sets the bounds of the mouse corresponding to the currently used
// 				 resolution.
//
// 				 The mouse is centered for the currently selected resolution and the
// 				 bounds are set appropriately. This way the mouse will first appear
// 				 in the center in the screen at start-up and when resolution is
// 				 changed and cannot leave the screen.
//
// 				 The position (and similarly the bounds) is set by placing and number
// 				 representing the middle of the screen dimension on the value output
// 				 and activation the corresponding set signal (setx for horizontal
// 				 position, sety for vertical position, setmax_x for horizontal
// 				 maximum value, setmax_y for the veritcal maximum value).
//----------------------------------------------------------------------------------------
//  											Port definitions
//----------------------------------------------------------------------------------------
// 				clk         - global clock signal
// 				rst         - reset signal
// 				resolution  - input pin, from resolution_switcher
// 				            - 0 for 640x480 selected resolution
// 				            - 1 for 800x600 selected resolution
// 				switch      - input pin, from resolution_switcher
// 				            - active for one clock period when resolution changes
// 				value       - output pin, 10 bits, to mouse_controller
// 				            - position on x or y, max value for x or y
// 				            - that is sent to the mouse_controller
// 				setx        - output pin, to mouse_controller
// 				            - active for one clock period when the horizontal
// 				            - position of the mouse cursor is valid on value output
// 				sety        - output pin, to mouse_controller
// 				            - active for one clock period when the vertical
// 				            - position of the mouse cursor is valid on value output
// 				setmax_x    - output pin, to mouse_controller
// 				            - active for one clock period when the horizontal
// 				            - maximum position of the mouse cursor is valid on
// 				            - value output
// 				setmax_y    - output pin, to mouse_controller
// 				            - active for one clock period when the vertical
// 				            - maximum position of the mouse cursor is valid on
//  				            - value output
//
// Revision History: 
//							Revision 0.00 - File created (UlrichZ)
//							Revision 1.00 - Added Comments and Converted to Verilog (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
// 										  Define Module
// =======================================================================================
module resolution_mouse_informer(
		 clk,
		 rst,
		 resolution,
		 switch,
		 value,
		 setx,
		 sety,
		 setmax_x,
		 setmax_y
);

// =======================================================================================
// 										Port Declarations
// =======================================================================================

			input clk;
			input rst;
			input resolution;
			input switch;
			output [9:0] value;
			output setx;
			output sety;
			output setmax_x;
			output setmax_y;

// =======================================================================================
// 							  Parameters, Registers, and Wires
// =======================================================================================

			// center horizontal position of the mouse for 640x480 and 800x600
			parameter [9:0] POS_X_640 = 10'b0101000000; // 320
			parameter [9:0] POS_X_800 = 10'b0110010000; // 400

			// center vertical position of the mouse for 640x480 and 800x600
			parameter [9:0] POS_Y_640 = 10'b0011110000; // 240
			parameter [9:0] POS_Y_800 = 10'b0100101100; // 300
			
			// maximum horizontal position of the mouse for 640x480 and 800x600
			parameter [9:0] MAX_X_640 = 10'b1001111111; // 639
			parameter [9:0] MAX_X_800 = 10'b1100011111; // 799

			// maximum vertical position of the mouse for 640x480 and 800x600
			parameter [9:0] MAX_Y_640 = 10'b0111011111; // 479
			parameter [9:0] MAX_Y_800 = 10'b1001010111; // 599

			parameter RES_640 = 1'b0;
			parameter RES_800 = 1'b1;

			parameter [2:0] sReset   = 3'd0,
								 sIdle    = 3'd1,
								 sSetX    = 3'd2,
								 sSetY    = 3'd3,
								 sSetMaxX = 3'd4,
								 sSetMaxY = 3'd5;

			// signal that holds the current state of the FSM
			reg [2:0] state;
			
			wire [9:0] value;

// =======================================================================================
// 							  		   Implementation
// =======================================================================================
			
			// value receives the horizontal position of the mouse, the vertical
			// position, the maximum horizontal value and maximum vertical
			// value for the active resolution when in the apropriate state
			assign value = (state == sSetX && resolution == RES_640) ? POS_X_640 :
								(state == sSetX && resolution == RES_800) ? POS_X_800 :
								(state == sSetY && resolution == RES_640) ? POS_Y_640 :
								(state == sSetY && resolution == RES_800) ? POS_Y_800 :
								(state == sSetMaxX && resolution == RES_640) ? MAX_X_640 :
								(state == sSetMaxX && resolution == RES_800) ? MAX_X_800 :
								(state == sSetMaxY && resolution == RES_640) ? MAX_Y_640 :
								(state == sSetMaxY && resolution == RES_800) ? MAX_Y_800 :
								10'b0000000000;
			
			// when in state sSetX, set the horizontal value for the mouse
			assign setx = (state == sSetX) ? 1'b1 : 1'b0;
			// when in state sSetY, set the vertical value for the mouse
			assign sety = (state == sSetY) ? 1'b1 : 1'b0;
			// when in state sSetMaxX, set the horizontal max value for the mouse
			assign setmax_x = (state == sSetMaxX) ? 1'b1 : 1'b0;
			// when in state sSetMaxX, set the vertical max value for the mouse
			assign setmax_y = (state == sSetMaxY) ? 1'b1 : 1'b0;

			// when a resolution switch occurs (even to the same resolution)
			// leave the idle state
			// if just powered up or reset occures go to reset state and
			// from there set the position and bounds for the mouse
			always @(posedge clk or posedge rst) begin
					if(rst == 1'b1) begin
						state <= sReset;
					end
					else begin

						case (state)
							// when reset occurs (or power-up) set the position
							// and bounds for the mouse.
							sReset : begin
								state <= sSetX;
							end

							// remain in idle while switch is not active.
							sIdle : begin
								if(switch == 1'b1) begin
									state <= sSetX;
								end
								else begin
									state <= sIdle;
								end
							end

							sSetX : begin
								state <= sSetY;
							end

							sSetY : begin
								state <= sSetMaxX;
							end

							sSetMaxX : begin
								state <= sSetMaxY;
							end

							sSetMaxY : begin
								state <= sIdle;
							end

						endcase
					end
			end

endmodule
