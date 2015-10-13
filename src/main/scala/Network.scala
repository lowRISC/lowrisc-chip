// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import uncore._
import scala.math.max

/** A general Network for TileLink communication
  * @param clientRouting     the client side routing algorithm
  * @param managerRouting    the manager side routing algorithm
  * @param clientFIFODepth   the depth of client side FIFO
  * @param managerFIFODepth  the depth of manager side FIFO
  */
class TileLinkNetwork(
  clientRouting: UInt => UInt,
  managerRouting: UInt => UInt,
  clientFIFODepth: TileLinkDepths,
  managerFIFODepth: TileLinkDepths
) extends TLModule {

  val nClients = params(TLNClients)
  val nManagers = params(TLNManagers)

  val io = new Bundle {
    val clients = Vec.fill(nClients){new ClientTileLinkIO}.flip
    val managers = Vec.fill(nManagers){new ManagerTileLinkIO}.flip
  }

  val clients = io.clients.zipWithIndex.map {
    case (c, i) => {
      val p = Module(new ClientTileLinkNetworkPort(i, clientRouting))
      val q = Module(new TileLinkEnqueuer(clientFIFODepth))
      p.io.client <> c
      q.io.client <> p.io.network
      q.io.manager
    }
  }

  val managers = io.managers.zipWithIndex.map {
    case (m, i) => {
      val p = Module(new ManagerTileLinkNetworkPort(i, managerRouting))
      val q = Module(new TileLinkEnqueuer(managerFIFODepth))
      m <> p.io.manager
      p.io.network <> q.io.manager
      q.io.client
    }
  }
}

/** The common channel hook up functions
  */
trait CrossbarHooker extends TLModule {
  // define connection helpers
  def P2LHookup[T <: Data](phy: DecoupledIO[PhysicalNetworkIO[T]], log: DecoupledIO[LogicalNetworkIO[T]]) =
  {
    val s = DefaultFromPhysicalShim(phy)
    log.bits := s.bits
    log.valid := s.valid
    s.ready := log.ready
  }

  def L2PHookup[T <: Data](n: Int, phy: DecoupledIO[PhysicalNetworkIO[T]],
    log: DecoupledIO[LogicalNetworkIO[T]]) =
  {
    val s = DefaultToPhysicalShim(n, log)
    phy.bits := s.bits
    phy.valid := s.valid
    s.ready := phy.ready
  }
}


/** A corssbar based TileLink network
  * @param count The number of beats for Acquire, Release and Grant messages
  */
class TileLinkCrossbar(
  clientRouting: UInt => UInt,
  managerRouting: UInt => UInt,
  count: Int = 1,
  clientFIFODepth: TileLinkDepths = TileLinkDepths(0,0,0,0,0),
  managerFIFODepth: TileLinkDepths = TileLinkDepths(0,0,0,0,0)
) extends TileLinkNetwork(clientRouting, managerRouting, clientFIFODepth, managerFIFODepth)
    with CrossbarHooker
{

  // parallel crossbars for different message types
  val acqCB = Module(new BasicCrossbar(nClients, nManagers, new Acquire, count, Some((a: PhysicalNetworkIO[Acquire]) => a.payload.hasMultibeatData())))
  val relCB = Module(new BasicCrossbar(nClients, nManagers, new Release, count, Some((r: PhysicalNetworkIO[Release]) => r.payload.hasMultibeatData())))
  val prbCB = Module(new BasicCrossbar(nManagers, nClients, new Probe))
  val gntCB = Module(new BasicCrossbar(nManagers, nClients, new Grant, count, Some((g: PhysicalNetworkIO[Grant]) => g.payload.hasMultibeatData())))
  val finCB = Module(new BasicCrossbar(nClients, nManagers, new Finish))

  val phyIdBits = max(nClients, nManagers)

  clients.zipWithIndex.map {
    case(c, i) => {
      L2PHookup(phyIdBits, acqCB.io.in(i),  c.acquire)
      L2PHookup(phyIdBits, relCB.io.in(i),  c.release)
      P2LHookup(prbCB.io.out(i), c.probe)
      P2LHookup(gntCB.io.out(i), c.grant)
      L2PHookup(phyIdBits, finCB.io.in(i),  c.finish)
    }
  }

  managers.zipWithIndex.map {
    case(m, i) => {
      P2LHookup(acqCB.io.out(i), m.acquire)
      P2LHookup(relCB.io.out(i), m.release)
      L2PHookup(phyIdBits, prbCB.io.in(i),  m.probe)
      L2PHookup(phyIdBits, gntCB.io.in(i),  m.grant)
      P2LHookup(finCB.io.out(i), m.finish)
    }
  }
}

/** A TileLink Network using a shared crossbar
  * @param count The number of beats for Acquire, Release and Grant messages
  */
class SharedTileLinkCrossbar(
  clientRouting: UInt => UInt,
  managerRouting: UInt => UInt,
  count: Int = 1,
  clientFIFODepth: TileLinkDepths = TileLinkDepths(0,0,0,0,0),
  managerFIFODepth: TileLinkDepths = TileLinkDepths(0,0,0,0,0)
) extends TileLinkNetwork(clientRouting, managerRouting, clientFIFODepth, managerFIFODepth)
    with CrossbarHooker
{

  // shared crossbars
  val c2mCB = Module(new BasicCrossbar(nClients, nManagers, new SuperChannel, count, Some((a: PhysicalNetworkIO[SuperChannel]) => a.payload.hasMultibeatData())))
  val m2cCB = Module(new BasicCrossbar(nManagers, nClients, new SuperChannel, count, Some((a: PhysicalNetworkIO[SuperChannel]) => a.payload.hasMultibeatData())))

  val phyIdBits = max(nClients, nManagers)

  clients.zipWithIndex.map {
    case(c, i) => {
      val mux = Module(new SuperChannelInputMultiplexer)
      val demux = Module(new SuperChannelInputDemultiplexer)
      mux.io.tl <> c
      demux.io.tl <> c
      c2mCB.io.in(i) <> mux.io.su
      m2cCB.io.out(i) <> demux.io.su
    }
  }

  managers.zipWithIndex.map {
    case(m, i) => {
      val mux = Module(new SuperChannelOutputMultiplexer)
      val demux = Module(new SuperChannelOutputDemultiplexer)
      mux.io.tl <> m
      demux.io.tl <> m
      c2mCB.io.out(i) <> demux.io.su
      m2cCB.io.in(i) <> mux.io.su
    }
  }
}
