package freechips.rocketchip.lowrisc

import Chisel._


object DumpMacro {
  // a has map of macros
  private var macros = scala.collection.mutable.HashMap.empty[String, MacroValue]
  def empty = macros.size == 0

  def apply(name:String)             { macros += (name -> FlagMacro())        }
  def apply(name:String, m:String) = { macros += (name -> StringMacro(m));  m }
  def apply(name:String, m:Int)    = { macros += (name -> IntMacro(m));     m }
  def apply(name:String, m:Long)   = { macros += (name -> LongIntMacro(m)); m }
  def apply(name:String, m:BigInt) = { macros += (name -> BigIntMacro(m));  m }

  private def indent(n:Int) = " " * n

  private def vhHelper(m:(String, MacroValue)): String = {
    m._2 match {
      case x: StringMacro  => f"""`define ${m._1}%s "${x.s}%s""""
      case x: IntMacro     => f"`define ${m._1}%s (32'h${x.n}%08x)"
      case x: LongIntMacro => f"`define ${m._1}%s (64'h${x.n}%016x)"
      case x: BigIntMacro  => f"`define ${m._1}%s (${x.n.bitCount}%d'h${x.n.toString(16)}%s)"
      case _               => f"`define ${m._1}%s"
    }
  }

  private def hppHelper(m:(String, MacroValue)): String = {
    m._2 match {
      case x: StringMacro  => f"""#define ${m._1}%s "${x.s}%s""""
      case x: IntMacro     => f"#define ${m._1}%s (0x${x.n}%08xu)"
      case x: LongIntMacro => f"#define ${m._1}%s (0x${x.n}%016xu)"
      case x: BigIntMacro  => f"#define ${m._1}%s (0x${x.n.toString(16)}%sull)"
      case _               => f"#define ${m._1}%s"
    }
  }

  // generate a verilog header file
  def genVH(guard:String):String = f"`ifndef $guard%s\n" ++
    indent(2) ++ f"`define $guard%s\n" ++
    macros.map{ m => indent(2) ++ vhHelper(m) ++ "\n"}.reduce(_++_) ++
    "`endif\n"

  // generate a C++ header file
  def genHPP(guard:String):String = f"#ifndef $guard%s\n" ++
    indent(2) ++ f"#define $guard%s\n" ++
    macros.map{ m => indent(2) ++ hppHelper(m) ++ "\n"}.reduce(_++_) ++
    "#endif\n"
}

sealed trait MacroValue
case class FlagMacro()           extends MacroValue  // macro flag for `ifndef etc.
case class StringMacro(s:String) extends MacroValue  // a string macro
case class IntMacro(n:Int)       extends MacroValue  // 32 bit int
case class LongIntMacro(n:Long)  extends MacroValue  // 64 bit int
case class BigIntMacro(n:BigInt) extends MacroValue  // big int

