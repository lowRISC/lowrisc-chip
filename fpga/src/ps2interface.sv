`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Ulrich Zolt�n
// 
// Create Date:    09/18/2006
// Module Name:    ps2interface
// Project Name: 	 PmodPS2_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.2
// Description:  Please read the following article on the web for understanding how
// 				  the ps/2 protocol works.
// 				  http://www.computer-engineering.org/ps2protocol/
//
// 				  This module implements a generic bidirectional ps/2 interface. It can
// 				  be used with any ps/2 compatible device. It offers its clients a
// 				  convenient way to exchange data with the device. The interface
// 				  transparently wraps the byte to be sent into a ps/2 frame, generates
// 				  parity for byte and sends the frame one bit at a time to the device.
// 				  Similarly, when receiving data from the ps2 device, the interface
// 				  receives the frame, checks for parity, and extract the usefull data
// 				  and forwards it to the client. If an error occurs during receiving
// 				  or sending a byte, the client is informed by settings the err output
// 				  line high. This way, the client can resend the data or can issue
// 				  a resend command to the device.
//
// 				  The physical ps/2 interface uses 4 lines
// 				  For the 6-pin connector pins are assigned as follows: 
// 				  1 - Data
// 				  2 - Not Implemented
// 				  3 - Ground
// 				  4 - Vcc (+5V)
// 				  5 - Clock
// 				  6 - Not Implemented
//
// 				  The clock line carries the device generated clock which has a 
// 				  frequency in range 10 - 16.7 kHz (30 to 50us). When line is idle
// 				  it is placed in high impedance. The clock is only generated when
// 				  device is sending or receiving data.
//
// 				  The Data and Clock lines are both open-collector with pullup
// 				  resistors to Vcc. An "open-collector" interface has two possible
// 				  states: low('0') or high impedance('Z').
//
// 				  When device wants to send a byte, it pulls the clock line low and the
// 				  host(i.e. this interfaces) recognizes that the device is sending data
// 				  When the host wants to send data, it maeks a request to send. This
// 				  is done by holding the clock line low for at least 100us, then with
// 				  the clock line low, the data line is brought low. Next the clock line
// 				  is released (placed in high impedance). The devices begins generating
// 				  clock signal on clock line.
//
// 				  When receiving data, bits are read from the data line (ps2_data) on
// 				  the falling edge of the clock (ps2_clk). When sending data, the
// 				  device reads the bits from the data line on the rising edge of the
// 				  clock.
// 				  A frame for sending a byte is comprised of 11 bits as shown bellow:
// 				  bits     10     9    8    7    6    5    4    3    2    1      0
// 				         -------------------------------------------------------------
// 				         | STOP| PAR | D7 | D6 | D5 | D4 | D3 | D2 | D1 | D0 | START |
// 				         -------------------------------------------------------------
// 				  STOP  - stop  bit, always '1'
// 				  PAR   - parity bit, odd parity for the 8 data bits.
// 				        - select in such way that the number of bits of '1' in the data
// 				        - bits together with parity bit is odd.
// 				  D0-7  - data bits.
// 				  START - start bit, always '0'
//
// 				  Frame is sent bit by bit starting with the least significant bit
// 				  (starting bit) and is received the same way. This is done, when
// 				  receiving, by shifting the frame register to the left when a bit
// 				  is available and placing the bit on data line on the most significant
// 				  bit. This way the first bit sent will reach the least significant bit
// 				  of the frame when all the bits have been received. When sending data
// 				  the least significant bit of the frame is placed on the data line
// 				  and the frame is shifted to the right when another bit needs to be
// 				  sent. During the request to send, when releasing the clock line,
// 				  the device reads the data line and interprets the data on it as the
// 				  first bit of the frame. Data line is low at that time, at this is the
// 				  way the start bit('0') is sent. Because of this, when sending, only
// 				  10 shifts of the frame will be made.
//
// 				  While the interface is sending or receiving data, the busy output
// 				  signal goes high. When interface is idle, busy is low.
// 				  After sending all the bits in the frame, the device must acknowledge
// 				  the data sent. This is done by the host releasing and data line
// 				  (clock line is already released) after the last bit is sent. The
// 				  devices brings the data line and the clock line low, in this order,
// 				  to acknowledge the data. If data line is high when clock line goes
// 				  low after last bit, the device did not acknowledge the data and
// 				  err output is set.
//
// 				  A FSM is used to manage the transitions the set all the command
// 				  signals. States that begin with "rx_" are used to receive data
// 				  from device and states begining with "tx_" are used to send data
// 				  to the device.
//
// 				  For the parity bit, a ROM holds the parity bit for all possible
// 				  data (256 possible values, since 8 bits of data). The ROM has
// 				  dimensions 256x1bit. For obtaining the parity bit of a value,
// 				  the bit at the data value address is read. Ex: to find the parity
// 				  bit of 174, the bit at address 174 is read.
//
// 				  For generating the necessary delay, counters are used. For example,
// 				  to generate the 100us delay a 14 bit counter is used that has the
// 				  upper limit for counting 10000. The interface is designed to run
// 				  at 100MHz. Thus, 10000x10ns = 100us.
//
//				  ---------------------------------------------------------------------
// 				  If using the interface at different frequency than 100MHz, adjusting
// 				  the delay counters is necessary!!!
//				  ---------------------------------------------------------------------
//
// 				  Clock line(ps2_clk) and data line(ps2_data) are passed through a
// 				  debouncer for the transitions of the clock and data to be clean.
// 				  Also, ps2_clk_s and ps2_data_s hold the debounced and synchronized
// 				  value of the clock and data line to the system clock(clk).
//				  ----------------------------------------------------------------------
//  				  Port definitions
//				  ----------------------------------------------------------------------
// 				  ps2_clk        - inout pin, clock line of the ps/2 interface
// 				  ps2_data       - inout pin, clock line of the ps/2 interface
// 				  clk            - input pin, system clock signal
// 				  rst            - input pin, system reset signal
// 				  tx_data        - input pin, 8 bits, from client
// 				                 - data to be sent to the device
// 				  write          - input pin, from client
//  				                 - should be active for one clock period when then
// 				                 - client wants to send data to the device and
// 				                 - data to be sent is valid on tx_data
// 				  rx_data        - output pin, 8 bits, to client
// 				                 - data received from device
// 				  read           - output pin, to client
// 				                 - active for one clock period when new data is
// 				                 - available from device
// 				  busy           - output pin, to client
// 				                 - active while sending or receiving data.
// 				  err            - output pin, to client
// 				                 - active for one clock period when an error occurred
// 				                 - during sending or receiving.
//
// Revision History: 
//							Revision 0.00 - File created (UlrichZ)
//							Revision 1.00 - Added Comments and Converted to Verilog (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
// 										  Define Module
// =======================================================================================
module ps2interface(
    clk,
    rst,
    ps2_clk,
    ps2_data,
    tx_data,
    write,
    rx_data,
    read,
    busy,
    err
);

// =======================================================================================
// 										Port Declarations
// =======================================================================================

			input clk;
			input rst;
			inout ps2_clk;
			inout ps2_data;
			input [7:0] tx_data;
			input write;
			output [7:0] rx_data;
			output read;
			output busy;
			output err;

// =======================================================================================
// 							  Parameters, Registers, and Wires
// =======================================================================================

			// Output Wires and Registers
			reg [7:0] rx_data;
			reg read;
			wire busy;
			reg err;

			// Values are valid for a 100MHz clk. Please adjust for other
			// frequencies if necessary!

			// upper limit for 100us delay counter.
			// 10000 * 10ns = 100us
			parameter [13:0] DELAY_100US = 14'b10011100010000;
																			 // 10000 clock periods
			// upper limit for 20us delay counter.
			// 2000 * 10ns = 20us
			parameter [10:0] DELAY_20US = 11'b11111010000;
																			  // 2000 clock periods
			// upper limit for 63clk delay counter.
			parameter [5:0] DELAY_63CLK = 6'b111111;
																				 // 63 clock periods
			// delay from debouncing ps2_clk and ps2_data signals
			parameter [3:0] DEBOUNCE_DELAY = 4'b1111;

			// number of bits in a frame
			parameter [3:0] NUMBITS = 4'b1011; // 11

			// parity bit position in frame
			parameter [3:0] PARITY_BIT = 4'd9;

			// (odd) parity bit ROM
			// Used instead of logic because this way speed is far greater
			// 256x1bit rom
			// If the odd parity bit for a 8 bits number, x, is needed
			// the bit at address x is the parity bit.
			parameter [1:0] parityrom[0:255] = {
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
															1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1
			};


			// 14 bits counter
			// max value DELAY_100US
			// used to wait 100us
			reg [13:0] delay_100us_count = 14'd0;

			// 11 bits counter
			// max value DELAY_20US
			// used to wait 20us
			reg [10:0] delay_20us_count = 11'd0;
			// 11 bits counter
			// max value DELAY_63CLK
			// used to wait 63 clock periods
			reg [5:0] delay_63clk_count = 6'd0;

			// done signal for the couters above
			// when a counter reaches max value,the corresponding done signal is set
			reg delay_100us_done;
			reg delay_20us_done;
			reg delay_63clk_done;

			// enable signal for 100us delay counter
			wire delay_100us_counter_enable;
			// enable signal for 20us delay counter
			wire delay_20us_counter_enable;
			// enable signal for 63clk delay counter
			wire delay_63clk_counter_enable;

			// synchronzed input for ps2_clk and ps2_data
			reg ps2_clk_s = 1'b1;
			reg ps2_data_s = 1'b1;

			// control the output of ps2_clk and ps2_data
			// if 1 then corresponding signal (ps2_clk or ps2_data) is
			// put in high impedance ('Z').
			reg ps2_clk_h = 1'b1;
			reg ps2_data_h = 1'b1;

			// states of the FSM for controlling the communcation with the device
			// states that begin with "rx_" are used when receiving data
			// states that begin with "tx_" are used when transmiting data
			parameter [4:0]	idle 								= 5'd0,
									rx_clk_h							= 5'd1,
									rx_clk_l							= 5'd2,
									rx_down_edge					= 5'd3,
									rx_error_parity				= 5'd4,
									rx_data_ready					= 5'd5,
									tx_force_clk_l					= 5'd6,
									tx_bring_data_down			= 5'd7,
									tx_release_clk					= 5'd8,
									tx_first_wait_down_edge		= 5'd9,
									tx_clk_l							= 5'd10,
									tx_wait_up_edge				= 5'd11,
									tx_clk_h							= 5'd12,
									tx_wait_up_edge_before_ack = 5'd13,
									tx_wait_ack						= 5'd14,
									tx_received_ack				= 5'd15,
									tx_error_no_ack				= 5'd16;

			// the signal that holds the current state of the FSM
			// implicitly state is idle.
			reg [4:0] state = idle;

			// register that holds the frame received or the one to be sent.
			// Its contents are shifted in from the bus one bit at a time
			// from left to right when receiving data and are shifted on the
			// bus (ps2_data) one bit at a time to the right when sending data
			reg [10:0] frame = 11'd0;

			// how many bits have been sent or received.
			reg [3:0] bit_count = 4'd0;

			// when active the bit counter is reset.
			wire reset_bit_count;

			// when active the contents of the frame is shifted to the right
			// and the most significant bit of frame is loaded with ps2_data.
			wire shift_frame;

			// parity of the byte that was received from the device.
			// must match the parity bit received, else error occurred.
			reg rx_parity = 1'b0;
			// parity bit that is sent with the frame, representing the
			// odd parity of the byte currently being sent
			reg tx_parity = 1'b0;

			// when active, frame is loaded with the start bit, data on
			// tx_data, parity bit (tx_parity) and stop bit
			// this frame will be sent to the device.
			reg load_tx_data = 1'b0;

			// when active bits 8 downto 1 from frame are loaded into
			// rx_data register. This is the byte received from the device.
			reg load_rx_data = 1'b0;

			// intermediary signals used to debounce the inputs ps2_clk and ps2_data
			reg ps2_clk_clean = 1'b1;
			reg ps2_data_clean = 1'b1;

			// debounce counter for the ps2_clk input and the ps2_data input.
			reg [3:0] clk_count = 4'd0;
			reg [3:0] data_count = 4'd0;
			// last value on ps2_clk and ps2_data.
			reg clk_inter = 1'b1;
			reg data_inter = 1'b1;

// =======================================================================================
// 							  		   Implementation
// =======================================================================================

			//-------------------------------------------------------------------
			// 					FLAGS and PS2 CLOCK AND DATA LINES
			//-------------------------------------------------------------------
			// clean ps2_clk signal (debounce)
			// note that this introduces a delay in ps2_clk of
			// DEBOUNCE_DELAY clocks
			always @(posedge clk) begin
					// if the current bit on ps2_clk is different
					// from the last value, then reset counter
					// and retain value
					if(ps2_clk != clk_inter) begin
						clk_inter <= ps2_clk;
						clk_count <= 4'd0;
					end
					// if counter reached upper limit, then
					// the signal is clean
					else if(clk_count == DEBOUNCE_DELAY) begin
						ps2_clk_clean <= clk_inter;
					end
					// ps2_clk did not change, but counter did not
					// reach limit. Increment counter
					else begin
						clk_count <= clk_count + 1'b1;
					end
			end

			// clean ps2_data signal (debounce)
			// note that this introduces a delay in ps2_data of
			// DEBOUNCE_DELAY clocks
			always @(posedge clk) begin
					// if the current bit on ps2_data is different
					// from the last value, then reset counter
					// and retain value
					if(ps2_data != data_inter) begin
						data_inter <= ps2_data;
						data_count <= 4'd0;
					end
					// if counter reached upper limit, then
					// the signal is clean
					else if(data_count == DEBOUNCE_DELAY) begin
						ps2_data_clean <= data_inter;
					end
					// ps2_data did not change, but counter did not
					// reach limit. Increment counter
					else begin
						data_count <= data_count + 1'b1;
					end
			end


			always @(posedge clk) begin
					// Synchronize ps2 entries
					ps2_clk_s <= ps2_clk_clean;
					ps2_data_s <= ps2_data_clean;

					// Assign parity from frame bits 8 downto 1, this is the parity
					// that should be received inside the frame on PARITY_BIT position
					rx_parity <= parityrom[frame[8:1]];
					// The parity for the data to be sent
					tx_parity <= parityrom[tx_data];
			end

			// Force ps2_clk to '0' if ps2_clk_h = '0', else release the line
			// ('Z' = +5Vcc because of pull-ups)
			assign ps2_clk = (ps2_clk_h == 1'b1) ? 1'bZ : 1'b0;

			// Force ps2_data to '0' if ps2_data_h = '0', else release the line
			// ('Z' = +5Vcc because of pull-ups)
			assign ps2_data = (ps2_data_h == 1'b1) ? 1'bZ : 1'b0;

			// Control busy flag. Interface is not busy while in idle state.
			assign busy = (state == idle) ? 1'b0 : 1'b1;

			// reset the bit counter when in idle state.
			assign reset_bit_count = (state == idle) ? 1'b1 : 1'b0;

			// Control shifting of the frame
			// When receiving from device, data is read
			// on the falling edge of ps2_clk
			// When sending to device, data is read by device
			// on the rising edge of ps2_clk
			assign shift_frame = (state == rx_down_edge || state == tx_clk_l) ? 1'b1 : 1'b0;


			//-------------------------------------------------------------------
			// 							FINITE STATE MACHINE
			//-------------------------------------------------------------------

			// For the current state establish next state
			// and give necessary commands
			always @(posedge clk or posedge rst) begin
				// if reset occurs, go to idle state.
				if(rst == 1'b1) begin
					state <= idle;
				end
				else begin
						
					// default values for these signals
					// ensures signals are reset to default value
					// when coditions for their activation are no
					// longer applied (transition to other state,
					// where signal should not be active)
					// Idle value for ps2_clk and ps2_data is 'Z'
					ps2_clk_h <= 1'b1;
					ps2_data_h <= 1'b1;
					load_tx_data <= 1'b0;
					load_rx_data <= 1'b0;
					read <= 1'b0;
					err <= 1'b0;

					case (state)

						// wait for the device to begin a transmission
						// by pulling the clock line low and go to state
						// rx_down_edge or, if write is high, the
						// client of this interface wants to send a byte
						// to the device and a transition is made to state
						// tx_force_clk_l
						idle : begin
							if(ps2_clk_s == 1'b0) begin
								state <= rx_down_edge;
							end
							else if(write == 1'b1) begin
								state <= tx_force_clk_l;               
							end
							else begin
								state <= idle;
							end
						end

						// ps2_clk is high, check if all the bits have been read
						// if, last bit read, check parity, and if parity ok
						// load received data into rx_data.
						// else if more bits left, then wait for the ps2_clk to
						// go low
						rx_clk_h : begin
							if(bit_count == NUMBITS) begin
								if(~(rx_parity == frame[PARITY_BIT])) begin
									state <= rx_error_parity;
								end
								else begin
									load_rx_data <= 1'b1;
									state <= rx_data_ready;
								end
							end
							else if(ps2_clk_s == 1'b0) begin
								state <= rx_down_edge;
							end
							else begin
								state <= rx_clk_h;
							end
						end

						// data must be read into frame in this state
						// the ps2_clk just transitioned from high to low
						rx_down_edge : begin
							state <= rx_clk_l;
						end

						// ps2_clk line is low, wait for it to go high
						rx_clk_l : begin
							if(ps2_clk_s == 1'b1) begin
								state <= rx_clk_h;
							end
							else begin
								state <= rx_clk_l;
							end
						end

						// parity bit received is invalid
						// signal error and go back to idle.
						rx_error_parity : begin
							err <= 1'b1;
							state <= idle;
						end

						// parity bit received was good
						// set read signal for the client to know
						// a new byte was received and is available on rx_data
						rx_data_ready : begin
							read <= 1'b1;
							state <= idle;
						end

						// the client wishes to transmit a byte to the device
						// this is done by holding ps2_clk down for at least 100us
						// bringing down ps2_data, wait 20us and then releasing
						// the ps2_clk.
						// This constitutes a request to send command.
						// In this state, the ps2_clk line is held down and
						// the counter for waiting 100us is eanbled.
						// when the counter reached upper limit, transition
						// to tx_bring_data_down
						tx_force_clk_l : begin
							load_tx_data <= 1'b1;
							ps2_clk_h <= 1'b0;

							if(delay_100us_done == 1'b1) begin
								state <= tx_bring_data_down;
							end
							else begin
								state <= tx_force_clk_l;
							end
						end

						// with the ps2_clk line low bring ps2_data low
						// wait for 20us and then go to tx_release_clk
						tx_bring_data_down : begin
							// keep clock line low
							ps2_clk_h <= 1'b0;
							// set data line low
							// when clock is released in the next state
							// the device will read bit 0 on data line
							// and this bit represents the start bit.
							ps2_data_h <= 1'b0;   // start bit = '0'
							if(delay_20us_done == 1'b1) begin
								state <= tx_release_clk;
							end
							else begin
								state <= tx_bring_data_down;
							end
						end

						// release the ps2_clk line
						// keep holding data line low
						tx_release_clk : begin
							ps2_clk_h <= 1'b1;
							// must maintain data low,
							// otherwise will be released by default value
							ps2_data_h <= 1'b0;
							state <= tx_first_wait_down_edge;
						end

						// state is necessary because the clock signal
						// is not released instantaneously and, because of debounce,
						// delay is even greater.
						// Wait 63 clock periods for the clock line to release
						// then if clock is low then go to tx_clk_l
						// else wait until ps2_clk goes low.
						tx_first_wait_down_edge : begin
							ps2_data_h <= 1'b0;
							if(delay_63clk_done == 1'b1) begin
								if(ps2_clk_s == 1'b0) begin
									state <= tx_clk_l;
								end
								else begin
									state <= tx_first_wait_down_edge;
								end
							end
							else begin
								state <= tx_first_wait_down_edge;
							end
						end

						// place the least significant bit from frame
						// on the data line
						// During this state the frame is shifted one
						// bit to the right
						tx_clk_l : begin
							ps2_data_h <= frame[0];
							state <= tx_wait_up_edge;
						end

						// wait for the clock to go high
						// this is the edge on which the device reads the data
						// on ps2_data.
						// keep holding ps2_data on frame(0) because else
						// will be released by default value.
						// Check if sent the last bit and if so, release data line
						// and go to state that wait for acknowledge
						tx_wait_up_edge : begin
							ps2_data_h <= frame[0];
							// NUMBITS - 1 because first (start bit = 0) bit was read
							// when the clock line was released in the request to
							// send command (see tx_bring_data_down state).
							if(bit_count == (NUMBITS-1'b1)) begin
								ps2_data_h <= 1'b1;
								state <= tx_wait_up_edge_before_ack;
							end
							// if more bits to send, wait for the up edge
							// of ps2_clk
							else if(ps2_clk_s == 1'b1) begin
								state <= tx_clk_h;
							end
							else begin
								state <= tx_wait_up_edge;
							end
						end

						// ps2_clk is released, wait for down edge
						// and go to tx_clk_l when arrived
						tx_clk_h : begin
							ps2_data_h <= frame[0];
							if(ps2_clk_s == 1'b0) begin
								state <= tx_clk_l;
							end
							else begin
								state <= tx_clk_h;
							end
						end

						// release ps2_data and wait for rising edge of ps2_clk
						// once this occurs, transition to tx_wait_ack
						tx_wait_up_edge_before_ack : begin
							ps2_data_h <= 1'b1;
							if(ps2_clk_s == 1'b1) begin
								state <= tx_wait_ack;
							end
							else begin
								state <= tx_wait_up_edge_before_ack;
							end
						end
						
						// wait for the falling edge of the clock line
						// if data line is low when this occurs, the
						// ack is received
						// else if data line is high, the device did not
						// acknowledge the transimission
						tx_wait_ack : begin
							if(ps2_clk_s == 1'b0) begin
								if(ps2_data_s == 1'b0) begin
									// acknowledge received
									state <= tx_received_ack;
								end
								else begin
									// acknowledge not received
									state <= tx_error_no_ack;
								end
							end
							else begin
								state <= tx_wait_ack;
							end
						end

						// wait for ps2_clk to be released together with ps2_data
						// (bus to be idle) and go back to idle state
						tx_received_ack : begin
							if(ps2_clk_s == 1'b1 && ps2_data_s == 1'b1) begin
								state  <= idle;
							end
							else begin
								state <= tx_received_ack;
							end
						end

						// wait for ps2_clk to be released together with ps2_data
						// (bus to be idle) and go back to idle state
						// signal error for not receiving ack
						tx_error_no_ack : begin
							if(ps2_clk_s == 1'b1 && ps2_data_s == 1'b1) begin
								err <= 1'b1;
								state  <= idle;
							end
							else begin
								state <= tx_error_no_ack;
							end
						end

						// if invalid transition occurred, signal error and
						// go back to idle state
						default : begin
							err <= 1'b1;
							state  <= idle;
						end

					endcase
				end
			end



			//-------------------------------------------------------------------
			// DELAY COUNTERS
			//-------------------------------------------------------------------

			// Enable the 100us counter only when state is tx_force_clk_l
			assign delay_100us_counter_enable = (state == tx_force_clk_l) ? 1'b1 : 1'b0;

			// Counter for a 100us delay
			// after done counting, done signal remains active until
			// enable counter is reset.
			always @(posedge clk) begin
					if(delay_100us_counter_enable == 1'b1) begin
						if(delay_100us_count == (DELAY_100US)) begin
							delay_100us_count <= delay_100us_count;
							delay_100us_done <= 1'b1;
						end
						else begin
							delay_100us_count <= delay_100us_count + 1'b1;
							delay_100us_done <= 1'b0;
						end
					end
					else begin
						delay_100us_count <= 14'd0;
						delay_100us_done <= 1'b0;
					end
			end

			// Enable the 20us counter only when state is tx_bring_data_down
			assign delay_20us_counter_enable = (state == tx_bring_data_down) ? 1'b1 : 1'b0; 

			// Counter for a 20us delay
			// after done counting, done signal remains active until
			// enable counter is reset.
			always @(posedge clk) begin
					if(delay_20us_counter_enable == 1'b1) begin
						if(delay_20us_count == (DELAY_20US)) begin
							delay_20us_count <= delay_20us_count;
							delay_20us_done <= 1'b1;
						end
						else begin
							delay_20us_count <= delay_20us_count + 1'b1;
							delay_20us_done <= 1'b0;
						end
					end
					else begin
						delay_20us_count <= 11'd0;
						delay_20us_done <= 1'b0;
					end
			end

			// Enable the 63clk counter only when state is tx_first_wait_down_edge
			assign delay_63clk_counter_enable = (state == tx_first_wait_down_edge) ? 1'b1 : 1'b0;

			// Counter for a 63 clock periods delay
			// after done counting, done signal remains active until
			// enable counter is reset.
			always @(posedge clk) begin
					if(delay_63clk_counter_enable == 1'b1) begin
						if(delay_63clk_count == (DELAY_63CLK)) begin
							delay_63clk_count <= delay_63clk_count;
							delay_63clk_done <= 1'b1;
						end
						else begin
							delay_63clk_count <= delay_63clk_count + 1'b1;
							delay_63clk_done <= 1'b0;
						end
					end
					else begin
						delay_63clk_count <= 6'd0;
						delay_63clk_done <= 1'b0;
					end
			end

			//-------------------------------------------------------------------
			// BIT COUNTER AND FRAME SHIFTING LOGIC
			//-------------------------------------------------------------------

			// counts the number of bits shifted into the frame
			// or out of the frame.
			always @(posedge clk) begin
					if(reset_bit_count == 1'b1) begin
						bit_count <= 4'd0;
					end
					else if(shift_frame == 1'b1) begin
						bit_count <= bit_count + 1'b1;
					end
			end

			// shifts frame with one bit to right when shift_frame is acitve
			// and loads data into frame from tx_data then load_tx_data is high
			always @(posedge clk) begin
					if(load_tx_data == 1'b1) begin
						frame[8:1] <= tx_data;       			// byte to send
						frame[0] <= 1'b0;                   // start bit
						frame[10] <= 1'b1;                  // stop bit
						frame[9] <= tx_parity;              // parity bit
					end
					else if(shift_frame == 1'b1) begin
						// shift right 1 bit
						frame[9:0] <= frame[10:1];
						// shift in from the ps2_data line
						frame[10] <= ps2_data_s;
					end
			end

			// Loads data from frame into rx_data output when data is ready
			always @(posedge clk) begin
					if(load_rx_data == 1'b1) begin
						rx_data <= frame[8:1];
					end
			end

endmodule
