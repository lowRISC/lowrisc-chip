// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import junctions._
import open_soc_debug._
import uncore._
import rocket._
import rocket.Util._
import scala.math.max
import cde.{Parameters, Config, Dump, Knob, CDEMatchError}

case object UseHost extends Field[Boolean]
case object UseUART extends Field[Boolean]
case object UseSPI extends Field[Boolean]
case object UseBootRAM extends Field[Boolean]
case object UseFlash extends Field[Boolean]
case object RAMSize extends Field[BigInt]
case object IOTagBits extends Field[Int]

class BaseConfig extends Config (
  topDefinitions = { (pname,site,here) => 
    type PF = PartialFunction[Any,Any]
    def findBy(sname:Any):Any = here[PF](site[Any](sname))(pname)

    lazy val internalIOAddrMap: AddrMap = {
      val entries = collection.mutable.ArrayBuffer[AddrMapEntry]()
      entries += AddrMapEntry("bootrom", MemSize(1<<13, 1<<12, MemAttr(AddrMapProt.RX)))
      entries += AddrMapEntry("rtc", MemSize(1<<12, 1<<12, MemAttr(AddrMapProt.RW)))
      for (i <- 0 until site(NTiles))
        entries += AddrMapEntry(s"prci$i", MemSize(1<<12, 1<<12, MemAttr(AddrMapProt.RW)))
      new AddrMap(entries)
    }

    lazy val externalIOAddrMap: AddrMap = {
      val entries = collection.mutable.ArrayBuffer[AddrMapEntry]()
      if (site(UseBootRAM)) {
        entries += AddrMapEntry("bram", MemSize(1<<16, 1<<30, MemAttr(AddrMapProt.RWX)))
        Dump("ADD_BRAM", true)
      }
      if (site(UseFlash)) {
        entries += AddrMapEntry("flash", MemSize(1<<24, 1<<24, MemAttr(AddrMapProt.RX)))
          Dump("ADD_FLASH", true)
      }
      if (site(UseHost)) {
        entries += AddrMapEntry("host", MemSize(1<<6, 1<<13, MemAttr(AddrMapProt.W)))
        Dump("ADD_HOST", true)
      }
      if (site(UseUART)) {
        entries += AddrMapEntry("uart", MemSize(1<<13, 1<<13, MemAttr(AddrMapProt.RW)))
        Dump("ADD_UART", true)
      }
      if (site(UseSPI)) {
        entries += AddrMapEntry("spi", MemSize(1<<13, 1<<13, MemAttr(AddrMapProt.RW)))
        Dump("ADD_SPI", true)
      }
      new AddrMap(entries)
    }

    lazy val (globalAddrMap, globalAddrHashMap) = {
      val memSize:BigInt = site(RAMSize)
      val memAlign = BigInt(1L << 30)
      val io = AddrMap(
        AddrMapEntry("int", MemSubmap(internalIOAddrMap.computeSize, internalIOAddrMap)),
        AddrMapEntry("ext", MemSubmap(externalIOAddrMap.computeSize, externalIOAddrMap, true)))
      val addrMap = AddrMap(
        AddrMapEntry("io", MemSubmap(io.computeSize, io)),
        AddrMapEntry("mem", MemSize(memSize, memAlign, MemAttr(AddrMapProt.RWX, true))))

      val addrHashMap = new AddrHashMap(addrMap)
      Dump("ROCKET_MEM_BASE", addrHashMap("mem").start)
      Dump("ROCKET_MEM_SIZE", memSize)
      Dump("ROCKET_IO_BASE", addrHashMap("io:ext").start)
      Dump("ROCKET_IO_SIZE", addrHashMap("io:ext").region.size)
      (addrMap, addrHashMap)
    }

    // content of the device tree ROM, core and CSR
    def makeConfigString() = {
      val addrMap = globalAddrHashMap
      val xLen = site(XLen)
      val res = new StringBuilder
      res append  "platform {\n"
      res append  "  vendor lowRISC;\n"
      res append  "  arch rocket;\n"
      res append  "};\n"
      res append  "rtc {\n"
      res append s"  addr 0x${addrMap("io:int:rtc").start.toString(16)};\n"
      res append  "};\n"
      if(site(UseUART)) {
        res append  "uart {\n"
        res append s"  addr 0x${addrMap("io:ext:uart").start.toString(16)};\n"
        res append  "};\n"
      }
      if(site(UseSPI)) {
        res append  "spi {\n"
        res append s"  addr 0x${addrMap("io:ext:spi").start.toString(16)};\n"
        res append  "};\n"
      }
      res append  "ram {\n"
      res append  "  0 {\n"
      res append s"    addr 0x${addrMap("mem").start.toString(16)};\n"
      res append s"    size 0x${addrMap("mem").region.size.toString(16)};\n"
      res append  "  };\n"
      res append  "};\n"
      res append  "core {\n"
      for (i <- 0 until site(NTiles)) {
        val isa = s"rv${site(XLen)}ima${if (site(UseFPU)) "fd" else ""}"
        val timecmpAddr = addrMap("io:int:rtc").start + 8*(i+1)
        val prciAddr = addrMap(s"io:int:prci$i").start
        res append s"  $i {\n"
        res append  "    0 {\n"
        res append s"      isa $isa;\n"
        res append s"      timecmp 0x${timecmpAddr.toString(16)};\n"
        res append s"      ipi 0x${prciAddr.toString(16)};\n"
        res append  "    };\n"
        res append  "  };\n"
      }
      res append  "};\n"
      res append '\u0000'
      res.toString.getBytes
    }

    // parameter definitions
    pname match {
      //Memory Parameters
      case CacheBlockBytes => 64
      case CacheBlockOffsetBits => log2Up(here(CacheBlockBytes))
      case PAddrBits => Dump("ROCKET_PADDR_WIDTH", 32)
      case PgIdxBits => 12
      case PgLevels => if (site(XLen) == 64) 3 /* Sv39 */ else 2 /* Sv32 */
      case PgLevelBits => site(PgIdxBits) - log2Up(site(XLen)/8)
      case VPNBits => site(PgLevels) * site(PgLevelBits)
      case PPNBits => site(PAddrBits) - site(PgIdxBits)
      case VAddrBits => site(VPNBits) + site(PgIdxBits)
      case ASIdBits => 7
      case MIFTagBits => Dump("ROCKET_MEM_TAG_WIDTH", 8)
      case MIFDataBits => Dump("ROCKET_MEM_DAT_WIDTH", site(TLKey("TCtoMem")).dataBitsPerBeat)
      case IODataBits => Dump("ROCKET_IO_DAT_WIDTH", 64)
      case IOTagBits => Dump("ROCKET_IO_TAG_WIDTH", 8)

      //Params used by all caches
      case NSets => findBy(CacheName)
      case NWays => findBy(CacheName)
      case RowBits => findBy(CacheName)
      case NTLBEntries => findBy(CacheName)
      case CacheIdBits => findBy(CacheName)
      case SplitMetadata => findBy(CacheName)
      case ICacheBufferWays => Knob("L1I_BUFFER_WAYS")

      //L1 I$
      case BtbKey => BtbParameters()
      case "L1I" => {
        case NSets => Knob("L1I_SETS")
        case NWays => Knob("L1I_WAYS")
        case RowBits => site(TLKey(site(TLId))).dataBitsPerBeat
        case NTLBEntries => 8
        case CacheIdBits => 0
	    case SplitMetadata => false
      }:PF

      //L1 D$
      case StoreDataQueueDepth => 17
      case ReplayQueueDepth => 16
      case NMSHRs => Knob("L1D_MSHRS")
      case LRSCCycles => 32 
      case "L1D" => {
        case NSets => Knob("L1D_SETS")
        case NWays => Knob("L1D_WAYS")
        case RowBits => site(TLKey(site(TLId))).dataBitsPerBeat
        case NTLBEntries => 8
        case CacheIdBits => 0
	    case SplitMetadata => false
      }:PF
      case ECCCode => None
      case Replacer => () => new RandomReplacement(site(NWays))
      case AmoAluOperandBits => site(XLen)
      case WordBits => site(XLen)

      //L2 $
      case NAcquireTransactors => Knob("L2_XACTORS")
      case L2StoreDataQueueDepth => 1
      case NSecondaryMisses => 4
      case L2DirectoryRepresentation => new FullRepresentation(site(NTiles))
      case L2Replacer => () => new SeqRandom(site(NWays))
      case "L2Bank" => {
        case NSets => Knob("L2_SETS")
        case NWays => Knob("L2_WAYS")
        case RowBits => site(TLKey(site(TLId))).dataBitsPerBeat
        case CacheIdBits => log2Ceil(site(NBanks))
	    case SplitMetadata => false
      }: PF

      // Tag Cache
      case UseTagMem = false
      case TagBits => 4
      case TagMapRatio => site(CacheBlockBytes) * 8
      case TCMemTransactors  => Knob("TC_MEM_XACTORS")
      case TCTagTransactors  => Knob("TC_TAG_XACTORS")
      case "TagCache" => {
        case NSets => Knob("TC_SETS")
        case NWays => Knob("TC_WAYS")
        case RowBits => site(TLKey(site(TLId))).dataBitsPerBeat
        case CacheIdBits => 0
	    case SplitMetadata => false
      }: PF

      //Tile Constants
      case NTiles => Knob("NTILES")
      case BuildRoCC => Nil
      case RoccNMemChannels => site(BuildRoCC).map(_.nMemChannels).foldLeft(0)(_ + _)
      case RoccNPTWPorts => site(BuildRoCC).map(_.nPTWPorts).foldLeft(0)(_ + _)
      case RoccNCSRs => site(BuildRoCC).map(_.csrs.size).foldLeft(0)(_ + _)
      case UseDma => false
      case NDmaTransactors => 3
      case NDmaXacts => site(NDmaTransactors) * site(NTiles)
      case NDmaClients => site(NTiles)

      //Rocket Core Constants
      case FetchWidth => 1
      case RetireWidth => 1
      case UseVM => true
      case UsePerfCounters => true
      case FastLoadWord => true
      case FastLoadByte => false
      case FastMulDiv => true
      case XLen => 64
      case NSCR => 64
      case UseFPU => true
      case FDivSqrt => true
      case SFMALatency => 2
      case DFMALatency => 3
      case CoreInstBits => 32
      case CoreDataBits => site(XLen)
      case NCustomMRWCSRs => 0
      case ResetVector => BigInt(0x00000000)
      case MtvecInit =>   BigInt(0x00000000)  // should have something default in ROM?
      case MtvecWritable => true

      //Uncore Paramters
      case RTCPeriod => 100 // gives 10 MHz RTC assuming 1 GHz uncore clock
      case NBanks => Knob("NBANKS")
      case BankIdLSB => 0
      case LNEndpoints => site(TLKey(site(TLId))).nManagers + site(TLKey(site(TLId))).nClients
      case LNHeaderBits => log2Up(max(site(TLKey(site(TLId))).nManagers,
        site(TLKey(site(TLId))).nClients))
      case SCRKey => SCRParameters(
                       nSCR = 64,
                       csrDataBits = site(XLen),
                       offsetBits = site(CacheBlockOffsetBits),
                       nCores = site(NTiles))

      case TLKey("L1toL2") =>
        TileLinkParameters(
          coherencePolicy = new MESICoherence(site(L2DirectoryRepresentation)),
          nManagers = site(NBanks) + 1,
          nCachingClients = site(NTiles),
          nCachelessClients = if(site(UseDebug)) site(NTiles) + 1 else site(NTiles),
          maxClientXacts = site(NMSHRs) + 1,
          maxClientsPerPort = 1,
          maxManagerXacts = site(NAcquireTransactors) + 2, // acquire, release, writeback
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = 8,
          withTag = site(UseTagMem)
        )
      case TLKey("L2toIO") =>
        TileLinkParameters(
          coherencePolicy = new MICoherence(new NullRepresentation(site(NBanks))),
          nManagers = 1,
          nCachingClients = 0,
          nCachelessClients = 1,
          maxClientXacts = 1,
          maxClientsPerPort = site(NAcquireTransactors) + 2,
          maxManagerXacts = 1,
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = 8,
          withTag = site(UseTagMem)
        )
      case TLKey("IONet") =>
        site(TLKey("L2toIO")).copy(
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = site(CacheBlockBytes)*8 / site(XLen),
          withTag = false
        )
      case TLKey("ExtIONet") =>
        site(TLKey("IONet")).copy(
          dataBeats = site(CacheBlockBytes)*8 / site(IODataBits)
        )
      case TLKey("L2toMem") =>
        TileLinkParameters(
          coherencePolicy = new MICoherence(new NullRepresentation(site(NBanks))),
          nManagers = 1,
          nCachingClients = site(NBanks),
          nCachelessClients = 0,
          maxClientXacts = 1,
          maxClientsPerPort = site(NAcquireTransactors) + 2,
          maxManagerXacts = 1,
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = 8,
          withTag = false
        )
      case TLKey("L2toTC") =>
        site(TLKey("L2toMem")).copy(
          coherencePolicy = new MICoherence(new NullRepresentation(site(NBanks))),
          maxManagerXacts = site(TCMemTransactors),
          withTag = true
        )
      case TLKey("TC") =>
        site(TLKey("L2toMem")).copy(
          coherencePolicy = new MICoherence(new NullRepresentation(1)),
        )
      case TLKey("TCtoMem") =>
        site(TLKey("L2toTC")).copy(
          nCachingClients = 0,
          nCachelessClients = 1,
          maxClientXacts = 1,
          maxClientsPerPort = site(TCMemTransactors) + site(TCTagTransactors) + 1,
          maxManagerXacts = 1,
          withTag = false
        )


      // debug
      // disabled in Default
      case DiiIOWidth => 16
      case MamIODataWidth => 16
      case MamIOAddrWidth => 39
      case MamIOBeatsBits => 14
      case UseDebug => false
      case EmitLogMessages => true

      // IO devices
      case RAMSize => BigInt(1L << 31)  // 2 GB
      case UseHost => false
      case UseUART => false
      case UseSPI => false
      case UseBootRAM => false
      case UseFlash => false

      // NASTI BUS parameters
      case NastiKey("mem") =>
        NastiParameters(
          dataBits = site(MIFDataBits),
          addrBits = site(PAddrBits),
          idBits = site(MIFTagBits)
        )
      case NastiKey("io") =>
        NastiParameters(
          dataBits = site(IODataBits),
          addrBits = site(PAddrBits),
          idBits = site(IOTagBits)
        )
      
      case ConfigString => makeConfigString()
      case GlobalAddrMap => globalAddrMap
      case GlobalAddrHashMap => globalAddrHashMap
      //case _ => throw new CDEMatchError
  }},
  knobValues = {
    case "NTILES" => Dump("ROCKET_NTILES", 1)
    case "NBANKS" => 1

    case "L1D_MSHRS" => 2
    case "L1D_SETS" => 64
    case "L1D_WAYS" => 4

    case "L1I_SETS" => 64
    case "L1I_WAYS" => 4
    case "L1I_BUFFER_WAYS" => false

    case "L2_XACTORS" => 2
    case "L2_SETS" => 256 // 1024
    case "L2_WAYS" => 8

    case "TC_MEM_XACTORS" => 2
    case "TC_TAG_XACTORS" => 2
    case "TC_SETS" => 64
    case "TC_WAYS" => 8
  }
)

