// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import junctions._
import open_soc_debug._
import uncore._
import rocket._
import rocket.Util._
import scala.math.max
import cde.{Parameters, Config, Dump, Knob}

class DefaultConfig extends Config (
  topDefinitions = { (pname,site,here) => 
    type PF = PartialFunction[Any,Any]
    def findBy(sname:Any):Any = here[PF](site[Any](sname))(pname)

    // Generate address map for device tree, CSR and SCR
    def genCsrAddrMap: AddrMap = {
      val deviceTree = AddrMapEntry("devicetree", None, MemSize(1 << 15, AddrMapConsts.R))
      val csrSize = (1 << 12) * (site(XLen) / 8)
      val csrs = (0 until site(NTiles)).map{ i => 
        AddrMapEntry(s"csr$i", None, MemSize(csrSize, AddrMapConsts.RW))
      }
      val scrSize = site(NSCR) * (site(XLen) / 8)
      val scr = AddrMapEntry("scr", None, MemSize(scrSize, AddrMapConsts.RW))
      new AddrMap(deviceTree +: csrs :+ scr)
    }

    // content of the device tree ROM, core and CSR
    def makeConfigString() = {
      val addrMap = new AddrHashMap(site(GlobalAddrMap), site(MMIOBase))
      val xLen = site(XLen)
      val res = new StringBuilder
      res append  "platform {\n"
      res append  "  vendor lowRISC;\n"
      res append  "  arch rocket;\n"
      res append  "};\n"
      res append  "ram {\n"
      res append  "  0 {\n"
      res append  "    addr 0;\n"
      res append s"    size 0x${site(MMIOBase).toString(16)};\n"
      res append  "  };\n"
      res append  "};\n"
      res append  "core {\n"
      for (i <- 0 until site(NTiles)) {
        val csrAddr = addrMap(s"conf:csr$i").start
        res append s"  $i {\n"
        res append  "    0 {\n"
        res append s"      isa rv$xLen;\n"
        res append s"      addr 0x${csrAddr.toString(16)};\n"
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
      case PAddrBits => Dump("PADDR_WIDTH", 32)
      case PgIdxBits => 12
      case PgLevels => if (site(XLen) == 64) 3 /* Sv39 */ else 2 /* Sv32 */
      case PgLevelBits => site(PgIdxBits) - log2Up(site(XLen)/8)
      case VPNBits => site(PgLevels) * site(PgLevelBits)
      case PPNBits => site(PAddrBits) - site(PgIdxBits)
      case VAddrBits => site(VPNBits) + site(PgIdxBits)
      case ASIdBits => 7
      case MIFTagBits => Dump("MEM_TAG_WIDTH", 8)
      case MIFDataBits => Dump("MEM_DAT_WIDTH", site(TLKey("TCtoMem")).dataBitsPerBeat)
      case IODataBits => Dump("IO_DAT_WIDTH", 32)   // assume 32-bit IO NASTI-Lite bus

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
        case RowBits => 4*site(CoreInstBits)
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
        case RowBits => 2*site(CoreDataBits)
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
      case TagBits => 4
      case TCBlockBits => site(MIFDataBits)
      case TCTransactors => Knob("TC_XACTORS")
      case TCBlockTags => 1 << log2Down(site(TCBlockBits) / site(TagBits))
      case TCBaseAddr => Knob("TC_BASE_ADDR")
      case "TagCache" => {
        case NSets => Knob("TC_SETS")
        case NWays => Knob("TC_WAYS")
        case RowBits => site(TCBlockTags) * site(TagBits)
        case CacheIdBits => 0
      }: PF
      
      //Tile Constants
      case NTiles => Knob("NTILES")
      case BuildRoCC => Nil
      case RoccNMemChannels => site(BuildRoCC).map(_.nMemChannels).foldLeft(0)(_ + _)
      case RoccNPTWPorts => site(BuildRoCC).map(_.nPTWPorts).foldLeft(0)(_ + _)
      case RoccNCSRs => site(BuildRoCC).map(_.csrs.size).foldLeft(0)(_ + _)
      case UseDma => false
      case NDmaTransactors => 3
      case NDmaXacts => site(NDmaTransactors) * 1 // site(NTiles)   ????? WRONG
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
      case ResetVector => BigInt(0x0)
      case MtvecInit => BigInt(0x8)
      case MtvecWritable => false

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
          nManagers = site(NBanks),
          nCachingClients = site(NTiles),
          nCachelessClients = site(NTiles),
          maxClientXacts = site(NMSHRs),
          maxClientsPerPort = 1,
          maxManagerXacts = site(NAcquireTransactors) + 2, // acquire, release, writeback
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = 4
        )
      case TLKey("L1toIO") =>
        TileLinkParameters(
          coherencePolicy = new MICoherence(new NullRepresentation(site(NTiles))),
          nManagers = 1,
          nCachingClients = 0,
          nCachelessClients = site(NTiles) + 1, // core, rtc
          maxClientXacts = 1,
          maxClientsPerPort = 1,
          maxManagerXacts = 1,
          dataBits = site(XLen),
          dataBeats = 1
        )
      case TLKey("L2toTC") =>
        TileLinkParameters(
          coherencePolicy = new MEICoherence(new NullRepresentation(site(NBanks))),
          nManagers = 1,
          nCachingClients = 0,
          nCachelessClients = site(NBanks),
          maxClientXacts = site(NAcquireTransactors) + 2,
          maxClientsPerPort = 1,
          maxManagerXacts = site(TCTransactors),
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = 4
        )

      case TLKey("TCtoMem") =>
        TileLinkParameters(
          coherencePolicy = new MEICoherence(new NullRepresentation(site(NBanks))),
          nManagers = 1,
          nCachingClients = 0,
          nCachelessClients = 1,
          maxClientXacts = site(TCTransactors),
          maxClientsPerPort = 1,
          maxManagerXacts = 1,
          dataBits = site(CacheBlockBytes)*8,
          dataBeats = 8
        )

      // debug
      // disabled in Default
      case DiiIOWidth => 16
      case MamIODataWidth => 16
      case MamIOAddrWidth => 39
      case MamIOBeatsBits => 14
      case UseDebug => false

      // NASTI BUS parameters
      case NastiKey("nasti") =>
        NastiParameters(
          dataBits = site(MIFDataBits),
          addrBits = site(PAddrBits),
          idBits = site(MIFTagBits)
        )
      case NastiKey("lite") =>
        NastiParameters(
          dataBits = site(XLen),
          addrBits = site(PAddrBits),
          idBits = 1
        )
      
      case MMIOBase => Dump("MEM_SIZE", BigInt(1 << 30)) // 1 GB
      case ConfigString => makeConfigString()
      case GlobalAddrMap => {
        AddrMap(
          AddrMapEntry("conf", None,
            MemSubmap(BigInt(1L << 30), genCsrAddrMap)),
          AddrMapEntry("devices", None,
            MemSubmap(BigInt(1L << 31), site(GlobalDeviceSet).getAddrMap)))
      }
      case GlobalDeviceSet => {
        val devset = new DeviceSet
        devset.addDevice("external", 1 << 30, "general")
        devset
      }
    }},
  knobValues = {
    case "NTILES" => Dump("NTILES", 1)
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

    case "TC_XACTORS" => 1
    case "TC_SETS" => 64
    case "TC_WAYS" => 8
    case "TC_BASE_ADDR" => 15 << 28 // 0xf000_0000
  }
)



class WithDebugConfig extends Config (
  (pname,site,here) => pname match {
    case UseDebug => Dump("ENABLE_DEBUG", true)
    case MamIODataWidth => Dump("MAM_IO_DWIDTH", 16)
    case MamIOAddrWidth => site(PAddrBits)
    case MamIOBeatsBits => 14
    case DebugCtmID => 0
    case DebugStmID => 1
    case DebugBaseID => 8
    case DebugCtmScorBoardSize => site(NMSHRs)
    case DebugStmCsrAddr => 0x8f0 // not synced with instruction.scala
    case DebugRouterBufferSize => 4
  }
)

class DebugConfig extends Config(new WithDebugConfig ++ new DefaultConfig)
