// See LICENSE for license details.

import sbt._
import Keys._
import complete._
import complete.DefaultParsers._

object BuildSettings extends Build {
  val buildOrganization = "edu.berkeley.cs"
  val buildVersion = "1.2"
  val buildScalaVersion = "2.11.6"

  override lazy val settings = super.settings ++ Seq(
    organization := "berkeley",
    version      := "1.2",
    scalaVersion := "2.11.6",
    parallelExecution in Global := false,
    traceLevel   := 50,
    scalacOptions ++= Seq("-deprecation","-unchecked"),
    libraryDependencies ++= Seq("org.scala-lang" % "scala-reflect" % scalaVersion.value)
  )

  lazy val chisel    = project
  lazy val hardfloat = project.dependsOn(chisel)
  lazy val junctions = project.dependsOn(chisel)
  lazy val uncore    = project.dependsOn(junctions)
  lazy val rocket    = project.dependsOn(hardfloat,uncore)
  lazy val lowrisc_chip = project.dependsOn(rocket)

}
