// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import junctions._
import uncore._
import rocket._
import rocket.Util._

abstract trait TopLevelParameters extends UsesParameters {
  val nTiles = params(NTiles)
  val nBanks = params(NBanks)
  val bankLSB = params(BankIdLSB)
  val bankMSB = bankLSB + log2Up(nBanks) - 1
  require(isPow2(nBanks))
  require(bankMSB < params(TLBlockAddrBits))
  val tlDataBeats = params(TLDataBeats)
}

class TopIO extends Bundle {
  val nasti       = Bundle(new NASTIMasterIO, {case BusId => "nasti"})
  val nasti_lite  = Bundle(new NASTILiteMasterIO, {case BusId => "lite"})
  val host        = new HostIO
  val interrupt   = UInt(INPUT, params(XLen))
}

class Top extends Module with TopLevelParameters {
  val io = new TopIO

  // Rocket Tiles
  val tiles = (0 until nTiles) map { i =>
    Module(new RocketTile(i), {case TLId => "L1ToL2"})
  }

  // PCR controller
  val pcrControl = Module(new PCRControl)
  pcrControl.io.host <> io.host
  pcrControl.io.interrupt <> io.interrupt
  pcrControl.io.pcr_req <> (tiles.map(_.io.pcr.req))
  (0 until nTiles) foreach { i =>
    tiles(i).io.soft_reset := pcrControl.io.soft_reset
    tiles(i).io.pcr.resp := pcrControl.io.pcr_resp
    tiles(i).io.pcr.update := pcrControl.io.pcr_update
    tiles(i).io.irq := pcrControl.io.irq(i)
  }

  // The crossbar between tiles and L2
  def routeL1ToL2(addr: UInt) = if(nBanks > 1) addr(bankMSB,bankLSB) else UInt(0)
  def routeL2ToL1(id: UInt) = id
  val l2Network = Module(new TileLinkCrossbar(
    routeL1ToL2, routeL2ToL1, tlDataBeats,
    TileLinkDepths(2,2,2,2,2),
    TileLinkDepths(0,0,1,0,0)   //Berkeley: TODO: had EOS24 crit path on inner.release
  ), {case TLId => "L1ToL2"})

  l2Network.io.clients <> (tiles.map(_.io.cached) ++ 
                           tiles.map(_.io.uncached).map(TileLinkIOWrapper(_, params.alterPartial({case TLId => "L1ToL2"}))))

  // L2 Banks
  val banks = (0 until nBanks) map { _ =>
    Module(new L2HellaCacheBank, {
      case CacheName => "L2Bank"
      case InnerTLId => "L1ToL2"
      case OuterTLId => "L2ToTC"
      case TLId => "L1ToL2"   // dummy
    })
  }

  l2Network.io.managers <> banks.map(_.innerTL)
  banks.foreach(_.incoherent := UInt(0))
  banks.foreach(_.io.soft_reset := pcrControl.io.soft_reset)

  // the network between L2 and tag cache
  def routeL2ToTC(addr: UInt) = UInt(0)
  def routeTCToL2(id: UInt) = id
  val tcNetwork = Module(new TileLinkCrossbar(routeL2ToTC, routeTCToL2, tlDataBeats), {case TLId => "L2ToTC"})

  tcNetwork.io.clients <> banks.map(_.outerTL)

  // tag cache
  //val tc = Module(new TagCache, {case TLId => "L2ToTC"; case CacheName => "TagCache"})
  // currently a TileLink to NASTI converter
  val conv = Module(new NASTIMasterIOTileLinkIOConverter, {case BusId => "nasti"; case TLId => "L2ToTC"})
  val nastiPipe = Module(new NASTIPipe, {case BusId => "nasti"})
  val nastiAddrConv = Module(new NASTIAddrConv, {case BusId => "nasti"})

  //tcNetwork.io.managers <> Vec(tc.io.inner)
  tcNetwork.io.managers <> Vec(conv.io.tl)
  conv.io.nasti <> nastiPipe.io.slave
  nastiPipe.io.master <> nastiAddrConv.io.slave
  nastiAddrConv.io.master <> io.nasti
  nastiAddrConv.io.update := pcrControl.io.pcr_update

  // IO space
  def routeL1ToIO(addr: UInt) = UInt(0)
  def routeIOToL1(id: UInt) = id
  val ioNetwork = Module(new SharedTileLinkCrossbar(routeL1ToIO, routeIOToL1),
    {case TLId => "L1ToIO"})

  ioNetwork.io.clients <> tiles.map(_.io.io).map(TileLinkIOWrapper(_, params.alterPartial({case TLId => "L1ToIO"})))

  // IO TileLink to NASTI-Lite bridge
  val nasti_lite = Module(new NASTILiteMasterIOTileLinkIOConverter, {case BusId => "lite"; case TLId => "L1ToIO"})

  ioNetwork.io.managers <> Vec(nasti_lite.io.tl)
  nasti_lite.io.nasti <> io.nasti_lite
}

object Run {
  def main(args: Array[String]): Unit = {
    val gen = () => Class.forName("lowrisc_chip."+args(0)).newInstance().asInstanceOf[Module]
    chiselMain.run(args.drop(1), () => new Top())
  }
}


// a NASTI pipeline stage sometimes used to break critical path
class NASTIPipe extends NASTIModule {
  val io = new Bundle {
    val slave = new NASTISlaveIO
    val master = new NASTIMasterIO
  }

  val awPipe = Module(new DecoupledPipe(io.slave.aw.bits))
  awPipe.io.pi <> io.slave.aw
  awPipe.io.po <> io.master.aw

  val wPipe = Module(new DecoupledPipe(io.slave.w.bits))
  wPipe.io.pi <> io.slave.w
  wPipe.io.po <> io.master.w

  val bPipe = Module(new DecoupledPipe(io.slave.b.bits))
  bPipe.io.pi <> io.master.b
  bPipe.io.po <> io.slave.b

  val arPipe = Module(new DecoupledPipe(io.slave.ar.bits))
  arPipe.io.pi <> io.slave.ar
  arPipe.io.po <> io.master.ar

  val rPipe = Module(new DecoupledPipe(io.master.r.bits))
  rPipe.io.pi <> io.master.r
  rPipe.io.po <> io.slave.r

}

// convert core address to phy address
class NASTIAddrConv extends NASTIModule {
  val io = new Bundle {
    val slave = new NASTISlaveIO
    val master = new NASTIMasterIO
    val update = new ValidIO(new PCRUpdate).flip
  }

  val conv = Module(new MemSpaceConsts(2))
  conv.io.update <> io.update

  io.master.aw.valid := io.slave.aw.valid
  io.master.aw.bits := io.slave.aw.bits
  conv.io.core_addr(0) := io.slave.aw.bits.addr
  io.master.aw.bits.addr := conv.io.phy_addr(0)
  io.slave.aw.ready := io.master.aw.ready

  io.master.ar.valid := io.slave.ar.valid
  io.master.ar.bits := io.slave.ar.bits
  conv.io.core_addr(1) := io.slave.ar.bits.addr
  io.master.ar.bits.addr := conv.io.phy_addr(1)
  io.slave.ar.ready := io.master.ar.ready

  io.master.w <> io.slave.w
  io.slave.b <> io.master.b
  io.slave.r <> io.master.r
}
