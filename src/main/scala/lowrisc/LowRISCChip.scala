// See LICENSE.Cambridge for license details.

package freechips.rocketchip.lowrisc

import Chisel._
import chisel3.core.{Input, Output, attach, Param, IntParam}
import chisel3.experimental.{RawModule, withClockAndReset}
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.coreplex._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.diplomacy.LazyModule

// the Application core complex for lowRISC SoC
class LoRCCoreplex(implicit p: Parameters) extends RocketCoreplex
    with HasAsyncExtInterrupts
    with HasMasterAXI4MemPort
    with HasMasterAXI4MMIOPort
    with HasSlaveAXI4Port
    with HasSystemErrorSlave {
  override lazy val module = new LoRCCoreplexModule(this)
}

class LoRCCoreplexModule[+L <: LoRCCoreplex](_outer: L) extends RocketCoreplexModule(_outer)
    with HasRTCModuleImp
    with HasExtInterruptsModuleImp
    with HasMasterAXI4MemPortModuleImp
    with HasMasterAXI4MMIOPortModuleImp
    with HasSlaveAXI4PortModuleImp

class CoreplexTop()(implicit p: Parameters) extends RawModule {

  val coreplex = LazyModule(new LoRCCoreplex)
  val clk = IO(Input(Clock()))
  val rst = IO(Input(Bool()))
  val interrupts = IO(UInt(INPUT, width = coreplex.nExtInterrupts))
  val mem = IO(coreplex.mem_axi4.bundleOut.cloneType)
  val mmio_master = IO(coreplex.mmio_axi4.bundleOut.cloneType)
  val mmio_slave = IO(Flipped(coreplex.l2FrontendAXI4Node.bundleIn.cloneType))

  withClockAndReset(clk, rst) {
    val rocket = Module(coreplex.module)
    rocket.interrupts <> interrupts
    mem <> rocket.mem_axi4
    mmio_master <> rocket.mmio_axi4
    rocket.l2_frontend_bus_axi4 <> mmio_slave
  }
}