class WithTagConfig extends Config (
  (pname,site,here) => pname match {
    case UseTag => true
    case TagBits => 4
  }
)

class WithDebugConfig extends Config (
  (pname,site,here) => pname match {
    case UseDebug => Dump("ENABLE_DEBUG", true)
    case UseUART => true
    //case EmitLogMessages => false
    case MamIODataWidth => Dump("ROCKET_MAM_IO_DWIDTH", 16)
    case MamIOAddrWidth => site(PAddrBits)
    case MamIOBeatsBits => 14
    case DebugCtmID => 0
    case DebugStmID => 1
    case DebugBaseID => 4
    case DebugSubIDSize => 2
    case DebugCtmScorBoardSize => site(NMSHRs)
    case DebugStmCsrAddr => 0x8ff // not synced with instruction.scala
    case DebugRouterBufferSize => 4
  }
)

class DebugConfig extends Config(new WithDebugConfig ++ new BaseConfig)

class WithHostConfig extends Config (
  (pname,site,here) => pname match {
    case UseHost => true
  }
)

class With4Banks extends Config (
  knobValues = {
    case "NBANKS" => 4
  }
)

class DefaultConfig extends Config(new With4Banks ++ new WithHostConfig ++ new BaseConfig)

class WithSPIConfig extends Config (
  (pname,site,here) => pname match {
    case UseSPI => true
  }
)

class WithUARTConfig extends Config (
  (pname,site,here) => pname match {
    case UseUART => true
  }
)

class WithBootRAMConfig extends Config (
  (pname,site,here) => pname match {
    case UseBootRAM => true
  }
)

class WithFlashConfig extends Config (
  (pname,site,here) => pname match {
    case UseFlash => true
  }
)

class With128MRamConfig extends Config (
  (pname,site,here) => pname match {
    case RAMSize => BigInt(1L << 27)  // 128 MB
  }
)

class BasicFPGAConfig extends
    Config(new WithSPIConfig ++ new WithBootRAMConfig ++ new WithFlashConfig ++ new BaseConfig)

class FPGAConfig extends
    Config(new WithUARTConfig ++ new BasicFPGAConfig)

class FPGADebugConfig extends
    Config(new WithDebugConfig ++ new BasicFPGAConfig)

class Nexys4Config extends
    Config(new With128MRamConfig ++ new FPGAConfig)

class Nexys4DebugConfig extends
    Config(new With128MRamConfig ++ new FPGADebugConfig)

