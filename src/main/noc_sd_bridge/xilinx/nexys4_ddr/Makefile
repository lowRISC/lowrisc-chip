# ../../../../chip/tile/ariane/src/axi_mem_if/src/axi2mem.sv
#../../../../chip/tile/ariane/src/axi/src/axi_pkg.sv 
#../../../../chip/tile/ariane/include/axi_intf.sv 
V = \
../../rtl/piton_sd_top_tb.sv \
../../rtl/byte_en_reg.v \
../../rtl/cdc_bits.v \
../../rtl/cdc_pulse.v \
../../rtl/piton_sd_buffer.v \
../../rtl/piton_sd_init.v \
../../rtl/piton_sd_top.v \
../../rtl/piton_sd_transaction_manager.v \
../../rtl/sdc_controller.v \
../../rtl/sd_clock_divider.v \
../../rtl/sd_cmd_master.v \
../../rtl/sd_cmd_serial_host.v \
../../rtl/sd_controller_wb.v \
../../rtl/sd_crc_16.v \
../../rtl/sd_crc_7.v \
../../rtl/sd_data_master.v \
../../rtl/sd_data_serial_host.v \
../../rtl/sd_data_xfer_trig.v \
../../rtl/sd_fifo_filler.v \
../../rtl/sd_wb_sel_ctrl.v \
ip_cores/sd_ctrl_fifo/sd_ctrl_fifo_sim_netlist.v \
ip_cores/sd_data_fifo/sd_data_fifo_sim_netlist.v \
ip_cores/sd_cache_bram/sd_cache_bram_sim_netlist.v \
../../rtl/sd_verilator_model.sv \

simv: $V
	vcs -full64 -sverilog +incdir+../../../../include -timescale=1ns/1ps +incdir+../../rtl -y $(XILINX_VIVADO)/data/verilog/src/unisims/ +libext+.v -y $(XILINX_VIVADO)/data/verilog/src/retarget $V

clean:
	rm -rf simv simv.daidir
