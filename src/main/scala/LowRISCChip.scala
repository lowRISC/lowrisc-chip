// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import cde.{Parameters, ParameterDump, Field, Config}
import junctions._
import uncore._
import rocket._
import rocket.Util._

case object UseDma extends Field[Boolean]
case object NBanks extends Field[Int]
case object NSCR extends Field[Int]
case object BankIdLSB extends Field[Int]
case object IODataBits extends Field[UInt]
case object ConfigString extends Field[Array[Byte]]
case object NTiles extends Field[Int]

trait HasTopLevelParameters {
  implicit val p: Parameters
  lazy val nTiles : Int = p(NTiles)
  lazy val nBanks : Int = p(NBanks)
  lazy val lsb : Int = p(BankIdLSB)
  lazy val xLen : Int = p(XLen)
  lazy val nSCR : Int = p(NSCR)
  lazy val scrAddrBits = log2Up(nSCR)
  lazy val mmioBase = p(MMIOBase)
  val csrAddrBits = 12
  val l1tol2TLId = "L1toL2"
  val l2totcTLId = "L2toTC"
  val tctomemTLId = "TCtoMem"
  val l1toioTLId = "L1toIO"
  val l2CacheId  = "L2Bank"
  val tagCacheId = "TagCache"
  val memBusId = "nasti"
  val ioBusId = "lite"
}

class TopIO(implicit val p: Parameters) extends ParameterizedBundle()(p) with HasTopLevelParameters {
  val nasti       = new NastiIO()(p.alterPartial({case BusId => "nasti"}))
  val nasti_lite  = new NastiIO()(p.alterPartial({case BusId => "lite"}))
  val interrupt   = UInt(INPUT, p(XLen))
  val cpu_rst     = Bool(INPUT)
}

object TopUtils {
  // Connect two Nasti interfaces with queues in-between
  def connectNasti(outer: NastiIO, inner: NastiIO)(implicit p: Parameters) {
    outer.ar <> Queue(inner.ar)
    outer.aw <> Queue(inner.aw)
    outer.w  <> Queue(inner.w)
    inner.r  <> Queue(outer.r)
    inner.b  <> Queue(outer.b)
  }

  // connect uncached tilelike -> nasti
  def connectTilelinkNasti(nasti: NastiIO, tl: ClientUncachedTileLinkIO)(implicit p: Parameters) = {
    val conv = Module(new NastiIOTileLinkIOConverter())
    conv.io.tl <> tl
    connectNasti(nasti, conv.io.nasti)
  }

}

class Top(topParams: Parameters) extends Module with HasTopLevelParameters {
  implicit val p = topParams
  val io = new TopIO

  ////////////////////////////////////////////
  // local partial parameter overrides

  val rocketParams = p.alterPartial({ case TLId => l1tol2TLId; case IOTLId => l1toioTLId })
  val coherentNetParams = p.alterPartial({ case TLId => l1tol2TLId })
  val tagCacheParams = p.alterPartial({ case TLId => l2totcTLId; case CacheName => tagCacheId })
  val tagNetParams = p.alterPartial({ case TLId => l2totcTLId })
  val ioNetParams = p.alterPartial({ case TLId => l1toioTLId; case BusId => ioBusId })
  val memConvParams = p.alterPartial({ case TLId => tctomemTLId; case BusId => memBusId })
  val smiConvParams = p.alterPartial({ case BusId => ioBusId })
  val ioConvParams = p.alterPartial({ case TLId => l1toioTLId; case BusId => ioBusId })

  // IO space configuration
  val addrMap = p(GlobalAddrMap)
  val addrHashMap = new AddrHashMap(addrMap, mmioBase)
  val nSlaves = addrHashMap.nEntries

  // TODO: the code to print this stuff should live somewhere else
  println("Generated Address Map")
  for ((name, base, size, _) <- addrHashMap.sortedEntries) {
    println(f"\t$name%s $base%x - ${base + size - 1}%x")
  }
  println("Generated Configuration String")
  println(new String(p(ConfigString)))

  ////////////////////////////////////////////
  // Rocket Tiles
  val tileList = (0 until nTiles) map ( i => Module(new RocketTile(i, io.cpu_rst)(rocketParams)))

  ////////////////////////////////////////////
  // The crossbar between tiles and L2
  def sharerToClientId(sharerId: UInt) = sharerId
  def addrToBank(addr: UInt): UInt = (addr >> lsb) % UInt(nBanks)
  val preBuffering = TileLinkDepths(2,2,2,2,2)
  val mem_net = Module(new PortedTileLinkCrossbar(addrToBank, sharerToClientId, preBuffering)(coherentNetParams))

  mem_net.io.clients_cached <> tileList.map(_.io.cached).flatten
  mem_net.io.clients_uncached <> tileList.map(_.io.uncached).flatten

