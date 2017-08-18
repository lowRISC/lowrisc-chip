// See LICENSE for license details.

import sbt._
import Keys._
import complete._
import complete.DefaultParsers._
import xerial.sbt.Pack._

object BuildSettings extends Build {

  override lazy val settings = super.settings ++ Seq(
    organization := "berkeley",
    version      := "1.2",
    scalaVersion := "2.11.7",
    parallelExecution in Global := false,
    traceLevel   := 30,
    scalacOptions ++= Seq("-deprecation","-unchecked"),
    scalacOptions ++= Seq("-Xmax-classfile-name", "72"),
    libraryDependencies ++= Seq("org.scala-lang" % "scala-reflect" % scalaVersion.value),
     addCompilerPlugin("org.scalamacros" % "paradise" % "2.1.0" cross CrossVersion.full)
 )

  lazy val chisel = project in file("chisel3")
  lazy val hardfloat  = project.dependsOn(chisel)
  lazy val rocketchip = (project in file(".")).dependsOn(chisel, hardfloat)

}
