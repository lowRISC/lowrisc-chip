# root path
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(dir $(mkfile_path))

# Sources
# Package files -> compile first
ariane_pkg :=             ariane/include/riscv_pkg.sv                          \
			  ariane/src/riscv-dbg/src/dm_pkg.sv                   \
			  ariane/include/ariane_pkg.sv                         \
			  ariane/include/std_cache_pkg.sv                      \
			  ariane/include/wt_cache_pkg.sv                       \
			  ariane/src/axi/src/axi_pkg.sv                        \
			  ariane/src/register_interface/src/reg_intf.sv        \
			  ariane/src/register_interface/src/reg_intf_pkg.sv    \
			  ariane/include/axi_intf.sv                           \
			  fpga/src/ariane_soc_pkg.sv                           \
			  ariane/include/ariane_axi_pkg.sv                     \
			  ariane/src/fpu/src/fpnew_pkg.sv                      \
                          ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv \
                          src/OpenIP/axi/common.sv

ariane_pkg := $(addprefix $(root-dir)/, $(ariane_pkg))

# utility modules
util := include/instr_tracer_pkg.sv                         \
        src/util/instr_tracer_if.sv                         \
        src/util/instr_tracer.sv                            \
        src/tech_cells_generic/src/cluster_clock_gating.sv  \
        src/util/sram.sv

util := $(addprefix $(root-dir)/ariane/, $(util))

