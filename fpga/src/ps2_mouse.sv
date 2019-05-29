//-------------------------------------------------------------------------------------
//
// Author: John Clayton
// Date  : April 30, 2001
// Update: 4/30/01 copied this file from lcd_2.v (pared down).
// Update: 5/24/01 changed the first module from "ps2_keyboard_receiver"
//                 to "ps2_keyboard_interface"
// Update: 5/29/01 Added input synchronizing flip-flops.  Changed state
//                 encoding (m1) for good operation after part config.
// Update: 5/31/01 Added low drive strength and slow transitions to ps2_clk
//                 and ps2_data in the constraints file.  Added the signal
//                 "tx_shifting_done" as distinguished from "rx_shifting_done."
//                 Debugged the transmitter portion in the lab.
// Update: 6/01/01 Added horizontal tab to the ascii output.
// Update: 6/01/01 Added parameter TRAP_SHIFT_KEYS.
// Update: 6/05/01 Debugged the "debounce" timer functionality.
//                 Used 60usec timer as a "watchdog" timeout during
//                 receive from the keyboard.  This means that a keyboard
//                 can now be "hot plugged" into the interface, without
//                 messing up the bit_count, since the bit_count is reset
//                 to zero during periods of inactivity anyway.  This was
//                 difficult to debug.  I ended up using the logic analyzer,
//                 and had to scratch my head quite a bit.
// Update: 6/06/01 Removed extra comments before the input synchronizing
//                 flip-flops.  Used the correct parameter to size the
//                 5usec_timer_count.  Changed the name of this file from
//                 ps2.v to ps2_keyboard.v
// Update: 6/06/01 Removed "&& q[7:0]" in output_strobe logic.  Removed extra
//                 commented out "else" condition in the shift register and
//                 bit counter.
// Update: 6/07/01 Changed default values for 60usec timer parameters so that
//                 they correspond to 60usec for a 49.152MHz clock.
//
//
//
//
//
// Description
//-------------------------------------------------------------------------------------
// This is a state-machine driven serial-to-parallel and parallel-to-serial
// interface to the ps2 style keyboard interface.  The details of the operation
// of the keyboard interface were obtained from the following website:
//
//   http://www.beyondlogic.org/keyboard/keybrd.htm
//
// Some aspects of the keyboard interface are not implemented (e.g, parity
// checking for the receive side, and recognition of the various commands
// which the keyboard sends out, such as "power on selt test passed," "Error"
// and "Resend.")  However, if the user wishes to recognize these reply
// messages, the scan code output can always be used to extend functionality
// as desired.
//
// Note that the "Extended" (0xE0) and "Released" (0xF0) codes are recognized.
// The rx interface provides separate indicator flags for these two conditions
// with every valid character scan code which it provides.  The shift keys are
// also trapped by the interface, in order to provide correct uppercase ASCII
// characters at the ascii output, although the scan codes for the shift keys
// are still provided at the scan code output.  So, the left/right ALT keys
// can be differentiated by the presence of the rx_entended signal, while the
// left/right shift keys are differentiable by the different scan codes
// received.
//
// The interface to the ps2 keyboard uses ps2_clk clock rates of
// 30-40 kHz, dependent upon the keyboard itself.  The rate at which the state
// machine runs should be at least twice the rate of the ps2_clk, so that the
// states can accurately follow the clock signal itself.  Four times
// oversampling is better.  Say 200kHz at least.  The upper limit for clocking
// the state machine will undoubtedly be determined by delays in the logic
// which decodes the scan codes into ASCII equivalents.  The maximum speed
// will be most likely many megahertz, depending upon target technology.
// In order to run the state machine extremely fast, synchronizing flip-flops
// have been added to the ps2_clk and ps2_data inputs of the state machine.
// This avoids poor performance related to slow transitions of the inputs.
//
// Because this is a bi-directional interface, while reading from the keyboard
// the ps2_clk and ps2_data lines are used as inputs.  While writing to the
// keyboard, however (which may be done at any time.  If writing interrupts a
// read from the keyboard, the keyboard will buffer up its data, and send
// it later) both the ps2_clk and ps2_data lines are occasionally pulled low,
// and pullup resistors are used to bring the lines high again, by setting
// the drivers to high impedance state.
//
// The tx interface, for writing to the keyboard, does not provide any special
// pre-processing.  It simply transmits the 8-bit command value to the
// keyboard.
//
// Pullups MUST BE USED on the ps2_clk and ps2_data lines for this design,
// whether they be internal to an FPGA I/O pad, or externally placed.
// If internal pullups are used, they may be fairly weak, causing bounces
// due to crosstalk, etc.  There is a "debounce timer" implemented in order
// to eliminate erroneous state transitions which would occur based on bounce.
//
// Parameters are provided in order to configure and appropriately size the
// counter of a 60 microsecond timer used in the transmitter, depending on
// the clock frequency used.  The 60 microsecond period is guaranteed to be
// more than one period of the ps2_clk_s signal.
//
// Also, a smaller 5 microsecond timer has been included for "debounce".
// This is used because, with internal pullups on the ps2_clk and ps2_data
// lines, there is some bouncing around which occurs
//
// A parameter TRAP_SHIFT_KEYS allows the user to eliminate shift keypresses
// from producing scan codes (along with their "undefined" ASCII equivalents)
// at the output of the interface.  If TRAP_SHIFT_KEYS is non-zero, the shift
// key status will only be reported by rx_shift_key_on.  No ascii or scan
// codes will be reported for the shift keys.  This is useful for those who
// wish to use the ASCII data stream, and who don't want to have to "filter
// out" the shift key codes.
//
//-------------------------------------------------------------------------------------


