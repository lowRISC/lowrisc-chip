// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import uncore._

/** A general Network for TileLink communication
  * @param clientNumber      the number of TileLink clients
  * @param managerNumber     the number of TileLink managers
  * @param clientRouting     the client side routing algorithm
  * @param managerRouting    the manager side routing algorithm
  * @param clientFIFODepth   the depth of client side FIFO
  * @param managerFIFODepth  the depth of manager side FIFO
  */
class TileLinkNetwork(
  clientNumber: Int,
  managerNumber: Int,
  clientRouting: UInt => UInt,
  managerRouting: UInt => UInt,
  clientFIFODepth: TileLinkDepths,
  managerFIFODepth: TileLinkDepths
) extends TLModule {

  val io = new Bundle {
    val clients = Vec.fill(clientNumber){new ClientTileLinkIO}.flip
    val managers = Vec.fill(managerNumber){new ManagerTileLinkIO}.flip
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

/** A corssbar based TileLink network
  * @param beatCount The number of beat for Acquire, Release and Grant messages
  */
class TileLinkCrossbar(
  clientNumber: Int,
  managerNumber: Int,
  clientRouting: UInt => UInt,
  managerRouting: UInt => UInt,
  beatCount: Int = 1,
  clientFIFODepth: TileLinkDepths = TileLinkDepths(0,0,0,0,0),
  managerFIFODepth: TileLinkDepths = TileLinkDepths(0,0,0,0,0),
) extends TileLinkNetwork(clientNumber, managerNumber, clientRouting, managerRouting, clientFIFODepth, managerFIFODepth) {

  // parallel crossbars for different message types
  val acqCB = Module(new BasicCrossbar(clientNumber, managerNumber, new Acquire, count, Some((a: PhysicalNetworkIO[Acquire]) => a.payload.hasMultibeatData())))
  val relCB = Module(new BasicCrossbar(clientNumber, managerNumber, new Release, count, Some((r: PhysicalNetworkIO[Release]) => r.payload.hasMultibeatData())))
  val prbCB = Module(new BasicCrossbar(managerNumber, clientNumber, new Probe))
  val gntCB = Module(new BasicCrossbar(managerNumber, clientNumber, new Grant, count, Some((g: PhysicalNetworkIO[Grant]) => g.payload.hasMultibeatData())))
  val finCB = Module(new BasicCrossbar(clientNumber, managerNumber, new Finish))

  // define connection helpers
  def crossbarHookup[T <: Data, A[x], B[y]](in: A[T], out: B[T]) = {
    out.bits.header := in.bits.header
    out.bits.payload := in.bits.payload
    out.valid := in.valid
    in.ready := out.ready
  }

  clients.zipWithIndex.map {
    case(c, i) => {
      crossbarHookup(c, acqCB.io.in(i))
      crossbarHookup(c, relCB.io.in(i))
      crossbarHookup(prbCB.io.in(i), c)
      crossbarHookup(gntCB.io.in(i), c)
      crossbarHookup(c, finCB.io.in(i))
    }
  }

  managers.zipWithIndex.map {
    case(m, i) => {
      crossbarHookup(acqCB.io.out(i), m)
      crossbarHookup(relCB.io.out(i), m)
      crossbarHookup(m, prbCB.io.out(i))
      crossbarHookup(m, gntCB.io.out(i))
      crossbarHookup(finCB.io.out(i), m)
    }
  }
}
