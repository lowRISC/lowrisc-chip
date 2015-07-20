// See LICENSE for license details.

import sbt._
import Keys._

object BuildSettings extends Build {
  val buildOrganization = "edu.berkeley.cs"
  val buildVersion = "1.1"
  val buildScalaVersion = "2.10.4"

  val buildSettings = Defaults.defaultSettings ++ Seq (
    organization := buildOrganization,
    version      := buildVersion,
    scalaVersion := buildScalaVersion,
    parallelExecution in Global := false,
    traceLevel   := 50,
    scalacOptions ++= Seq("-deprecation","-unchecked"),
    libraryDependencies ++= Seq("org.scala-lang" % "scala-reflect" % scalaVersion.value)
  )

  // sbt multi-project compilation

  lazy val chisel       = Project("chisel", file("chisel"), settings = buildSettings)
  lazy val hardfloat    = Project("hardfloat", file("hardfloat"), settings = buildSettings).dependsOn(chisel)
  lazy val uncore       = Project("uncore", file("uncore"), settings = buildSettings).dependsOn(hardfloat)
  lazy val rocket       = Project("rocket", file("rocket"), settings = buildSettings).dependsOn(uncore)
  lazy val bridge       = Project("bridge", file("bridge"), settings = buildSettings).dependsOn(uncore)
  lazy val lowrisc_chip = Project("lowrisc_chip", file("."), settings = buildSettings).dependsOn(chisel, hardfloat, uncore, rocket, bridge)

}
