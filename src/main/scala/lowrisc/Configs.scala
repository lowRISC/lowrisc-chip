// See LICENSE.Cambridge for license details.

package freechips.rocketchip.lowrisc

import Chisel._
import freechips.rocketchip.config.Config
import freechips.rocketchip.coreplex._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.diplomacy._

class LoRCBaseConfig extends Config(new BaseCoreplexConfig().alter((site,here,up) => {
  // DTS descriptive parameters
  case DTSModel => "freechips,rocketchip-unknown"
  case DTSCompat => Nil
  // External port parameters
  case IncludeJtagDTM => false
  case JtagDTMKey => new JtagDTMKeyDefault()
  case NExtTopInterrupts => 2
  case ExtMem => MasterPortParams(
                      base = 0x80000000L,
                      size = 0x10000000L,
                      beatBytes = site(MemoryBusParams).beatBytes,
                      idBits = 4)
  case ExtBus => MasterPortParams(
                      base = 0x60000000L,
                      size = 0x20000000L,
                      beatBytes = site(MemoryBusParams).beatBytes,
                      idBits = 4)
  case ExtIn  => SlavePortParams(beatBytes = 8, idBits = 8, sourceBits = 4)
  // Additional device Parameters
  case ErrorParams => ErrorParams(Seq(AddressSet(0x3000, 0xfff)))
}))


class LoRCDefaultConfig extends Config(new WithNBigCores(1) ++ new LoRCBaseConfig)
