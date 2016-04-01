// See LICENSE for license details.

package lowrisc_chip
import Chisel._

case object UseDma extends Field[Boolean]
case object NBanks extends Field[Int]
case object BankIdLSB extends Field[Int]
case object IODataBits extends Field[UInt]
