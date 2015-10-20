// See LICENSE for license details.

package lowrisc_chip

import Chisel._
import junctions._
import uncore._
import rocket._
import rocket.Util._
import scala.math.max

class DefaultConfig extends ChiselConfig (
  topDefinitions = { (pname,site,here) => 
    type PF = PartialFunction[Any,Any]
    def findBy(sname:Any):Any = here[PF](site[Any](sname))(pname)
    pname match {
      //Memory Parameters
      case CacheBlockBytes => 64
      case CacheBlockOffsetBits => log2Up(here(CacheBlockBytes))
      case PAddrBits => Dump("PADDR_WIDTH", 32)
      case PgIdxBits => 12
      case PgLevels => 3 // Sv39
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

      //L1 I$
      case NBTBEntries => 62
      case NRAS => 2
      case "L1I" => {
        case NSets => Knob("L1I_SETS")
        case NWays => Knob("L1I_WAYS")
        case RowBits => 4*site(CoreInstBits)
        case NTLBEntries => 8
      }:PF

      //L1 D$
      case StoreDataQueueDepth => 17
      case ReplayQueueDepth => 16
      case NMSHRs => Knob("L1D_MSHRS")
      case LRSCCycles => 32 
      case "L1D" => {
        case NSets => Knob("L1D_SETS")
        case NWays => Knob("L1D_WAYS")
        case RowBits => 2*site(XLen)
        case NTLBEntries => 8
      }:PF
      case ECCCode => None
      case Replacer => () => new RandomReplacement(site(NWays))

      //L2 $
      case NAcquireTransactors => Knob("L2_XACTORS")
      case NSecondaryMisses => 4
      case L2DirectoryRepresentation => new FullRepresentation(site(TLNCachingClients))
      case "L2Bank" => {
        case NSets => Knob("L2_SETS")
        case NWays => Knob("L2_WAYS")
        case RowBits => site(TLDataBits)
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
      }: PF
      
      //Tile Constants
      case NTiles => Knob("NTILES")
      case NDCachePorts => 2
      case NPTWPorts => 2
      case BuildRoCC => None

      //Rocket Core Constants
      case FetchWidth => 1
      case RetireWidth => 1
      case UseVM => true
      case FastLoadWord => true
      case FastLoadByte => false
      case FastMulDiv => true
      case XLen => 64
      case NMultXpr => 32
      case BuildFPU => true
      case FDivSqrt => true
      case SFMALatency => 2
      case DFMALatency => 3
      case CoreInstBits => 32
      case CoreDCacheReqTagBits => 7 + log2Up(site(NDCachePorts))
      case NCustomMRWCSRs => 0
      
      //Uncore Paramters
      case NBanks => Knob("NBANKS")
      case BankIdLSB => 0
      case LNHeaderBits => log2Up(max(site(TLNManagers),site(TLNClients)))
      case TLBlockAddrBits => site(PAddrBits) - site(CacheBlockOffsetBits)
      case TLNClients => site(TLNCachingClients) + site(TLNCachelessClients)
      case TLDataBits => site(CacheBlockBytes)*8/site(TLDataBeats)
      case TLWriteMaskBits => (site(TLDataBits) - 1) / 8 + 1
      case TLDataBeats => 4
      case TLNetworkIsOrderedP2P => false
      case TLNManagers => findBy(TLId)
      case TLNCachingClients => findBy(TLId)
      case TLNCachelessClients => findBy(TLId)
      case TLCoherencePolicy => findBy(TLId)
      case TLMaxManagerXacts => findBy(TLId)
      case TLMaxClientXacts => findBy(TLId)
      case TLMaxClientsPerPort => findBy(TLId)
      
      case "L1ToL2" => {
        case TLNManagers => site(NBanks)
        case TLNCachingClients => site(NTiles)
        case TLNCachelessClients => site(NTiles)
        case TLCoherencePolicy => new MESICoherence(site(L2DirectoryRepresentation)) 
        case TLMaxManagerXacts => site(NAcquireTransactors) + 2  // ?? + 2
        case TLMaxClientXacts => site(NMSHRs)
        case TLMaxClientsPerPort => 1
      }:PF
      case "L2ToTC" => {
        case TLNManagers => 1
        case TLNCachingClients => site(NBanks)
        case TLNCachelessClients => 0
        case TLCoherencePolicy => new MEICoherence(new NullRepresentation(site(NBanks)))
        case TLMaxManagerXacts => site(TCTransactors) // ?? + ?
        case TLMaxClientXacts => 1
        case TLMaxClientsPerPort => site(NAcquireTransactors) + 2
      }:PF
      case "L1ToIO" => {
        case TLNManagers => 1
        case TLNCachingClients => 0
        case TLNCachelessClients => site(NTiles)
        case TLCoherencePolicy => new MICoherence(new NullRepresentation(site(NTiles)))
        case TLMaxManagerXacts => site(NTiles)
        case TLMaxClientXacts => 1
        case TLMaxClientsPerPort => 1
      }:PF

      // NASTI BUS parameters
      case NASTIDataBits => findBy(BusId)
      case NASTIAddrBits => findBy(BusId)
      case NASTIIdBits   => findBy(BusId)
      case NASTIUserBits => findBy(BusId)
      case NASTIHandlers => findBy(BusId)

      case "nasti" => {
        case NASTIDataBits => site(MIFDataBits)
        case NASTIAddrBits => site(PAddrBits)
        case NASTIIdBits => site(MIFTagBits)
        case NASTIUserBits => 1
        case NASTIHandlers => 4
      }:PF
      case "lite" => {
        case NASTIDataBits => site(IODataBits)
        case NASTIAddrBits => site(PAddrBits)
        case NASTIIdBits => site(MIFTagBits) // IO may write to memory, avoid X in simulation
        case NASTIUserBits => 1
        case NASTIHandlers => 1
      }:PF
      
    }},
  knobValues = {
    case "NTILES" => Dump("NTILES", 1)
    case "NBANKS" => 1

    case "L1D_MSHRS" => 2
    case "L1D_SETS" => 64
    case "L1D_WAYS" => 4

    case "L1I_SETS" => 64
    case "L1I_WAYS" => 4

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
