// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import cde.{Parameters, ParameterDump, Field, Config}
import junctions._
import uncore._
import rocket._
import rocket.Util._
import open_soc_debug._

case object UseDma extends Field[Boolean]
case object NBanks extends Field[Int]
case object NSCR extends Field[Int]
case object BankIdLSB extends Field[Int]
case object IODataBits extends Field[Int]
case object ConfigString extends Field[Array[Byte]]
case object UseL2Cache extends Field[Boolean]

trait HasTopLevelParameters {
  implicit val p: Parameters
  lazy val nTiles : Int = p(NTiles)
  lazy val nBanks : Int = p(NBanks)
  lazy val lsb : Int = p(BankIdLSB)
  lazy val xLen : Int = p(XLen)
  lazy val nSCR : Int = p(NSCR)
  lazy val scrAddrBits = log2Up(nSCR)
  val csrAddrBits = 12
  val l1tol2TLId = "L1toL2"
  val l2tomemTLId = "L2toMem"
  val l2totcTLId = "L2toTC"
  val tctomemTLId = "TCtoMem"
  val l2toioTLId = "L2toIO"
  val ioTLId = "IONet"
  val extIoTLId = "ExtIONet"
  val l2CacheId  = "L2Bank"
  val tagCacheId = "TagCache"
  val memBusId = "mem"
  val ioBusId = "io"
}

class TopIO(implicit val p: Parameters) extends ParameterizedBundle()(p) with HasTopLevelParameters {
  val nasti_mem   = new NastiIO()(p.alterPartial({case BusId => "mem"}))
  val nasti_io    = new NastiIO()(p.alterPartial({case BusId => "io"}))
  val interrupt   = UInt(INPUT, p(XLen))
  val debug_mam   = (new MamIO).flip
  val cpu_rst     = Bool(INPUT)
  val debug_rst   = Bool(INPUT)
  val debug_net   = Vec(2, new DiiBBoxIO)       // debug network
}

object TopUtils {
  // Connect two Nasti interfaces with queues in-between
  def connectNasti(outer: NastiIO, inner: NastiIO)(implicit p: Parameters) {
    outer.ar <> Queue(inner.ar,1)
    outer.aw <> Queue(inner.aw,1)
    outer.w  <> Queue(inner.w,1)
    inner.r  <> Queue(outer.r,1)
    inner.b  <> Queue(outer.b,1)
  }

  // connect uncached tilelike -> nasti
  def connectTilelinkNasti(nasti: NastiIO, tl: ClientUncachedTileLinkIO)(implicit p: Parameters) = {
    val conv = Module(new NastiIOTileLinkIOConverter())
    conv.io.tl <> tl
    connectNasti(nasti, conv.io.nasti)
  }

  def makeBootROM()(implicit p: Parameters) = {
    val rom = java.nio.ByteBuffer.allocate(32)
    rom.order(java.nio.ByteOrder.LITTLE_ENDIAN)

    // for now, have the reset vector jump straight to memory
    val addrHashMap = p(GlobalAddrHashMap)
    val resetToMemDist =
      if(p(UseBootRAM)) addrHashMap("io:ext:bram").start - p(ResetVector) // start from on-chip BRAM
      else              addrHashMap("mem").start - p(ResetVector)  // start from DDRx
    require(resetToMemDist == (resetToMemDist.toInt >> 12 << 12))
    val configStringAddr = p(ResetVector).toInt + rom.capacity

    rom.putInt(0x00000297 + resetToMemDist.toInt) // auipc t0, &mem - &here
    rom.putInt(0x00028067)                        // jr t0
    rom.putInt(0)                                 // reserved
    rom.putInt(configStringAddr)                  // pointer to config string
    rom.putInt(0)                                 // default trap vector
    rom.putInt(0)                                 //   ...
    rom.putInt(0)                                 //   ...
    rom.putInt(0)                                 //   ...

    rom.array() ++ p(ConfigString).toSeq
  }

}

class Top(topParams: Parameters) extends Module with HasTopLevelParameters {
  implicit val p = topParams
  val io = new TopIO

  ////////////////////////////////////////////
  // local partial parameter overrides

  val rocketParams = p.alterPartial({ case TLId => l1tol2TLId })
  val coherentNetParams = p.alterPartial({ case TLId => l1tol2TLId })
  val memNetParams = if(p(UseTagMem)) p.alterPartial({ case TLId => l2totcTLId })
                     else p.alterPartial({ case TLId => l2tomemTLId })
  val ioManagerParams = p.alterPartial({ case TLId => l2toioTLId })
  val ioNetParams = p.alterPartial({ case TLId => ioTLId; case BusId => ioBusId })
  val memConvParams = if(p(UseTagMem)) p.alterPartial({ case TLId => tctomemTLId; case BusId => memBusId })
                      else p.alterPartial({ case TLId => l2tomemTLId; case BusId => memBusId })
  val smiConvParams = p.alterPartial({ case BusId => ioBusId })
  val ioConvParams = p.alterPartial({ case TLId => extIoTLId; case BusId => ioBusId })

