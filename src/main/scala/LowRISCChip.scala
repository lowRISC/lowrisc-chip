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
}

class Top extends Module with TopLevelParameters {
  val io = new TopIO

  // Rocket Tiles
  val tiles = (0 until nTiles) map { i =>
    Module(new RocketTile(i), {case TLId => "L1ToL2"})
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

  //tcNetwork.io.managers <> Vec(tc.io.inner)
  tcNetwork.io.managers <> Vec(conv.io.tl)
  conv.io.nasti <> nastiPipe.io.slave
  nastiPipe.io.master <> io.nasti

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
    chiselMain.run(args, () => new Top())
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