// synopsys translate_off
`resetall
`include "timescale.v"
// synopsys translate_on
`define TOTAL_BITS   11

module ps2_mouse (
  clk,
  reset,
  ps2_clk_en_o_,
  ps2_data_en_o_,
  ps2_clk_i,
  ps2_data_i,
  rx_scan_code,
  rx_data_ready,       // rx_read_o
  rx_read,             // rx_read_ack_i
  tx_data,
  tx_write,
  tx_write_ack_o,
  tx_error_no_ack,
  divide_reg_i
  );

// Parameters

// The timer value can be up to (2^bits) inclusive.
parameter TIMER_60USEC_VALUE_PP = 2950; // Number of sys_clks for 60usec.
parameter TIMER_60USEC_BITS_PP  = 12;   // Number of bits needed for timer
parameter TIMER_5USEC_VALUE_PP = 186;   // Number of sys_clks for debounce
parameter TIMER_5USEC_BITS_PP  = 8;     // Number of bits needed for timer

// State encodings, provided as parameters
// for flexibility to the one instantiating the module.
// In general, the default values need not be changed.

// State "m1_rx_clk_l" has been chosen on purpose.  Since the input
// synchronizing flip-flops initially contain zero, it takes one clk
// for them to update to reflect the actual (idle = high) status of
// the I/O lines from the keyboard.  Therefore, choosing 0 for m1_rx_clk_l
// allows the state machine to transition to m1_rx_clk_h when the true
// values of the input signals become present at the outputs of the
// synchronizing flip-flops.  This initial transition is harmless, and it
// eliminates the need for a "reset" pulse before the interface can operate.

parameter m1_rx_clk_h = 1;
parameter m1_rx_clk_l = 0;
parameter m1_rx_falling_edge_marker = 13;
parameter m1_rx_rising_edge_marker = 14;
parameter m1_tx_force_clk_l = 3;
parameter m1_tx_first_wait_clk_h = 10;
parameter m1_tx_first_wait_clk_l = 11;
parameter m1_tx_reset_timer = 12;
parameter m1_tx_wait_clk_h = 2;
parameter m1_tx_clk_h = 4;
parameter m1_tx_clk_l = 5;
parameter m1_tx_wait_ack = 6;
parameter m1_tx_done_recovery = 7;
parameter m1_tx_error_no_ack = 8;
parameter m1_tx_rising_edge_marker = 9;
parameter m2_rx_data_ready = 1;
parameter m2_rx_data_ready_ack = 0;


// I/O declarations
input clk;
input reset;
output ps2_clk_en_o_ ;
output ps2_data_en_o_ ;
input  ps2_clk_i ;
input  ps2_data_i ;
output [7:0] rx_scan_code;
output rx_data_ready;
input rx_read;
input [7:0] tx_data;
input tx_write;
output tx_write_ack_o;
output tx_error_no_ack;

input [15:0] divide_reg_i;

reg rx_released;
reg [7:0] rx_scan_code;
reg rx_data_ready;
reg tx_error_no_ack;

// Internal signal declarations
wire timer_60usec_done;
wire timer_5usec_done;
reg timer_done ;
reg timer_5usec ;
                         // NOTE: These two signals used to be one.  They
                         //       were split into two signals because of
                         //       shift key trapping.  With shift key
                         //       trapping, no event is generated externally,
                         //       but the "hold" data must still be cleared
                         //       anyway regardless, in preparation for the
                         //       next scan codes.
wire rx_output_event;    // Used only to clear: hold_released, hold_extended
wire rx_output_strobe;   // Used to produce the actual output.

wire tx_parity_bit;
wire rx_shifting_done;
wire tx_shifting_done;

reg [`TOTAL_BITS-1:0] q;
reg [3:0] m1_state;
reg [3:0] m1_next_state;
reg m2_state;
reg m2_next_state;
reg [3:0] bit_count;
reg enable_timer_60usec;
reg enable_timer_5usec;
reg [TIMER_60USEC_BITS_PP-1:0] timer_60usec_count;
reg [TIMER_5USEC_BITS_PP-1:0] timer_5usec_count;
reg ps2_clk_s;        // Synchronous version of this input
reg ps2_data_s;       // Synchronous version of this input
reg ps2_clk_hi_z;     // Without keyboard, high Z equals 1 due to pullups.
reg ps2_data_hi_z;    // Without keyboard, high Z equals 1 due to pullups.

