// See LICENSE.Cambridge for license details.

package freechips.rocketchip.lowrisc

import freechips.rocketchip.util.GeneratorApp

/** A lowRISC generator for the Rocket coreplex */
object Generator extends GeneratorApp {

  val longName = names.topModuleClass + "." + names.configs
  generateFirrtl
  generateROMs
  generateArtefacts
}
