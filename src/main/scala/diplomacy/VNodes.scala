// See LICENSE.Cambridge for license details.

/** lowRISC extension:
  *   This file is used to expand the diplomacy/Nodes
  *   to support attaching virtual peripherals while omitting
  *   build up the actual physical connections.
  */

package freechips.rocketchip.diplomacy

import Chisel._
import chisel3.internal.sourceinfo.SourceInfo
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.util.HeterogeneousBag

abstract class VirtualNode[D, U, EO, EI, B <: Data](
  imp: NodeImp[D, U, EO, EI, B])(
  protected[diplomacy] val numPO: Range.Inclusive,
  protected[diplomacy] val numPI: Range.Inclusive)
  extends BaseNode with InwardNode[D, U, B] with OutwardNode[D, U, B]
{
  protected[diplomacy] def resolveStar(iKnown: Int, oKnown: Int, iStar: Int, oStar: Int): (Int, Int)
  protected[diplomacy] def mapParamsD(n: Int, p: Seq[D]): Seq[D]
  protected[diplomacy] def mapParamsU(n: Int, p: Seq[U]): Seq[U]

  protected[diplomacy] lazy val (oPortMapping, iPortMapping, oStar, iStar) = {
    val oStars = oBindings.filter { case (_,_,b) => b == BIND_STAR }.size
    val iStars = iBindings.filter { case (_,_,b) => b == BIND_STAR }.size
    val oKnown = oBindings.map { case (_, n, b) => b match {
      case BIND_ONCE  => 1
      case BIND_QUERY => n.iStar
      case BIND_STAR  => 0 }}.foldLeft(0)(_+_)
    val iKnown = iBindings.map { case (_, n, b) => b match {
      case BIND_ONCE  => 1
      case BIND_QUERY => n.oStar
      case BIND_STAR  => 0 }}.foldLeft(0)(_+_)
    val (iStar, oStar) = resolveStar(iKnown, oKnown, iStars, oStars)
    val oSum = oBindings.map { case (_, n, b) => b match {
      case BIND_ONCE  => 1
      case BIND_QUERY => n.iStar
      case BIND_STAR  => oStar }}.scanLeft(0)(_+_)
    val iSum = iBindings.map { case (_, n, b) => b match {
      case BIND_ONCE  => 1
      case BIND_QUERY => n.oStar
      case BIND_STAR  => iStar }}.scanLeft(0)(_+_)
    val oTotal = oSum.lastOption.getOrElse(0)
    val iTotal = iSum.lastOption.getOrElse(0)
    require(numPO.contains(oTotal), s"${name} has ${oTotal} outputs, expected ${numPO}${lazyModule.line}")
    require(numPI.contains(iTotal), s"${name} has ${iTotal} inputs, expected ${numPI}${lazyModule.line}")
    (oSum.init zip oSum.tail, iSum.init zip iSum.tail, oStar, iStar)
  }

  lazy val oPorts = oBindings.flatMap { case (i, n, _) =>
    val (start, end) = n.iPortMapping(i)
    (start until end) map { j => (j, n) }
  }
  lazy val iPorts = iBindings.flatMap { case (i, n, _) =>
    val (start, end) = n.oPortMapping(i)
    (start until end) map { j => (j, n) }
  }

  protected[diplomacy] lazy val oParams: Seq[D] = {
    val o = mapParamsD(oPorts.size, iPorts.map { case (i, n) => n.oParams(i) })
    require (o.size == oPorts.size, s"Bug in diplomacy; ${name} has ${o.size} != ${oPorts.size} down/up outer parameters${lazyModule.line}")
    o.map(imp.mixO(_, this))
  }
  protected[diplomacy] lazy val iParams: Seq[U] = {
    val i = mapParamsU(iPorts.size, oPorts.map { case (o, n) => n.iParams(o) })
    require (i.size == iPorts.size, s"Bug in diplomacy; ${name} has ${i.size} != ${iPorts.size} up/down inner parameters${lazyModule.line}")
    i.map(imp.mixI(_, this))
  }

  protected[diplomacy] def gco = if (iParams.size != 1) None else imp.getO(iParams(0))
  protected[diplomacy] def gci = if (oParams.size != 1) None else imp.getI(oParams(0))

  lazy val edgesOut = (oPorts zip oParams).map { case ((i, n), o) => imp.edgeO(o, n.iParams(i)) }
  lazy val edgesIn  = (iPorts zip iParams).map { case ((o, n), i) => imp.edgeI(n.oParams(o), i) }
  lazy val externalEdgesOut = if (externalOut) {edgesOut} else { Seq() }
  lazy val externalEdgesIn = if (externalIn) {edgesIn} else { Seq() }

  val flip = false // needed for blind nodes
  private def flipO(b: HeterogeneousBag[B]) = if (flip) b.flip else b
  private def flipI(b: HeterogeneousBag[B]) = if (flip) b      else b.flip
  val wire = false // needed if you want to grab access to from inside a module
  private def wireO(b: HeterogeneousBag[B]) = if (wire) Wire(b) else b
  private def wireI(b: HeterogeneousBag[B]) = if (wire) Wire(b) else b

  lazy val bundleOut = wireO(flipO(HeterogeneousBag(edgesOut.map(imp.bundleO(_)))))
  lazy val bundleIn  = wireI(flipI(HeterogeneousBag(edgesIn .map(imp.bundleI(_)))))

  // connects the outward part of a node with the inward part of this node
  private def bind(h: OutwardNodeHandle[D, U, B], binding: NodeBinding)
                  (implicit p: Parameters, sourceInfo: SourceInfo): Option[MonitorBase] = {
    val x = this // x := y
    val y = h.outward
    val info = sourceLine(sourceInfo, " at ", "")
    require (!LazyModule.stack.isEmpty, s"${y.name} cannot be connected to ${x.name} outside of LazyModule scope" + info)
    val i = x.iPushed
    val o = y.oPushed
    y.oPush(i, x, binding match {
      case BIND_ONCE  => BIND_ONCE
      case BIND_STAR  => BIND_QUERY
      case BIND_QUERY => BIND_STAR })
    x.iPush(o, y, binding)
    None
  }

  override def :=  (h: OutwardNodeHandle[D, U, B])(implicit p: Parameters, sourceInfo: SourceInfo): Option[MonitorBase] = bind(h, BIND_ONCE)
  override def :*= (h: OutwardNodeHandle[D, U, B])(implicit p: Parameters, sourceInfo: SourceInfo): Option[MonitorBase] = bind(h, BIND_STAR)
  override def :=* (h: OutwardNodeHandle[D, U, B])(implicit p: Parameters, sourceInfo: SourceInfo): Option[MonitorBase] = bind(h, BIND_QUERY)

  // meta-data for printing the node graph
  protected[diplomacy] def colour  = imp.colour
  protected[diplomacy] def reverse = imp.reverse
  protected[diplomacy] def outputs = oPorts.map(_._2) zip edgesOut.map(e => imp.labelO(e))
  protected[diplomacy] def inputs  = iPorts.map(_._2) zip edgesIn .map(e => imp.labelI(e))
}