reg ps2_clk_ms;
reg ps2_data_ms;

//--------------------------------------------------------------------------
// Module code

assign ps2_clk_en_o_  = ps2_clk_hi_z  ;
assign ps2_data_en_o_ = ps2_data_hi_z ;

// Input "synchronizing" logic -- synchronizes the inputs to the state
// machine clock, thus avoiding errors related to
// spurious state machine transitions.
always @(posedge clk)
begin
  ps2_clk_ms <= #1 ps2_clk_i;
  ps2_data_ms <= #1 ps2_data_i;

  ps2_clk_s <= #1 ps2_clk_ms;
  ps2_data_s <= #1 ps2_data_ms;

end

// State register
always @(posedge clk)
begin : m1_state_register
  if (reset) m1_state <= #1 m1_rx_clk_h;
  else m1_state <= #1 m1_next_state;
end

// State transition logic
always @(m1_state
         or q
         or tx_shifting_done
         or tx_write
         or ps2_clk_s
         or ps2_data_s
         or timer_60usec_done
         or timer_5usec_done
         )
begin : m1_state_logic

  // Output signals default to this value, unless changed in a state condition.
  ps2_clk_hi_z <= #1 1;
  ps2_data_hi_z <= #1 1;
  tx_error_no_ack <= #1 0;
  enable_timer_60usec <= #1 0;
  enable_timer_5usec <= #1 0;

  case (m1_state)

    m1_rx_clk_h :
      begin
        enable_timer_60usec <= #1 1;
        if (tx_write) m1_next_state <= #1 m1_tx_reset_timer;
        else if (~ps2_clk_s) m1_next_state <= #1 m1_rx_falling_edge_marker;
        else m1_next_state <= #1 m1_rx_clk_h;
      end

    m1_rx_falling_edge_marker :
      begin
        enable_timer_60usec <= #1 0;
        m1_next_state <= #1 m1_rx_clk_l;
      end

    m1_rx_rising_edge_marker :
      begin
        enable_timer_60usec <= #1 0;
        m1_next_state <= #1 m1_rx_clk_h;
      end


    m1_rx_clk_l :
      begin
        enable_timer_60usec <= #1 1;
        if (tx_write) m1_next_state <= #1 m1_tx_reset_timer;
        else if (ps2_clk_s) m1_next_state <= #1 m1_rx_rising_edge_marker;
        else m1_next_state <= #1 m1_rx_clk_l;
      end

    m1_tx_reset_timer:
      begin
        enable_timer_60usec <= #1 0;
        m1_next_state <= #1 m1_tx_force_clk_l;
      end

    m1_tx_force_clk_l :
      begin
        enable_timer_60usec <= #1 1;
        ps2_clk_hi_z <= #1 0;  // Force the ps2_clk line low.
        if (timer_60usec_done) m1_next_state <= #1 m1_tx_first_wait_clk_h;
        else m1_next_state <= #1 m1_tx_force_clk_l;
      end

    m1_tx_first_wait_clk_h :
      begin
        enable_timer_5usec <= #1 1;
        ps2_data_hi_z <= #1 0;        // Start bit.
        if (~ps2_clk_s && timer_5usec_done)
          m1_next_state <= #1 m1_tx_clk_l;
        else
          m1_next_state <= #1 m1_tx_first_wait_clk_h;
      end

    // This state must be included because the device might possibly
    // delay for up to 10 milliseconds before beginning its clock pulses.
    // During that waiting time, we cannot drive the data (q[0]) because it
    // is possibly 1, which would cause the keyboard to abort its receive
    // and the expected clocks would then never be generated.
    m1_tx_first_wait_clk_l :
      begin
        ps2_data_hi_z <= #1 0;
        if (~ps2_clk_s) m1_next_state <= #1 m1_tx_clk_l;
        else m1_next_state <= #1 m1_tx_first_wait_clk_l;
      end

    m1_tx_wait_clk_h :
      begin
        enable_timer_5usec <= #1 1;
        ps2_data_hi_z <= #1 q[0];
        if (ps2_clk_s && timer_5usec_done)
          m1_next_state <= #1 m1_tx_rising_edge_marker;
        else
          m1_next_state <= #1 m1_tx_wait_clk_h;
      end

    m1_tx_rising_edge_marker :
      begin
        ps2_data_hi_z <= #1 q[0];
        m1_next_state <= #1 m1_tx_clk_h;
      end

    m1_tx_clk_h :
      begin
        ps2_data_hi_z <= #1 q[0];
        if (tx_shifting_done) m1_next_state <= #1 m1_tx_wait_ack;
        else if (~ps2_clk_s) m1_next_state <= #1 m1_tx_clk_l;
        else m1_next_state <= #1 m1_tx_clk_h;
      end

    m1_tx_clk_l :
      begin
        ps2_data_hi_z <= #1 q[0];
        if (ps2_clk_s) m1_next_state <= #1 m1_tx_wait_clk_h;
        else m1_next_state <= #1 m1_tx_clk_l;
      end

    m1_tx_wait_ack :
      begin
        if (~ps2_clk_s && ps2_data_s)
          m1_next_state <= #1 m1_tx_error_no_ack;
        else if (~ps2_clk_s && ~ps2_data_s)
          m1_next_state <= #1 m1_tx_done_recovery;
        else m1_next_state <= #1 m1_tx_wait_ack;
      end

    m1_tx_done_recovery :
      begin
        if (ps2_clk_s && ps2_data_s) m1_next_state <= #1 m1_rx_clk_h;
        else m1_next_state <= #1 m1_tx_done_recovery;
      end

    m1_tx_error_no_ack :
      begin
        tx_error_no_ack <= #1 1;
        if (ps2_clk_s && ps2_data_s) m1_next_state <= #1 m1_rx_clk_h;
        else m1_next_state <= #1 m1_tx_error_no_ack;
      end

    default : m1_next_state <= #1 m1_rx_clk_h;
  endcase
