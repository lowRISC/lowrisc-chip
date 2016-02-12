// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import junctions._
import uncore._
import rocket._
import rocket.Util._
import scala.math.max
import cde.{Parameters, Config, Dump, Knob}

class DefaultConfig extends Config (
  topDefinitions = { (pname,site,here) => 
    type PF = PartialFunction[Any,Any]
    def findBy(sname:Any):Any = here[PF](site[Any](sname))(pname)
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
      case MIFDataBits => Dump("MEM_DAT_WIDTH", 128)

      // Memory spaces
      case NIOSections => 2                         // number of IO space sections
      case IODataBits => Dump("IO_DAT_WIDTH", 32)   // assume 32-bit IO NASTI-Lite bus
                                                    // (LD/SD leads to NASTI-Lite transactions)
      case NMemSections => 2                        // number of Memory space sections
      case InitIOBase => "h80000000"                // IO base address after reset
      case InitIOMask => "h0fffffff"                // IO space mask after reset
      case InitMemBase => "h00000000"               // Memory base address after reset
      case InitMemMask => "h7fffffff"               // Memory space mask address after reset
      case InitPhyBase => "h00000000"               // Memory physical base address after reset

      //Params used by all caches
      case NSets => findBy(CacheName)
      case NWays => findBy(CacheName)
      case RowBits => findBy(CacheName)
      case NTLBEntries => findBy(CacheName)
      case CacheIdBits => findBy(CacheName)
      case ICacheBufferWays => Knob("L1I_BUFFER_WAYS")

      //L1 I$
      case BtbKey => BtbParameters()
      case "L1I" => {
        case NSets => Knob("L1I_SETS")
        case NWays => Knob("L1I_WAYS")
        case RowBits => 4*site(CoreInstBits)
        case NTLBEntries => 8
        case CacheIdBits => 0
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
      case NDmaTransactors => 3
      case NDmaClients => site(NTiles)
      case NDmaXactsPerClient => site(NDmaTransactors)

      //Rocket Core Constants
      case FetchWidth => 1
      case RetireWidth => 1
      case UseVM => true
      case FastLoadWord => true
      case FastLoadByte => false
      case FastMulDiv => true
      case XLen => 64
      case UseFPU => true
      case FDivSqrt => true
      case SFMALatency => 2
      case DFMALatency => 3
      case CoreInstBits => 32
      case CoreDataBits => site(XLen)
      case NCustomMRWCSRs => 0
      
      //Uncore Paramters
      case NBanks => Knob("NBANKS")
      case BankIdLSB => 0
      case LNEndpoints => site(TLKey(site(TLId))).nManagers + site(TLKey(site(TLId))).nClients
      case LNHeaderBits => log2Up(max(site(TLKey(site(TLId))).nManagers,
        site(TLKey(site(TLId))).nClients))
      
      case TLKey("L1toL2") =>
        TileLinkParameters(
          coherencePolicy = new MESICoherence(site(L2DirectoryRepresentation)),
          nManagers = site(NBanks),
          nCachingClients = site(NTiles),
          nCachelessClients = site(NTiles),
          maxClientXacts = site(NMSHRs),
          maxClientsPerPort = 1,
          maxManagerXacts = site(NAcquireTransactors) + 2,
          dataBits = site(CacheBlockBytes)*8
        )
      case TLKey("L2toTC") =>
        TileLinkParameters(
          coherencePolicy = new MEICoherence(new NullRepresentation(site(NBanks))),
          nManagers = 1,
          nCachingClients = site(NBanks),
          nCachelessClients = 0,
          maxClientXacts = 1,
          maxClientsPerPort = site(NAcquireTransactors) + 2,
          maxManagerXacts = 1,
          dataBits = site(CacheBlockBytes)*8
        )
      case TLKey("L1toIO") =>
        TileLinkParameters(
          coherencePolicy = new MICoherence(new NullRepresentation(site(NTiles))),
          nManagers = 1,
          nCachingClients = 0,
          nCachelessClients = site(NTiles),
          maxClientXacts = 1,
          maxClientsPerPort = 1,
          maxManagerXacts = site(NTiles),
          dataBits = site(XLen),
          dataBeats = 1
        )

      // NASTI BUS parameters
      case NastiKey("nasti") =>
        NastiParameters(
          dataBits = site(MIFDataBits),
          addrBits = site(PAddrBits),
          idBits = site(MIFTagBits),
          userBits = 1,
          handlers = 4
        )
      case NastiKey("lite") =>
        NastiParameters(
          dataBits = site(IODataBits),
          addrBits = site(PAddrBits),
          idBits = site(MIFTagBits),
          userBits = 1,
          handlers = 1
        )
      
      case MMIOBase => Dump("MEM_SIZE", BigInt(1 << 30)) // 1 GB
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


class FPGAConfig extends ChiselConfig (
  knobValues = {
    case "TC_BASE_ADDR" => 15 << 24 // 0xf00,0000
  }
)
