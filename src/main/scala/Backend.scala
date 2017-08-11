// See LICENSE for license details.

package lowrisc_chip

import Chisel._

class LowRISCBackend extends VerilogBackend
{
  override def pruneUnconnectedIOs = {
    super.pruneUnconnectedIOs
    for (m <- Driver.sortedComps) {
      if (m != topMod) {
        val (inputs, outputs) = m.wires.unzip._2 partition (_.dir == INPUT)
        for (i <- inputs if i.inputs.isEmpty) {
          i.driveRand = false
        }
      }
    }
  }
}