end

// State register
always @(posedge clk)
begin : m2_state_register
  if (reset) m2_state <= #1 m2_rx_data_ready_ack;
  else m2_state <= #1 m2_next_state;
end

// State transition logic
always @(m2_state or rx_output_strobe or rx_read)
begin : m2_state_logic
  case (m2_state)
    m2_rx_data_ready_ack:
          begin
            rx_data_ready <= #1 1'b0;
            if (rx_output_strobe) m2_next_state <= #1 m2_rx_data_ready;
            else m2_next_state <= #1 m2_rx_data_ready_ack;
          end
    m2_rx_data_ready:
          begin
            rx_data_ready <= #1 1'b1;
            if (rx_read) m2_next_state <= #1 m2_rx_data_ready_ack;
            else m2_next_state <= #1 m2_rx_data_ready;
          end
    default : m2_next_state <= #1 m2_rx_data_ready_ack;
  endcase
end

// This is the bit counter
always @(posedge clk)
begin
  if (   reset
      || rx_shifting_done
      || (m1_state == m1_tx_wait_ack)        // After tx is done.
      ) bit_count <= #1 0;  // normal reset
  else if (timer_60usec_done
           && (m1_state == m1_rx_clk_h)
           && (ps2_clk_s)
      ) bit_count <= #1 0;  // rx watchdog timer reset
  else if ( (m1_state == m1_rx_falling_edge_marker)   // increment for rx
           ||(m1_state == m1_tx_rising_edge_marker)   // increment for tx
           )
    bit_count <= #1 bit_count + 1;
