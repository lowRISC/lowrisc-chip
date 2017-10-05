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
  case ExPeriperals => ExPeriperalsParams(
    beatBytes = 8, // only support 64-bit right now
    idBits = 8,
    slaves = Seq(
      ExSlaveParams(
        name       = "bram",
        device     = () => new SimpleDevice("bram", Seq("xlnx,bram")),
        base       = 0x40000000,
        size       = 0x00020000,     // 128KB
        resource   = Some("mem"),
        executable = true
      ),
      ExSlaveParams(
        name       = "uart",
        device     = () => new SimpleDevice("serial",Seq("xlnx,uart16550")),
        base       = 0x50000000,
        size       = 0x00002000,     // 8KB
        interrupts = 1
      )
    ))
  case ExtIn  => SlavePortParams(beatBytes = 8, idBits = 8, sourceBits = 4)
  // Additional device Parameters
  case ErrorParams => ErrorParams(Seq(AddressSet(0x3000, 0xfff)))
  case BootROMParams => BootROMParams(contentFileName = "./bootrom/bootrom.img")
}))


class LoRCDefaultConfig extends Config(new WithNBigCores(1) ++ new LoRCBaseConfig)
