`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Ulrich Zoltán
// 
// Create Date:    09/18/2006
// Module Name:    mouse_controller
// Project Name: 	 PmodPS2_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.2
// Description: Please read the article found at the link provided below for details on
// 				 how to interface a ps/2 mouse:
//
// 				 http://www.computer-engineering.org/ps2mouse/
//
// 				 This controller is implemented as described in the above article.
// 				 The mouse controller receives bytes from the ps2interface which, in
// 				 turn, receives them from the mouse device. Data is received on the
// 				 rx_data input port, and is validated by the read signal. read is
// 				 active for one clock period when new byte available on rx_data. Data
// 				 is sent to the ps2interface on the tx_data output port and validated
// 				 by the write output signal. 'write' should be active for one clock
// 				 period when tx_data contains the command or data to be sent to the
// 				 mouse. ps2interface wraps the byte in a 11 bits packet that is sent
// 				 through the ps/2 port using the ps/2 protocol. Similarly, when the
// 				 mouse sends data, the ps2interface receives 11 bits for every byte,
// 				 extracts the byte from the ps/2 frame, puts it on rx_data and
// 				 activates read for one clock period. If an error occurs when sending
// 				 or receiving a frame from the mouse, the err input goes high for one
// 				 clock period. When this occurs, the controller enters reset state.
//
// 				 When in reset state, the controller resets the mouse and begins an
// 				 initialization procedure that consists of tring to put mouse in
// 				 scroll mode (enables wheel if the mouse has one), setting the
// 				 resolution of the mouse, the sample rate and finally enables
// 				 reporting. Implicitly the mouse, after a reset or imediately after a
// 				 reset, does not send data packets on its own. When reset(or power-up)
// 				 the mouse enters reset state, where it performs a test, called the
// 				 bat test (basic assurance test), when this test is done, it sends
// 				 the result: AAh for test ok, FCh for error. After this it sends its
// 				 ID which is 00h. When this is done, the mouse enters stream mode,
// 				 but with reporting disabled (movement data packets are not sent).
// 				 To enable reporting the enable data reporting command (F4h) must be
// 				 sent to the mouse. After this command is sent, the mouse will send
// 				 movement data packets when the mouse is moved or the status of the
// 				 button changes.
//
// 				 After sending a command or a byte following a command, the mouse
// 				 must respond with ack (FAh). For managing the intialization
// 				 procedure and receiving the movement data packets, a FSM is used.
// 				 When the fpga is powered up or the logic is reset using the global
// 				 reset, the FSM enters reset state. From this state, the FSM will
// 				 transition to a series of states used to initialize the mouse. When
// 				 initialization is complete, the FSM remains in state read_byte_1,
// 				 waiting for a movement data packet to be sent. This is the idle
// 				 state if the FSM. When a byte is received in this state, this is
// 				 the first byte of the 3 bytes sent in a movement data packet (4 bytes
// 				 if mouse in scrolling mode). After reading the last byte from the
// 				 packet, the FSM enters mark_new_event state and sets new_event high.
// 				 After that FSM enterss read_byte_1 state, resets new_event and waits
// 				 for a new packet.
// 				 After a packet is received, new_event is set high for one clock
// 				 period to "inform" the clients of this controller a new packet was
// 				 received and processed.
//
// 				 During the initialization procedure, the controller tries to put the
// 				 mouse in scroll mode (activates wheel, if mouse has one). This is
// 				 done by successively setting the sample rate to 200, then to 100, and
// 				 lastly to 80. After this is done, the mouse ID is requested by 
// 				 sending get device ID command (F2h). If the received ID is 00h than
// 				 the mouse does not have a wheel. If the received ID is 03h than the
// 				 mouse is in scroll mode, and when sending movement data packets
// 				 (after enabling data reporting) it will include z movement data.
// 				 If the mouse is in normal, non-scroll mode, the movement data packet
// 				 consists of 3 successive bytes. This is their format:
//
//
//
// 				 bits      7     6     5     4     3     2     1     0
// 				        -------------------------------------------------
// 				 byte 1 | YOVF| XOVF|YSIGN|XSIGN|  1  | MBTN| RBTN| LBTN|
// 				        -------------------------------------------------
// 				        -------------------------------------------------
// 				 byte 2 |                  X MOVEMENT                   |
// 				        -------------------------------------------------
// 				        -------------------------------------------------
// 				 byte 3 |                  Y MOVEMENT                   |
//  				       -------------------------------------------------
// 				 OVF = overflow
// 				 BTN = button
// 				 M = middle
// 				 R = right
// 				 L = left
//
// 				 When scroll mode is enabled, the mouse send 4 byte movement packets.
// 				 bits      7     6     5     4     3     2     1     0
// 				        -------------------------------------------------
// 				 byte 1 | YOVF| XOVF|YSIGN|XSIGN|  1  | MBTN| RBTN| LBTN|
// 				        -------------------------------------------------
// 				        -------------------------------------------------
// 				 byte 2 |                  X MOVEMENT                   |
// 				        -------------------------------------------------
// 				        -------------------------------------------------
// 				 byte 3 |                  Y MOVEMENT                   |
// 				        -------------------------------------------------
// 				        -------------------------------------------------
// 				 byte 4 |                  Z MOVEMENT                   |
// 				        -------------------------------------------------
// 				 x and y movement counters are represented on 8 bits, 2's complement
// 				 encoding. The first bit (sign bit) of the counters are the xsign and
// 				 ysign bit from the first packet, the rest of the bits are the second
// 				 byte for the x movement and the third byte for y movement. For the
// 				 z movement the range is -8 -> +7 and only the 4 least significant
// 				 bits from z movement are valid, the rest are sign extensions.
// 				 The x and y movements are in range: -256 -> +255
//
// 				 The mouse uses as axes origin the lower-left corner. For the purpose
// 				 of displaying a mouse cursor on the screen, the controller inverts
// 				 the y axis to move the axes origin in the upper-left corner. This
// 				 is done by negating the y movement value (following the 2s complement
// 				 encoding). The movement data received from the mouse are delta
// 				 movements, the data represents the movement of the mouse relative
// 				 to the last position. The controller keeps track of the position of
// 				 the mouse relative to the upper-left corner. This is done by keeping
// 				 the mouse position in two registers x_pos and y_pos and adding the
// 				 delta movements to their value. The addition uses saturation. That
// 				 means the value of the mouse position will not exceed certain bounds
// 				 and will not rollover the a margin. For example, if the mouse is at
// 				 the left margin and is moved left, the x position remains at the left
// 				 margin(0). The lower bound is always 0 for both x and y movement.
// 				 The upper margin can be set using input pins: value, setmax_x,
// 				 setmax_y. To set the upper bound of the x movement counter, the new
// 				 value is placed on the value input pins and setmax_x is activated
// 				 for at least one clock period. Similarly for y movement counter, but
// 				 setmax_y is activated instead. Notice that value has 10 bits, and so
// 				 the maximum value for a bound is 1023.
//
// 				 The position of the mouse (x_pos and y_pos) can be set at any time,
// 				 by placing the x or y position on the value input pins and activating
// 				 the setx, or sety respectively, for at least one clock period. This
// 				 is useful for setting an original position of the mouse different
// 				 from (0,0).
//				 ----------------------------------------------------------------------
//  				 Port definitions
//				 ----------------------------------------------------------------------
// 				 clk            - global clock signal (100MHz)
// 				 rst            - global reset signal
// 				 read           - input pin, from ps2interface
// 				                - active one clock period when new data received
// 				                - and available on rx_data
// 				 err            - input pin, from ps2interface
// 				                - active one clock period when error occurred when
// 				                - receiving or sending data.
// 				 rx_data        - input pin, 8 bits, from ps2interface
// 				                - the byte received from the mouse.
// 				 xpos           - output pin, 10 bits
// 				                - the x position of the mouse relative to the upper
// 				                - left corner
// 				 ypos           - output pin, 10 bits
// 				                - the y position of the mouse relative to the upper
// 				                - left corner
// 				 zpos           - output pin, 4 bits
// 				                - last delta movement on z axis
// 				 left           - output pin, high if the left mouse button is pressed
// 				 middle         - output pin, high if the middle mouse button is
// 				                - pressed
// 				 right          - output pin, high if the right mouse button is
// 				                - pressed
// 				 new_event      - output pin, active one clock period after receiving
// 				                - and processing one movement data packet.
// 				 tx_data        - output pin, 8 bits, to ps2interface
// 				                - byte to be sent to the mouse
// 				 write          - output pin, to ps2interface
// 				                - active one clock period when sending a byte to the
// 				                - ps2interface.
//
// Revision History: 
//							Revision 0.00 - File created (UlrichZ)
//							Revision 1.00 - Default resolution to 800x600 (MichelleY)
//							Revision 1.01 - Added Comments and Converted to Verilog (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
// 										  Define Module
// =======================================================================================
module mouse_controller(
    clk,
    rst,
    read,
    err,
    rx_data,
    value,
    setx,
    sety,
    setmax_x,
    setmax_y,
    xpos,
    ypos,
    zpos,
    left,
    middle,
    right,
    new_event,
    tx_data,
    write
    );


// =======================================================================================
// 										Port Declarations
// =======================================================================================

			 input clk;
			 input rst;
			 input read;
			 input err;
			 input [7:0] rx_data;
			 input [9:0] value;
			 input setx;
			 input sety;
			 input setmax_x;
			 input setmax_y;
			 output [9:0] xpos;
			 output [9:0] ypos;
			 output [3:0] zpos;
			 output left;
			 output middle;
			 output right;
			 output new_event;
			 output [7:0] tx_data;
			 output write;



// =======================================================================================
// 							  Parameters, Registers, and Wires
// =======================================================================================

			// Outputs
			reg [9:0] xpos;
			reg [9:0] ypos;
			reg [3:0] zpos;
			reg left;
			reg middle;
			reg right;
			reg new_event;
			reg [7:0] tx_data;
			reg write;

			// constants defining commands to send or received from the mouse
			parameter [7:0] FA = 8'b11111010; // 0xFA(ACK)
			parameter [7:0] FF = 8'b11111111; // 0xFF(RESET)
			parameter [7:0] AA = 8'b10101010; // 0xAA(BAT_OK)
			parameter [7:0] OO = 8'b00000000; // 0x00(ID)
			// (atention: name is 2 letters O not zero)

			// command to read id
			parameter [7:0] READ_ID = 8'hF2;
			// command to enable mouse reporting
			// after this command is sent, the mouse begins sending data packets
			parameter [7:0] ENABLE_REPORTING = 8'hF4;
			// command to set the mouse resolution
			parameter [7:0] SET_RESOLUTION = 8'hE8;
			// the value of the resolution to send after sending SET_RESOLUTION
			parameter [7:0] RESOLUTION = 8'h03;
																			  // (8 counts/mm)
			// command to set the mouse sample rate
			parameter [7:0] SET_SAMPLE_RATE = 8'hF3;

			// the value of the sample rate to send after sending SET_SAMPLE_RATE
			parameter [7:0] SAMPLE_RATE = 8'h28;
																			  // (40 samples/s)

			// default maximum value for the horizontal mouse position
			parameter [9:0] DEFAULT_MAX_X = 10'b1001111111;
																					// 639
			// default maximum value for the vertical mouse position
			parameter [9:0] DEFAULT_MAX_Y = 10'b0111011111;
																					// 479


			// after doing the enable scroll mouse procedure, if the ID returned by
			// the mouse is 03 (scroll mouse enabled) then this register will be set
			// If '1' then the mouse is in scroll mode, else mouse is in simple
			// mouse mode.
			reg haswheel = 1'b0;

			// horizontal and veritcal mouse position
			// origin of axes is upper-left corner
			// the origin of axes the mouse uses is the lower-left corner
			// The y-axis is inverted, by making negative the y movement received
			// from the mouse (if it was positive it becomes negative
			// and vice versa)
			reg [10:0] x_pos = 11'b00101000000;
			reg [10:0] y_pos = 11'b00011110000;

			// active when an overflow occurred on the x and y axis
			// bits 6 and 7 from the first byte received from the mouse
			reg x_overflow = 1'b0;
			reg y_overflow = 1'b0;

			// active when the x,y movement is negative
			// bits 4 and 5 from the first byte received from the mouse
			reg x_sign = 1'b0;
			reg y_sign = 1'b0;

			// 2's complement value for incrementing the x_pos,y_pos
			// y_inc is the negated value from the mouse in the third byte
			reg [7:0] x_inc = 8'h00;
			reg [7:0] y_inc = 8'h00;

			// active for one clock period, indicates new delta movement received
			// on x,y axis
			reg x_new = 1'b0;
			reg y_new = 1'b0;

			// maximum value for x and y position registers(x_pos,y_pos)
			reg [9:0] x_max;
			reg [9:0] y_max;
			
			// active when left,middle,right mouse button is down
			reg left_down = 1'b0;
			reg middle_down = 1'b0;
			reg right_down = 1'b0;

			// the FSM states
			// states that begin with "reset" are part of the reset procedure.
			// states that end in "_wait_ack" are states in which ack is waited
			// as response to sending a byte to the mouse.
			// read behavioral description above for details.
			parameter [5:0]  fsm_state_reset = 0,
								  fsm_state_reset_wait_ack = 1,
								  fsm_state_reset_wait_bat_completion = 2,
								  fsm_state_reset_wait_id = 3,
								  fsm_state_reset_set_sample_rate_200 = 4,
								  fsm_state_reset_set_sample_rate_200_wait_ack = 5,
								  fsm_state_reset_send_sample_rate_200 = 6,
								  fsm_state_reset_send_sample_rate_200_wait_ack = 7,
								  fsm_state_reset_set_sample_rate_100 = 8,
								  fsm_state_reset_set_sample_rate_100_wait_ack = 9,
								  fsm_state_reset_send_sample_rate_100 = 10,
								  fsm_state_reset_send_sample_rate_100_wait_ack = 11,
								  fsm_state_reset_set_sample_rate_80 = 12,
								  fsm_state_reset_set_sample_rate_80_wait_ack = 13,
								  fsm_state_reset_send_sample_rate_80 = 14,
								  fsm_state_reset_send_sample_rate_80_wait_ack = 15,
								  fsm_state_reset_read_id = 16,
								  fsm_state_reset_read_id_wait_ack = 17,
								  fsm_state_reset_read_id_wait_id = 18,
								  fsm_state_reset_set_resolution = 19,
								  fsm_state_reset_set_resolution_wait_ack = 20,
								  fsm_state_reset_send_resolution = 21,
								  fsm_state_reset_send_resolution_wait_ack = 22,
								  fsm_state_reset_set_sample_rate_40 = 23,
								  fsm_state_reset_set_sample_rate_40_wait_ack = 24,
								  fsm_state_reset_send_sample_rate_40 = 25,
								  fsm_state_reset_send_sample_rate_40_wait_ack = 26,
								  fsm_state_reset_enable_reporting = 27,
								  fsm_state_reset_enable_reporting_wait_ack = 28,
								  fsm_state_read_byte_1 = 29,
								  fsm_state_read_byte_2 = 30,
								  fsm_state_read_byte_3 = 31,
								  fsm_state_read_byte_4 = 32,
								  fsm_state_mark_new_event = 33;
						
					// holds current state of the FSM
					reg [5:0] state = fsm_state_reset;

// =======================================================================================
// 							  		   Implementation
// =======================================================================================

			// left output the state of the left_down register   
			always @(posedge clk) begin
					left <= left_down;
			end

			// middle output the state of the middle_down register
			always @(posedge clk) begin
					middle <= middle_down;
			end

			// right output the state of the right_down register
			always @(posedge clk) begin
					right <= right_down;
			end


			// xpos output is the horizontal position of the mouse
			// it has the range: 0-x_max
			always @(posedge clk) begin
					xpos <= x_pos[9:0];
			end

			// ypos output is the vertical position of the mouse
			// it has the range: 0-y_max
			always @(posedge clk) begin
					ypos <= y_pos[9:0];
			end


			always @(posedge clk)begin: set_x
				reg [10:0]       x_inter;
				reg [10:0]       inc;
				begin
					// if setx active, set new x_pos value
					if (setx == 1'b1)
						x_pos <= {1'b0, value};
					// if delta movement received from mouse
					else if (x_new == 1'b1)
					begin
						// if negative movement on x axis
						if (x_sign == 1'b1)
						begin
							// if overflow occurred
							if (x_overflow == 1'b1)
								// inc is -256
								inc = 11'b11100000000;
							else
								// inc is sign extended x_inc
								inc = {3'b111, x_inc};
							// intermediary horizontal position
							x_inter = x_pos + inc;
							// if first bit of x_inter is 1
							// then negative overflow occurred and
							// new x position is 0.
							// Note: x_pos and x_inter have 11 bits,
							// and because xpos has only 10, when
							// first bit becomes 1, this is considered
							// a negative number when moving left
							if (x_inter[10] == 1'b1)
								x_pos <= 1'b0;
							else
								x_pos <= x_inter;
						end
						else
						begin
							// if positive movement on x axis
							// if overflow occurred
							if (x_overflow == 1'b1)
								// inc is 256
								inc = 11'b00100000000;
							else
								// inc is sign extended x_inc
								inc = {3'b000, x_inc};
							// intermediary horizontal position
							x_inter = x_pos + inc;
							// if x_inter is greater than x_max
							// then positive overflow occurred and
							// new x position is x_max.
							if (x_inter > ({1'b0, x_max}))
								x_pos <= {1'b0, x_max};
							else
								x_pos <= x_inter;
						end
					end
				end
			end
			
			// sets the value of y_pos from another module when sety is active
			// else, computes the new y_pos from the old position when new y
			// movement detected by adding the delta movement in y_inc, or by
			// adding 256 or -256 when overflow occurs.
			
			always @(posedge clk) begin: set_y
				reg [10:0]       y_inter;
				reg [10:0]       inc;
				begin
					// if sety active, set new y_pos value
					if (sety == 1'b1) begin
						y_pos <= {1'b0, value};
					end
					// if delta movement received from mouse
					else if (y_new == 1'b1) begin
						// if negative movement on y axis
						// Note: axes origin is upper-left corner
						if (y_sign == 1'b1) begin
							// if overflow occurred
							if (y_overflow == 1'b1) begin
								// inc is -256
								inc = 11'b11100000000;
							end
							else begin
								// inc is sign extended y_inc
								inc = {3'b111, y_inc};
							end
							// intermediary vertical position
							y_inter = y_pos + inc;
							// if first bit of y_inter is 1
							// then negative overflow occurred and
							// new y position is 0.
							// Note: y_pos and y_inter have 11 bits,
							// and because ypos has only 10, when
							// first bit becomes 1, this is considered
							// a negative number when moving upward
							if (y_inter[10] == 1'b1) begin
								y_pos <= 1'b0;
							end
							else begin
								y_pos <= y_inter;
							end
						end
						else begin
							// if positive movement on y axis
							// if overflow occurred
							if (y_overflow == 1'b1) begin
								// inc is 256
								inc = 11'b00100000000;
							end
							else begin
								// inc is sign extended y_inc
								inc = {3'b000, y_inc};
							end
							// intermediary vertical position
							y_inter = y_pos + inc;
							// if y_inter is greater than y_max
							// then positive overflow occurred and
							// new y position is y_max.
							if (y_inter > ({1'b0, y_max})) begin
								y_pos <= {1'b0, y_max};
							end
							else begin
								y_pos <= y_inter;
							end
						end
					end
				end
			end
			
			// sets the maximum value of the x movement register, stored in x_max
			// when setmax_x is active, max value should be on value input pin
			
			always @(posedge clk or posedge rst)
			begin: set_max_x
				begin
					if (rst == 1'b1)
						x_max <= DEFAULT_MAX_X;
					else if (setmax_x == 1'b1)
						x_max <= value;
				end
			end
			
			// sets the maximum value of the y movement register, stored in y_max
			// when setmax_y is active, max value should be on value input pin
			
			always @(posedge clk or posedge rst)
			begin: set_max_y
				begin
					if (rst == 1'b1)
						y_max <= DEFAULT_MAX_Y;
					else if (setmax_y == 1'b1)
						y_max <= value;
				end
			end
			
			// Synchronous one process fsm to handle the communication
			// with the mouse.
			// When reset and at start-up it enters reset state
			// where it begins the procedure of initializing the mouse.
			// After initialization is complete, it waits packets from
			// the mouse.
			// Read at Behavioral decription for details.
			
			always @(posedge clk or posedge rst)
			begin: manage_fsm
				// when reset occurs, give signals default values.
				if (rst == 1'b1)
				begin
					state <= fsm_state_reset;
					haswheel <= 1'b0;
					x_overflow <= 1'b0;
					y_overflow <= 1'b0;
					x_sign <= 1'b0;
					y_sign <= 1'b0;
					x_inc <= 1'b0;
					y_inc <= 1'b0;
					x_new <= 1'b0;
					y_new <= 1'b0;
					new_event <= 1'b0;
					left_down <= 1'b0;
					middle_down <= 1'b0;
					right_down <= 1'b0;
				end
				
				else
				begin
					
					// at every rising edge of the clock, this signals
					// are reset, thus assuring that they are active
					// for one clock period only if a state sets then
					// because the fsm will transition from the state
					// that set them on the next rising edge of clock.
					write <= 1'b0;
					x_new <= 1'b0;
					y_new <= 1'b0;
					
					case (state)
						
						// if just powered-up, reset occurred or some error in
						// transmision encountered, then fsm will transition to
						// this state. Here the RESET command (FF) is sent to the
						// mouse, and various signals receive their default values
						// From here the FSM transitions to a series of states that
						// perform the mouse initialization procedure. All this
						// state are prefixed by "reset_". After sending a byte
						// to the mouse, it respondes by sending ack (FA). All
						// states that wait ack from the mouse are postfixed by
						// "_wait_ack".
						// Read at Behavioral decription for details.
						fsm_state_reset :
							begin
								haswheel <= 1'b0;
								x_overflow <= 1'b0;
								y_overflow <= 1'b0;
								x_sign <= 1'b0;
								y_sign <= 1'b0;
								x_inc <= 1'b0;
								y_inc <= 1'b0;
								x_new <= 1'b0;
								y_new <= 1'b0;
								left_down <= 1'b0;
								middle_down <= 1'b0;
								right_down <= 1'b0;
								tx_data <= FF;
								write <= 1'b1;
								state <= fsm_state_reset_wait_ack;
							end
						
						// wait ack for the reset command.
						// when received transition to reset_wait_bat_completion.
						// if error occurs go to reset state.
						fsm_state_reset_wait_ack :
							if (read == 1'b1)
							begin
								// if received ack
								if (rx_data == FA)
									state <= fsm_state_reset_wait_bat_completion;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_wait_ack;
						
						// wait for bat completion test
						// mouse should send AA if test is successful
						fsm_state_reset_wait_bat_completion :
							if (read == 1'b1)
							begin
								if (rx_data == AA)
									state <= fsm_state_reset_wait_id;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_wait_bat_completion;
						
						// the mouse sends its id after performing bat test
						// the mouse id should be 00
						fsm_state_reset_wait_id :
							if (read == 1'b1)
							begin
								if (rx_data == OO)
									state <= fsm_state_reset_set_sample_rate_200;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_wait_id;
						
						// with this state begins the enable wheel mouse
						// procedure. The procedure consists of setting
						// the sample rate of the mouse first 200, then 100
						// then 80. After this is done, the mouse id is
						// requested and if the mouse id is 03, then
						// mouse is in wheel mode and will send 4 byte packets
						// when reporting is enabled.
						// If the id is 00, the mouse does not have a wheel
						// and will send 3 byte packets when reporting is enabled.
						// This state issues the set_sample_rate command to the
						// mouse.
						fsm_state_reset_set_sample_rate_200 :
							begin
								tx_data <= SET_SAMPLE_RATE;
								write <= 1'b1;
								state <= fsm_state_reset_set_sample_rate_200_wait_ack;
							end
						
						// wait ack for set sample rate command
						fsm_state_reset_set_sample_rate_200_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_send_sample_rate_200;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_set_sample_rate_200_wait_ack;
						
						// send the desired sample rate (200 = 0xC8)
						fsm_state_reset_send_sample_rate_200 :
							begin
								tx_data <= 8'b11001000;		// 0xC8
								write <= 1'b1;
								state <= fsm_state_reset_send_sample_rate_200_wait_ack;
							end
						
						// wait ack for sending the sample rate
						fsm_state_reset_send_sample_rate_200_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_set_sample_rate_100;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_send_sample_rate_200_wait_ack;
						
						// send the sample rate command
						fsm_state_reset_set_sample_rate_100 :
							begin
								tx_data <= SET_SAMPLE_RATE;
								write <= 1'b1;
								state <= fsm_state_reset_set_sample_rate_100_wait_ack;
							end
						
						// wait ack for sending the sample rate command
						fsm_state_reset_set_sample_rate_100_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_send_sample_rate_100;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_set_sample_rate_100_wait_ack;
						
						// send the desired sample rate (100 = 0x64)
						fsm_state_reset_send_sample_rate_100 :
							begin
								tx_data <= 8'b01100100;		// 0x64
								write <= 1'b1;
								state <= fsm_state_reset_send_sample_rate_100_wait_ack;
							end
						
						// wait ack for sending the sample rate
						fsm_state_reset_send_sample_rate_100_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_set_sample_rate_80;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_send_sample_rate_100_wait_ack;
						
						// send set sample rate command
						fsm_state_reset_set_sample_rate_80 :
							begin
								tx_data <= SET_SAMPLE_RATE;
								write <= 1'b1;
								state <= fsm_state_reset_set_sample_rate_80_wait_ack;
							end
						
						// wait ack for sending the sample rate command
						fsm_state_reset_set_sample_rate_80_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_send_sample_rate_80;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_set_sample_rate_80_wait_ack;
						
						// send desired sample rate (80 = 0x50)
						fsm_state_reset_send_sample_rate_80 :
							begin
								tx_data <= 8'b01010000;		// 0x50
								write <= 1'b1;
								state <= fsm_state_reset_send_sample_rate_80_wait_ack;
							end
						
						// wait ack for sending the sample rate
						fsm_state_reset_send_sample_rate_80_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_read_id;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_send_sample_rate_80_wait_ack;
						
						// now the procedure for enabling wheel mode is done
						// the mouse id is read to determine is mouse is in
						// wheel mode.
						// Read ID command is sent to the mouse.
						fsm_state_reset_read_id :
							begin
								tx_data <= READ_ID;
								write <= 1'b1;
								state <= fsm_state_reset_read_id_wait_ack;
							end
						
						// wait ack for sending the read id command
						fsm_state_reset_read_id_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_read_id_wait_id;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_read_id_wait_ack;
						
						// received the mouse id
						// if the id is 00, then the mouse does not have
						// a wheel and haswheel is reset
						// if the id is 03, then the mouse is in scroll mode
						// and haswheel is set.
						// if anything else is received or an error occurred
						// then the FSM transitions to reset state.
						fsm_state_reset_read_id_wait_id :
							if (read == 1'b1)
							begin
								if (rx_data == 9'b000000000)
								begin
									// the mouse does not have a wheel
									haswheel <= 1'b0;
									state <= fsm_state_reset_set_resolution;
								end
								else if (rx_data == 8'b00000011)		// 0x03
								begin
									// the mouse is in scroll mode
									haswheel <= 1'b1;
									state <= fsm_state_reset_set_resolution;
								end
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_read_id_wait_id;
						
						// send the set resolution command to the mouse
						fsm_state_reset_set_resolution :
							begin
								tx_data <= SET_RESOLUTION;
								write <= 1'b1;
								state <= fsm_state_reset_set_resolution_wait_ack;
							end
						
						// wait ack for sending the set resolution command
						fsm_state_reset_set_resolution_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_send_resolution;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_set_resolution_wait_ack;
						
						// send the desired resolution (0x03 = 8 counts/mm)
						fsm_state_reset_send_resolution :
							begin
								tx_data <= RESOLUTION;
								write <= 1'b1;
								state <= fsm_state_reset_send_resolution_wait_ack;
							end
						
						// wait ack for sending the resolution
						fsm_state_reset_send_resolution_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_set_sample_rate_40;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_send_resolution_wait_ack;
						
						// send the set sample rate command
						fsm_state_reset_set_sample_rate_40 :
							begin
								tx_data <= SET_SAMPLE_RATE;
								write <= 1'b1;
								state <= fsm_state_reset_set_sample_rate_40_wait_ack;
							end
						
						// wait ack for sending the set sample rate command
						fsm_state_reset_set_sample_rate_40_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_send_sample_rate_40;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_set_sample_rate_40_wait_ack;
						
						// send the desired sampele rate.
						// 40 samples per second is sent.
						fsm_state_reset_send_sample_rate_40 :
							begin
								tx_data <= SAMPLE_RATE;
								write <= 1'b1;
								state <= fsm_state_reset_send_sample_rate_40_wait_ack;
							end
						
						// wait ack for sending the sample rate
						fsm_state_reset_send_sample_rate_40_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_reset_enable_reporting;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_send_sample_rate_40_wait_ack;
						
						// in this state enable reporting command is sent
						// to the mouse. Before this point, the mouse
						// does not send packets. Only after issuing this
						// command, the mouse begins sending data packets,
						// 3 byte packets if it doesn't have a wheel and
						// 4 byte packets if it is in scroll mode.
						fsm_state_reset_enable_reporting :
							begin
								tx_data <= ENABLE_REPORTING;
								write <= 1'b1;
								state <= fsm_state_reset_enable_reporting_wait_ack;
							end
						
						// wait ack for sending the enable reporting command
						fsm_state_reset_enable_reporting_wait_ack :
							if (read == 1'b1)
							begin
								if (rx_data == FA)
									state <= fsm_state_read_byte_1;
								else
									state <= fsm_state_reset;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_reset_enable_reporting_wait_ack;
						
						// this is idle state of the FSM after the
						// initialization is complete.
						// Here the first byte of a packet is waited.
						// The first byte contains the state of the
						// buttons, the sign of the x and y movement
						// and overflow information about these movements
						// First byte looks like this:
						//    7       6        5        4      3   2   1   0
						//----------------------------------------------------
						// | Y OVF | X OVF | Y SIGN | X SIGN | 1 | M | R | L |
						//----------------------------------------------------
						fsm_state_read_byte_1 :
							begin
								// reset new_event when back in idle state.
								new_event <= 1'b0;
								// reset last z delta movement
								zpos <= 1'b0;
								if (read == 1'b1)
								begin
									// mouse button states
									left_down <= rx_data[0];
									middle_down <= rx_data[2];
									right_down <= rx_data[1];
									// sign of the movement data
									x_sign <= rx_data[4];
									// y sign is changed to invert the y axis
									// because the mouse uses the lower-left corner
									// as axes origin and it is placed in the upper-left
									// corner by this inversion (suitable for displaying
									// a mouse cursor on the screen).
									// y movement data from the third packet must be
									// also negated.
									y_sign <= (~rx_data[5]);
									
									// overflow status of the x and y movement
									x_overflow <= rx_data[6];
									y_overflow <= rx_data[7];
									
									// transition to state read_byte_2
									state <= fsm_state_read_byte_2;
								end
								else
									// no byte received yet.
									state <= fsm_state_read_byte_1;
							end
						
						// wait the second byte of the packet
						// this byte contains the x movement counter.
						fsm_state_read_byte_2 :
							if (read == 1'b1)
							begin
								// put the delta movement in x_inc
								x_inc <= rx_data;
								// signal the arrival of new x movement data.
								x_new <= 1'b1;
								// go to state read_byte_3.
								state <= fsm_state_read_byte_3;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								// byte not received yet.
								state <= fsm_state_read_byte_2;
						
						// wait the third byte of the data, that
						// contains the y data movement counter.
						// negate its value, for the axis to be
						// inverted.
						// If mouse is in scroll mode, transition
						// to read_byte_4, else go to mark_new_event
						fsm_state_read_byte_3 :
							if (read == 1'b1)
							begin
								// when y movement is 0, then ignore
								if (rx_data != 8'b00000000)
								begin
									// 2's complement positive numbers
									// become negative and vice versa
									y_inc <= ((~rx_data)) + 8'b00000001;
									y_new <= 1'b1;
								end
								// if the mouse has a wheel then transition
								// to read_byte_4, else go to mark_new_event
								if (haswheel == 1'b1)
									state <= fsm_state_read_byte_4;
								else
									state <= fsm_state_mark_new_event;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_read_byte_3;
						
						// only reached when mouse is in scroll mode
						// wait for the fourth byte to arrive
						// fourth byte contains the z movement counter
						// only least significant 4 bits are relevant
						// the rest are sign extension.
						fsm_state_read_byte_4 :
							if (read == 1'b1)
							begin
								// zpos is the delta movement on z
								zpos <= rx_data[3:0];
								// packet completly received,
								// go to mark_new_event
								state <= fsm_state_mark_new_event;
							end
							else if (err == 1'b1)
								state <= fsm_state_reset;
							else
								state <= fsm_state_read_byte_4;
						
						// set new_event high
						// it will be reset in next state
						// informs client new packet received and processed
						fsm_state_mark_new_event :
							begin
								new_event <= 1'b1;
								state <= fsm_state_read_byte_1;
							end
						
						// if invalid transition occurred, reset
						default :
							state <= fsm_state_reset;
					endcase
				end
			end

endmodule