# this list contains the standalone components
src :=  $(filter-out ariane/src/ariane_regfile.sv, $(wildcard ariane/src/*.sv))              \
        $(filter-out ariane/src/fpu/src/fpnew_pkg.sv, $(wildcard ariane/src/fpu/src/*.sv))   \
        $(filter-out ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,    \
        $(wildcard ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                     \
        $(wildcard ariane/src/frontend/*.sv)                                          \
        $(filter-out ariane/src/cache_subsystem/std_no_dcache.sv,                     \
        $(wildcard ariane/src/cache_subsystem/*.sv))                                  \
        $(wildcard ariane/src/clint/*.sv)                                             \
        $(filter-out ariane/fpga/src/axi2apb/src/axi2apb_wrap.sv, $(wildcard ariane/fpga/src/axi2apb/src/*.sv)) \
        $(wildcard ariane/fpga/src/axi_slice/src/*.sv)                                \
        $(wildcard ariane/src/axi_node/src/*.sv)                                      \
        $(wildcard ariane/src/axi_riscv_atomics/src/*.sv)                             \
        $(wildcard ariane/src/axi_mem_if/src/*.sv)                                    \
        ariane/src/rv_plic/rtl/rv_plic_target.sv                                      \
        ariane/src/rv_plic/rtl/rv_plic_gateway.sv                                     \
        ariane/src/rv_plic/rtl/plic_regmap.sv                                         \
        ariane/src/rv_plic/rtl/plic_top.sv                                            \
        ariane/src/riscv-dbg/src/dmi_cdc.sv                                           \
        ariane/src/riscv-dbg/src/dmi_jtag.sv                                          \
        ariane/src/riscv-dbg/src/dmi_jtag_tap.sv                                      \
        ariane/src/riscv-dbg/src/dm_csrs.sv                                           \
        ariane/src/riscv-dbg/src/dm_mem.sv                                            \
        ariane/src/riscv-dbg/src/dm_sba.sv                                            \
        ariane/src/riscv-dbg/src/dm_top.sv                                            \
        ariane/src/riscv-dbg/debug_rom/debug_rom.sv                                   \
        ariane/src/register_interface/src/apb_to_reg.sv                               \
        ariane/src/axi/src/axi_multicut.sv                                            \
        ariane/src/common_cells/src/deprecated/generic_fifo.sv                        \
        ariane/src/common_cells/src/deprecated/pulp_sync.sv                           \
        ariane/src/common_cells/src/rstgen_bypass.sv                                  \
        ariane/src/common_cells/src/rstgen.sv                                         \
        ariane/src/common_cells/src/stream_mux.sv                                     \
        ariane/src/common_cells/src/stream_demux.sv                                   \
        ariane/src/util/axi_master_connect.sv                                         \
        ariane/src/util/axi_slave_connect.sv                                          \
        ariane/src/util/axi_master_connect_rev.sv                                     \
        ariane/src/util/axi_slave_connect_rev.sv                                      \
        ariane/src/axi/src/axi_cut.sv                                                 \
        ariane/src/axi/src/axi_join.sv                                                \
        ariane/src/axi/src/axi_delayer.sv                                             \
        ariane/src/axi/src/axi_to_axi_lite.sv                                         \
        ariane/src/fpga-support/rtl/SyncSpRamBeNx64.sv                                \
        ariane/src/common_cells/src/unread.sv                                         \
        ariane/src/common_cells/src/sync.sv                                           \
        ariane/src/common_cells/src/cdc_2phase.sv                                     \
        ariane/src/common_cells/src/spill_register.sv                                 \
        ariane/src/common_cells/src/sync_wedge.sv                                     \
        ariane/src/common_cells/src/edge_detect.sv                                    \
        ariane/src/common_cells/src/stream_arbiter.sv                                 \
        ariane/src/common_cells/src/stream_arbiter_flushable.sv                       \
        ariane/src/common_cells/src/deprecated/fifo_v1.sv                             \
        ariane/src/common_cells/src/deprecated/fifo_v2.sv                             \
        ariane/src/common_cells/src/fifo_v3.sv                                        \
        ariane/src/common_cells/src/lzc.sv                                            \
        ariane/src/common_cells/src/popcount.sv                                       \
        ariane/src/common_cells/src/rr_arb_tree.sv                                    \
        ariane/src/common_cells/src/deprecated/rrarbiter.sv                           \
        ariane/src/common_cells/src/stream_delay.sv                                   \
        ariane/src/common_cells/src/lfsr_8bit.sv                                      \
        ariane/src/common_cells/src/lfsr_16bit.sv                                     \
        ariane/src/common_cells/src/counter.sv                                        \
        ariane/src/common_cells/src/shift_reg.sv                                      \
        ariane/src/tech_cells_generic/src/pulp_clock_gating.sv                        \
        ariane/src/tech_cells_generic/src/cluster_clock_inverter.sv                   \
        ariane/src/tech_cells_generic/src/pulp_clock_mux2.sv                          \
        fpga/src/ariane_shell.sv                                                      \

src := $(addprefix $(root-dir)/, $(src))

rocket_src := rocket-chip/vsim/generated-src/freechips.rocketchip.system.DefaultConfig.v \
	      rocket-chip/vsim/generated-src/freechips.rocketchip.system.DefaultConfig.behav_srams.v \
	      rocket-chip/vsrc/AsyncResetReg.v \
	      rocket-chip/vsrc/ClockDivider2.v \
	      rocket-chip/vsrc/ClockDivider3.v \
	      rocket-chip/vsrc/plusarg_reader.v \
              fpga/src/rocket_shell.sv \

rocket_src := $(addprefix $(root-dir)/, $(rocket_src))

open_src := $(filter-out src/OpenIP/axi/common.sv                         \
			src/OpenIP/axi/dummy_slave.sv                     \
			src/OpenIP/axi/dummy_master.sv                    \
			src/OpenIP/axi/id_downsizer.sv                    \
			src/OpenIP/axi/from_lite.sv                       \
			src/OpenIP/axi/crossbar.sv                        \
			src/OpenIP/axi/buf.sv                             \
			src/OpenIP/axi/mux.sv                             \
			src/OpenIP/axi/join.sv,                           \
                        $(wildcard src/OpenIP/axi/*.sv))                  \
        $(filter-out src/OpenIP/util/from_if.sv                           \
			src/OpenIP/util/to_if.sv                          \
			src/OpenIP/util/axi_xbar_rework.sv                \
			src/OpenIP/util/async_fifo.sv                     \
			src/OpenIP/util/axi_xbar_wrapper.sv               \
			src/OpenIP/util/axi_xbar_rework_wrapper.sv,       \
                        $(wildcard src/OpenIP/util/*.sv))                 \

open_src := $(addprefix $(root-dir), $(open_src))

fpga_src := $(filter-out fpga/src/ariane_shell.sv \
                         fpga/src/rocket_shell.sv \
                         fpga/src/boom_shell.sv, $(wildcard fpga/src/*.sv)) \
            $(wildcard fpga/src/apb_uart/src/*.sv) \
            $(wildcard fpga/src/ariane-ethernet/*.sv) \
            $(wildcard fpga/src/spi_mem_programmer/*.sv)

fpga_src := $(addprefix $(root-dir)/, $(fpga_src))

fpga_filter := $(addprefix $(root-dir), src/util/instruction_tracer.sv)

sim_src := fpga/xilinx/xlnx_clk_sd/ip/xlnx_clk_sd_sim_netlist.v \
	   fpga/xilinx/xlnx_axi_clock_converter/ip/xlnx_axi_clock_converter_sim_netlist.v \
	   fpga/xilinx/xlnx_axi_gpio/ip/xlnx_axi_gpio_sim_netlist.v \
	   fpga/xilinx/xlnx_clk_$(BOARD)/ip/xlnx_clk_$(BOARD)_sim_netlist.v \
	   fpga/xilinx/xlnx_mig_7_ddr_$(BOARD)/ip/xlnx_mig_7_ddr_$(BOARD)_sim_netlist.v \
	   fpga/xilinx/xlnx_axi_quad_spi/ip/xlnx_axi_quad_spi_sim_netlist.v \
	   fpga/xilinx/xlnx_axi_dwidth_converter/ip/xlnx_axi_dwidth_converter_sim_netlist.v \
           fpga/xilinx/xilinx_stubs.sv

