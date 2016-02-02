// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import cde.{Parameters, ParameterDump, Field, Config}
import junctions._
import uncore._
import rocket._
import rocket.Util._

trait HasTopLevelParameters {
  implicit val p: Parameters
  lazy val nTiles : Int = p(NTiles)
  lazy val nBanks : Int = p(NBanks)
  lazy val bankLSB : Int = p(BankIdLSB)
  lazy val bankMSB = bankLSB + log2Up(nBanks) - 1
  //require(isPow2(nBanks))
}

class TopIO(implicit val p: Parameters) extends ParameterizedBundle()(p) with HasTopLevelParameters {
  val nasti       = new NastiIO()(p.alterPartial({case BusId => "nasti"}))
  val nasti_lite  = new NastiIO()(p.alterPartial({case BusId => "lite"}))
  val host        = new HIFIO
  val interrupt   = UInt(INPUT, p(XLen))
}

class Top(topParams: Parameters) extends Module with HasTopLevelParameters {
  implicit val p = topParams
  val io = new TopIO

  // Rocket Tiles
  val tiles = (0 until nTiles) map { i =>
    Module(new RocketTile(i)(p.alterPartial({case TLId => "L1toL2" })))
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
    routeL1ToL2, routeL2ToL1,
    TileLinkDepths(2,2,2,2,2),
    TileLinkDepths(0,0,1,0,0)   //Berkeley: TODO: had EOS24 crit path on inner.release
  )(p.alterPartial({case TLId => "L1toL2"})))

  l2Network.io.clients <> (tiles.map(_.io.cached).flatten ++ tiles.map(_.io.uncached).flatten.map(TileLinkIOWrapper(_)))

  // L2 Banks
  val banks = (0 until nBanks) map { _ =>
    Module(new L2HellaCacheBank()(p.alterPartial({
      case CacheName => "L2Bank"
      case InnerTLId => "L1ToL2"
      case OuterTLId => "L2ToTC"
      case TLId => "L1ToL2"   // dummy
    })))
  }

  l2Network.io.managers <> banks.map(_.innerTL)
  banks.foreach(_.incoherent := UInt(0))
  banks.foreach(_.io.soft_reset := pcrControl.io.soft_reset)

  // the network between L2 and tag cache
  def routeL2ToTC(addr: UInt) = UInt(0)
  def routeTCToL2(id: UInt) = id
  val tcNetwork = Module(new TileLinkCrossbar(routeL2ToTC, routeTCToL2)(p.alterPartial({case TLId => "L2toTC" })))

  tcNetwork.io.clients <> banks.map(_.outerTL)

  // tag cache
  //val tc = Module(new TagCache, {case TLId => "L2ToTC"; case CacheName => "TagCache"})
  // currently a TileLink to NASTI converter
  val conv = Module(new NastiMasterIOTileLinkIOConverter()(p.alterPartial({case BusId => "nasti"; case TLId => "L2toTC"})))
  val nastiPipe = Module(new NastiPipe()(p.alterPartial({case BusId => "nasti"})))
  val nastiAddrConv = Module(new NastiAddrConv()(p.alterPartial({case BusId => "nasti"})))

  //tcNetwork.io.managers <> Vec(tc.io.inner)
  tcNetwork.io.managers <> Vec(conv.io.tl)
  conv.io.nasti <> nastiPipe.io.master
  nastiPipe.io.slave <> nastiAddrConv.io.master
  nastiAddrConv.io.slave <> io.nasti
  nastiAddrConv.io.update := pcrControl.io.pcr_update

  // IO space
  def routeL1ToIO(addr: UInt) = UInt(0)
  def routeIOToL1(id: UInt) = id
  val ioNetwork = Module(new SharedTileLinkCrossbar(routeL1ToIO, routeIOToL1)(p.alterPartial({case TLId => "L1toIO"})))

  ioNetwork.io.clients <> tiles.map(_.io.io).map(TileLinkIOWrapper(_))

  // IO TileLink to NASTI-Lite bridge
  val nasti_lite = Module(new NastiLiteMasterIOTileLinkIOConverter()(p.alterPartial({case BusId => "lite"; case TLId => "L1toIO"})))

  ioNetwork.io.managers <> Vec(nasti_lite.io.tl)
  nasti_lite.io.nasti <> io.nasti_lite
}

object Run {
  def main(args: Array[String]): Unit = {
    val projectName = "lowrisc_chip"
    val topModuleName = args(0)
    val configClassName = args(1)

    val config = try {
      Class.forName(s"$projectName.$configClassName").newInstance.asInstanceOf[Config]
    } catch {
      case e: java.lang.ClassNotFoundException =>
        throwException(s"Could not find the cde.Config subclass you asked for " +
          "(i.e. \"$configClassName\"), did you misspell it?", e)
    }

    val world = config.toInstance
    val paramsFromConfig: Parameters = Parameters.root(world)

    val gen = () =>
      Class.forName(s"$projectName.$topModuleName")
        .getConstructor(classOf[cde.Parameters])
        .newInstance(paramsFromConfig)
        .asInstanceOf[Module]

    chiselMain.run(args.drop(2), gen)
    //chiselMain.run(args.drop(2), () => new Top(paramsFromConfig))
  }
}


// a NASTI pipeline stage sometimes used to break critical path
class NastiPipe(implicit p: Parameters) extends NastiModule()(p) {
  val io = new Bundle {
    val slave = new NastiIO
    val master = (new NastiIO).flip
  }

  val awPipe = Module(new DecoupledPipe(io.master.aw.bits))
  awPipe.io.po <> io.slave.aw
  awPipe.io.pi <> io.master.aw

  val wPipe = Module(new DecoupledPipe(io.master.w.bits))
  wPipe.io.po <> io.slave.w
  wPipe.io.pi <> io.master.w

  val bPipe = Module(new DecoupledPipe(io.slave.b.bits))
  bPipe.io.po <> io.master.b
  bPipe.io.pi <> io.slave.b

  val arPipe = Module(new DecoupledPipe(io.master.ar.bits))
  arPipe.io.po <> io.slave.ar
  arPipe.io.pi <> io.master.ar

  val rPipe = Module(new DecoupledPipe(io.slave.r.bits))
  rPipe.io.po <> io.master.r
  rPipe.io.pi <> io.slave.r

}

// convert core address to phy address
class NastiAddrConv(implicit p: Parameters) extends NastiModule()(p) {
  val io = new Bundle {
    val slave = new NastiIO
    val master = (new NastiIO).flip
    val update = new ValidIO(new PCRUpdate).flip
  }

  val conv = Module(new MemSpaceConsts(2))
  conv.io.update <> io.update

  io.slave.aw.valid := io.master.aw.valid
  io.slave.aw.bits := io.master.aw.bits
  conv.io.core_addr(0) := io.master.aw.bits.addr
  io.slave.aw.bits.addr := conv.io.phy_addr(0)
  io.master.aw.ready := io.slave.aw.ready

  io.slave.ar.valid := io.master.ar.valid
  io.slave.ar.bits := io.master.ar.bits
  conv.io.core_addr(1) := io.master.ar.bits.addr
  io.slave.ar.bits.addr := conv.io.phy_addr(1)
  io.master.ar.ready := io.slave.ar.ready

  io.slave.w <> io.master.w
  io.master.b <> io.slave.b
  io.master.r <> io.slave.r
}