  // IO space configuration
  val addrMap = p(GlobalAddrMap)
  val addrHashMap = p(GlobalAddrHashMap)
  AllAddrMapEntries += addrHashMap

  // TODO: the code to print this stuff should live somewhere else
  println("Generated Address Map")
  addrHashMap.getEntries map { case (name, AddrHashMapEntry(_, base, region)) => {
    println(f"\t$name%s $base%x - ${base + region.size - 1}%x")
  }}
  println("Generated Configuration String")
  println(new String(p(ConfigString)))

  ////////////////////////////////////////////
  // Rocket Tiles
  val tileList = (0 until nTiles) map ( i => Module(new RocketTile(i, reset || io.cpu_rst)(rocketParams)))

  ////////////////////////////////////////////
  // The crossbar between tiles and L2
  def sharerToClientId(sharerId: UInt) = sharerId
  def addrToBank(addr: UInt): UInt = {
    val isMemory = addrHashMap.isInRegion("mem", addr << log2Up(p(CacheBlockBytes)))
    Mux(isMemory, (addr >> lsb) % UInt(nBanks), UInt(nBanks))
  }
  val preBuffering = TileLinkDepths(0,0,1,0,1)
  val coherent_net = Module(new PortedTileLinkCrossbar(addrToBank, sharerToClientId, preBuffering)(coherentNetParams))

  coherent_net.io.clients_cached <> tileList.map(_.io.cached).flatten
  if(p(UseDebug)) {
    val debug_mam = Module(new TileLinkIOMamIOConverter()(coherentNetParams))
    debug_mam.io.mam <> io.debug_mam
    coherent_net.io.clients_uncached <> tileList.map(_.io.uncached).flatten :+ debug_mam.io.tl
  } else
    coherent_net.io.clients_uncached <> tileList.map(_.io.uncached).flatten

  ////////////////////////////////////////////
  // L2 cache coherence managers
  val managerEndpoints = List.tabulate(nBanks){ id =>
    {
      if(p(UseL2Cache)) {
        Module(new L2HellaCacheBank()(p.alterPartial({
          case CacheId => id
          case TLId => coherentNetParams(TLId)
          case CacheName => l2CacheId
          case InnerTLId => coherentNetParams(TLId)
          case OuterTLId => memNetParams(TLId)
        })))
      } else { // broadcasting coherent hub
        Module(new L2BroadcastHub()(p.alterPartial({
          case CacheId => id
          case TLId => coherentNetParams(TLId)
          case CacheName => l2CacheId
          case InnerTLId => coherentNetParams(TLId)
          case OuterTLId => memNetParams(TLId)
        })))
      }
    }
  }

  val mmioManager = Module(new MMIOTileLinkManager()(p.alterPartial({
    case TLId => coherentNetParams(TLId)
    case InnerTLId => coherentNetParams(TLId)
    case OuterTLId => ioManagerParams(TLId)
  })))

  coherent_net.io.managers <> managerEndpoints.map(_.innerTL) :+ mmioManager.io.inner
  managerEndpoints.foreach { _.incoherent.foreach { _ := io.cpu_rst } } // revise when tiles are reset separately

  ////////////////////////////////////////////
  // the network between L2 and memory/tag cache
  def routeL2ToMem(addr: UInt) = UInt(1) // this route function is one-hot
  def routeMemToL2(id: UInt) = id
  val mem_net = Module(new ClientUncachedTileLinkIOCrossbar(nBanks, 1, routeL2ToMem)(memNetParams))
  mem_net.io.in <> managerEndpoints.map(_.outerTL).map(ClientTileLinkIOUnwrapper(_)(memNetParams))

  ////////////////////////////////////////////
  // tag cache
  if(p(UseTagMem)) {
    val tc = Module(new TagCache()(p.alterPartial({
      case CacheName => tagCacheId
      case TLId => memConvParams(TLId)
      case InnerTLId => memNetParams(TLId)
      case OuterTLId => memConvParams(TLId)
    })))
    tc.io.inner <> mem_net.io.out(0)
    TopUtils.connectTilelinkNasti(io.nasti_mem, tc.io.outer)(memConvParams)
  } else {
    TopUtils.connectTilelinkNasti(io.nasti_mem, mem_net.io.out(0))(memConvParams)
  }

  ////////////////////////////////////////////
  // MMIO interconnect