end
// This signal is high for one clock at the end of the timer count.
assign rx_shifting_done = (bit_count == `TOTAL_BITS);
assign tx_shifting_done = (bit_count == `TOTAL_BITS-1);

// This is the signal which enables loading of the shift register.
// It also indicates "ack" to the device writing to the transmitter.
assign tx_write_ack_o = (  (tx_write && (m1_state == m1_rx_clk_h))
                         ||(tx_write && (m1_state == m1_rx_clk_l))
                         );

// This is the ODD parity bit for the transmitted word.
assign tx_parity_bit = ~^tx_data;

// This is the shift register
always @(posedge clk)
begin
  if (reset) q <= #1 0;
  else if (tx_write_ack_o) q <= #1 {1'b1,tx_parity_bit,tx_data,1'b0};
  else if ( (m1_state == m1_rx_falling_edge_marker)
           ||(m1_state == m1_tx_rising_edge_marker) )
    q <= #1 {ps2_data_s,q[`TOTAL_BITS-1:1]};
end

// This is the 60usec timer counter
always @(posedge clk)
begin
  if (~enable_timer_60usec) timer_60usec_count <= #1 0;
  else if ( timer_done && !timer_60usec_done)
         timer_60usec_count<= #1 timer_60usec_count +1;
  end
assign timer_60usec_done = (timer_60usec_count == (TIMER_60USEC_VALUE_PP ));



always @(posedge clk or posedge reset)
if (reset) timer_5usec <= #1 1;
else if (!enable_timer_60usec) timer_5usec <= #1 1;
else if (timer_5usec == divide_reg_i)
 begin
   timer_5usec <= #1 1;
   timer_done  <= #1 1;
  end
else
  begin
    timer_5usec<= #1 timer_5usec +1;
    timer_done  <= #1 0;
 end

// This is the 5usec timer counter
always @(posedge clk)
begin
  if (~enable_timer_5usec) timer_5usec_count <= #1 0;
  else if (~timer_5usec_done) timer_5usec_count <= #1 timer_5usec_count + 1;
end
assign timer_5usec_done = (timer_5usec_count == divide_reg_i - 1);

always @(posedge clk)
begin
  if (reset)
  begin
    rx_scan_code <= #1 0;
  end
  else if (rx_output_strobe)
  begin
    rx_scan_code <= #1 q[8:1];
  end
end

// Store the final rx output data only when all extend and release codes
// are received and the next (actual key) scan code is also ready.
// (the presence of rx_extended or rx_released refers to the
// the current latest scan code received, not the previously latched flags.)
assign rx_output_event  = rx_shifting_done ;

assign rx_output_strobe = rx_shifting_done ;

endmodule