  ////////////////////////////////////////////
  // L2 cache coherence managers
  val managerEndpoints = List.tabulate(nBanks){ id =>
    Module(new L2HellaCacheBank()(p.alterPartial({
      case CacheId => id
      case TLId => l1tol2TLId
      case CacheName => l2CacheId
      case InnerTLId => l1tol2TLId
      case OuterTLId => l2totcTLId})))}

  mem_net.io.managers <> managerEndpoints.map(_.innerTL)
  managerEndpoints.foreach { _.incoherent := io.cpu_rst } // revise when tiles are reset separately

  ////////////////////////////////////////////
  // the network between L2 and tag cache
  def routeL2ToTC(addr: UInt) = UInt(0)
  def routeTCToL2(id: UInt) = id
  val tc_net = Module(new ClientUncachedTileLinkIOCrossbar(nBanks, 1, routeL2ToTC)(tagNetParams))
  tc_net.io.in <> managerEndpoints.map(_.outerTL).map(ClientTileLinkIOUnwrapper(_)(tagNetParams))

  ////////////////////////////////////////////
  // tag cache
  //val tc = Module(new TagCache, {case TLId => "L2ToTC"; case CacheName => "TagCache"})
  // currently a TileLink to NASTI converter
  val mem_narrow = Module(new TileLinkIONarrower(l2totcTLId, tctomemTLId)(memConvParams))
  mem_narrow.io.in <> tc_net.io.out(0)
  TopUtils.connectTilelinkNasti(io.nasti, mem_narrow.io.out)(memConvParams)

  ////////////////////////////////////////////
  // MMIO interconnect

  // mmio interconnect
  val mmio_net = Module(new TileLinkRecursiveInterconnect(
    nTiles + 1, addrHashMap.nInternalPorts, addrMap, mmioBase)(ioNetParams))

  for (i <- 0 until nTiles) {
    // mmio
    mmio_net.io.in(i) <> tileList(i).io.io

    // memory mapped csr
    val csrName = s"conf:csr$i"
    val csrPort = addrHashMap(csrName).port
    val conv = Module(new SmiIONastiIOConverter(xLen, csrAddrBits)(smiConvParams))
    TopUtils.connectTilelinkNasti(conv.io.nasti, mmio_net.io.out(csrPort))(ioConvParams)
    tileList(i).io.mmcsr <> conv.io.smi
  }

  // Global real time counter (wall clock)
  val rtc = Module(new RTC(CSRs.mtime)(ioNetParams))
  mmio_net.io.in(nTiles) <> rtc.io

  // scr
  val scrFile = Module(new SCRFile("UNCORE_SCR",addrHashMap("conf:scr").start))
  scrFile.io.scr.attach(Wire(init = UInt(nTiles)), "N_CORES")
  scrFile.io.scr.attach(Wire(init = UInt(p(MMIOBase) >> 20)), "MMIO_BASE")

  val scrPort = addrHashMap("conf:scr").port
  val scr_conv = Module(new SmiIONastiIOConverter(xLen, scrAddrBits)(smiConvParams))
  TopUtils.connectTilelinkNasti(scr_conv.io.nasti, mmio_net.io.out(scrPort))(ioConvParams)
  scrFile.io.smi <> scr_conv.io.smi

  // device tree
  val deviceTree = Module(new NastiROM(p(ConfigString).toSeq)(ioNetParams))
  val dtPort = addrHashMap("conf:devicetree").port
  TopUtils.connectTilelinkNasti(deviceTree.io, mmio_net.io.out(dtPort))(ioConvParams)

  // DMA (master)
  //dmaOpt.foreach { dma =>
  //  mmio_ic.io.masters(2) <> dma.io.mmio
  //  dma.io.ctrl <> mmio_ic.io.slaves(addrHashMap("devices:dma").port)
  //}

  // outer IO devices
  val outerPort = addrHashMap("conf:external").port
  TopUtils.connectTilelinkNasti(io.nasti_lite, mmio_net.io.out(outerPort))(ioConvParams)
}

object Run extends App with FileSystemUtilities {
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

  val pdFile = createOutputFile(s"$topModuleName.$configClassName.prm")
  pdFile.write(ParameterDump.getDump)
  pdFile.close
  val v = createOutputFile(configClassName + ".knb")
  v.write(world.getKnobs)
  v.close
  val d = new java.io.FileOutputStream(Driver.targetDir + "/" + configClassName + ".cfg")
  d.write(paramsFromConfig(ConfigString))
  d.close
  val w = createOutputFile(configClassName + ".cst")
  w.write(world.getConstraints)
  w.close
  val scr_map_hdr = createOutputFile(topModuleName + "." + configClassName + ".scr_map.h")
  AllSCRFiles.foreach{ map => scr_map_hdr.write(map.as_c_header) }
  scr_map_hdr.close

}