  // mmio interconnect
  val (ioBase, ioAddrMap) = addrHashMap.subMap("io")
  val ioAddrHashMap = new AddrHashMap(ioAddrMap, ioBase)
  val mmio_net = Module(new TileLinkRecursiveInterconnect(1, ioAddrMap, ioBase)(ioNetParams))
  mmio_net.io.in.head <> mmioManager.io.outer

  // Global real time counter (wall clock)
  val rtc = Module(new RTC(nTiles)(ioNetParams))
  val rtcAddr = ioAddrHashMap("int:rtc")
  require(rtc.size <= rtcAddr.region.size)
  rtc.io.tl <> mmio_net.io.out(rtcAddr.port)

  // scr
  //val scrFile = Module(new SCRFile("UNCORE_SCR", ioAddrHashMap("int:scr").start))
  //scrFile.io.scr.attach(Wire(init = UInt(nTiles)), "N_CORES")
  //scrFile.io.scr.attach(Wire(init = UInt(ioBase) >> 20), "MMIO_BASE")
  //if (p(UseHost))
  //  scrFile.io.scr.attach(Wire(init = UInt(ioAddrHashMap("ext:host").start)), "DEV_HOST_BASE")

  //val scrPort = ioAddrHashMap("int:scr").port
  //val scr_conv = Module(new SmiIONastiIOConverter(xLen, scrAddrBits)(smiConvParams))
  //TopUtils.connectTilelinkNasti(scr_conv.io.nasti, mmio_net.io.out(scrPort))(ioConvParams)
  //scrFile.io.smi <> scr_conv.io.smi

  // boot ROM
  val bootROM = Module(new ROMSlave(TopUtils.makeBootROM())(ioNetParams))
  val bootROMAddr = ioAddrHashMap("int:bootrom")
  bootROM.io <> mmio_net.io.out(bootROMAddr.port)

  // DMA (master)
  //dmaOpt.foreach { dma =>
  //  mmio_ic.io.masters(2) <> dma.io.mmio
  //  dma.io.ctrl <> mmio_ic.io.slaves(ioAddrHashMap("int:dma").port)
  //}

  // outer IO devices
  val outerPort = ioAddrHashMap("ext").port
  TopUtils.connectTilelinkNasti(io.nasti_io, mmio_net.io.out(outerPort))(ioConvParams)

  // connection to tiles
  for (i <- 0 until nTiles) {
    // memory mapped csr
    val prci = Module(new PRCI()(ioNetParams))
    val prciAddr = ioAddrHashMap(s"int:prci$i")
    prci.io.tl <> mmio_net.io.out(prciAddr.port)

    prci.io.id := UInt(i)
    prci.io.interrupts.mtip := rtc.io.irqs(i)
    prci.io.interrupts.meip := Bool(false)
    prci.io.interrupts.seip := Bool(false)
    prci.io.interrupts.debug := Bool(false)

    tileList(i).io.prci := prci.io.tile
    tileList(i).io.prci.reset := Bool(false)
  }

  // interrupt, currently just ORed
  for (i <- 0 until nTiles) {
    tileList(i).io.irq := io.interrupt.orR
  }

  ////////////////////////////////////////////
  // trace debugger
  if(p(UseDebug)) {
    (0 until nTiles) foreach { i =>
      if(nTiles > 1 && i != 0) {
        tileList(i).io.dbgnet(0).dii_in <> tileList(i-1).io.dbgnet(0).dii_out
        tileList(i).io.dbgnet(1).dii_in <> tileList(i-1).io.dbgnet(1).dii_out
      }
    tileList(i).io.dbgrst := io.debug_rst
    }

    (0 until 2) foreach { i =>
      val bbox_port = Module(new DiiBBoxPort)
      io.debug_net(i) <> bbox_port.io.bbox
      bbox_port.io.chisel.dii_in <> tileList(0).io.dbgnet(i).dii_in
      if(nTiles == 1) {
        bbox_port.io.chisel.dii_out <> tileList(0).io.dbgnet(i).dii_out
      } else {
        bbox_port.io.chisel.dii_out <> tileList(nTiles - 1).io.dbgnet(i).dii_out
      }
    }
  }

}

object Run extends App with FileSystemUtilities {
  val projectName = args(0)
  val topModuleName = args(1)
  val configProjectName = args(2)
  val configClassName = args(3)

  val config = try {
    Class.forName(s"$configProjectName.$configClassName").newInstance.asInstanceOf[Config]
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

  chiselMain.run(args.drop(4), gen)

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
  val dev_map_hdr = createOutputFile(topModuleName + "." + configClassName + ".dev_map.h")
  AllAddrMapEntries.foreach{ map => dev_map_hdr.write(map.as_c_header) }
  dev_map_hdr.close
}