class VirtualBusNode[D, U, EO, EI, B <: Data](
  imp: NodeImp[D, U, EO, EI, B])(
  dFn: Seq[D] => D,
  uFn: Seq[U] => U)
  extends VirtualNode(imp)(1 to 999, 1 to 1)
{
  override val externalIn: Boolean = true
  override val externalOut: Boolean = true
  override val flip = true
  override lazy val bundleOut = bundleIn

  protected[diplomacy] def resolveStar(iKnown: Int, oKnown: Int, iStars: Int, oStars: Int): (Int, Int) = {
    require (iStars == 0, s"${name} (a virtual bus) cannot appear left of a :*= ${lazyModule.line}")
    require (oStars == 0, s"${name} (a virtual bus) cannot appear right of a :=* ${lazyModule.line}")
    require (iKnown <= 1, s"${name} (a virtual bus) can appear left of a := once ${lazyModule.line}")
    (0, 0)
  }
  protected[diplomacy] def mapParamsD(n: Int, p: Seq[D]): Seq[D] = { val a = dFn(p); Seq.fill(n)(a) }
  protected[diplomacy] def mapParamsU(n: Int, p: Seq[U]): Seq[U] = { val a = uFn(p); Seq.fill(n)(a) }
}

class VirtualSlaveNode[D, U, EO, EI, B <: Data](imp: NodeImp[D, U, EO, EI, B])(pi: Seq[U])
  extends VirtualNode(imp)(0 to 0, pi.size to pi.size)
{
  override val externalIn: Boolean = true
  override val externalOut: Boolean = false
  override lazy val bundleOut = bundleIn

  protected[diplomacy] def resolveStar(iKnown: Int, oKnown: Int, iStars: Int, oStars: Int): (Int, Int) = {
    require (iStars <= 1, s"${name} (a virtual slave) appears left of a :*= ${iStars} times; at most once is allowed${lazyModule.line}")
    require (oStars == 0, s"${name} (a virtual slave) cannot appear right of a :=*${lazyModule.line}")
    require (oKnown == 0, s"${name} (a virtual slave) cannot appear right of a :=${lazyModule.line}")
    require (pi.size >= iKnown, s"${name} (a virtual slave) has ${iKnown} inputs out of ${pi.size}; cannot assign ${pi.size - iKnown} edges to resolve :*=${lazyModule.line}")
    (pi.size - iKnown, 0)
  }
  protected[diplomacy] def mapParamsD(n: Int, p: Seq[D]): Seq[D] = Seq()
  protected[diplomacy] def mapParamsU(n: Int, p: Seq[U]): Seq[U] = pi
}
