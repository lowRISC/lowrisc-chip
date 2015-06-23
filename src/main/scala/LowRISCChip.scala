// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import uncore._
import rocket._
import rocket.Util._

case object NTiles extends Field[Int]
case object NBanks extends Field[Int]
case object BankIdLSB extends Field[Int]

abstract trait TopLevelParameters extends UsesParameters {
  val nTiles = params(NTiles)
  val nBanks = params(NBanks)
  val bankLSB = params(BankIdLSB)
  val bankMSB = bankLSB + log2Up(nBanks) - 1
  require(isPow2(nBanks))
  require(bankMSB < params(TLBlockAddrBits))
  val tlDataBeats = param(TLDataBeats)
}

class TopIO extends Bundle {
  val mem     = new MemIO
}

class Top extends Module with TopLevelParameters {
  val io = new TopIO

  // Rocket Tiles
  val tiles = Vec.fill(nTiles) {
    Module(new RocketTile, {case TLId => "L1ToL2"})
  }

  // L2 Banks
  val banks = Vec.fill(nBanks) {
    Module(new L2HellaCacheBank{
      case CacheName => "L2Bank"
      case InnerTLId => "L1ToL2"
      case OuterTLId => "L2ToTC"})
  }

  // The crossbar between tiles and L2
  def routeL1ToL2(addr: Bits) = if(nBanks > 1) addr(bankMSB,bankLSB) else UInt(0)
  def routeL2ToL1(id: Bits) = id
  val l2Network = Module(new TileLinkCrossbar(
    nTiles, nBanks, routeL1ToL2, routeL2ToL1, tlDataBeats
    TileLinkDepths(2,2,2,2,2),
    TileLinkDepths(0,0,1,0,0)   //Berkeley: TODO: had EOS24 crit path on inner.release
  ))

  // tag cache
  val tc = Module(new TagCache, {case TLId => "L2ToTC"; case CacheName => "TagCache"})

  // the network between L2 and tag cache
  def routeL2ToTC(addr: Bits) = UInt(0)
  def routeTCToL2(id: Bits) = id
  val l2Network = Module(new TileLinkCrossbar(nBanks, 1, routeL2ToTC, routeTCToL2,tlDataBeats))


}

