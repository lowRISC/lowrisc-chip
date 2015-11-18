// See LICENSE for license details.

import sbt._
import Keys._
import complete._
import complete.DefaultParsers._

object BuildSettings extends Build {

  override lazy val settings = super.settings ++ Seq(
    organization := "berkeley",
    version      := "1.2",
    scalaVersion := "2.11.6",
    parallelExecution in Global := false,
    traceLevel   := 50,
    scalacOptions ++= Seq("-deprecation","-unchecked"),
    libraryDependencies ++= Seq("org.scala-lang" % "scala-reflect" % scalaVersion.value)
  )

  lazy val chisel       = Project("chisel", file("chisel"))
  lazy val hardfloat    = Project("hardfloat", file("hardfloat")).dependsOn(chisel)
  lazy val junctions    = Project("bridge", file("junctions")).dependsOn(chisel)
  lazy val uncore       = Project("uncore", file("uncore")).dependsOn(junctions)
  lazy val rocket       = Project("rocket", file("rocket")).dependsOn(hardfloat, uncore)
  lazy val lowrisc_chip = Project("lowrisc_chip", file(".")).dependsOn(chisel, hardfloat, uncore, rocket, junctions)

}
