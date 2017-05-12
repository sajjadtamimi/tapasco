//
// Copyright (C) 2014 Jens Korinth, TU Darmstadt
//
// This file is part of Tapasco (TPC).
//
// Tapasco is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Tapasco is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Tapasco.  If not, see <http://www.gnu.org/licenses/>.
//
/**
 * @file    Benchmark.scala
 * @brief   Model: TPC IP Benchmark.
 * @todo    Scaladoc is missing.
 * @authors J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
 **/
package de.tu_darmstadt.cs.esa.tapasco.base
import  de.tu_darmstadt.cs.esa.tapasco.util.LinearInterpolator
import  builder._
import  java.time.LocalDateTime
import  java.nio.file._

final case class LibraryVersions(platform: String, tapasco: String)
final case class Host(machine: String, node: String, operatingSystem: String, release: String, version: String)
final case class TransferSpeedMeasurement(chunkSize: Int, read: Double, write: Double, readWrite: Double)
final case class InterruptLatency(clockCycles: Int, latency: Double)
/** Defines an interpolation on [[InterruptLatency]] elements. */
final class LatencyInterpolator(data: Seq[InterruptLatency])
    extends LinearInterpolator[Int, Double](data map { il => (il.clockCycles, il.latency) }) {
  def interpolate(cc: Int, left: (Int, Double), right: (Int, Double)): Double = {
    val l = left._1.toDouble
    val r = right._1.toDouble
    ((cc.toDouble - l) / (r - l)) * (right._2 - left._2) + left._2
  }
}
/** Defines an interpolation on [[TransferSpeedMeasurements]]. */
final class TransferSpeedInterpolator(data: Seq[TransferSpeedMeasurement])
    extends LinearInterpolator[Int, (Double, Double, Double)](data map { ts: TransferSpeedMeasurement =>
      (ts.chunkSize, (ts.read, ts.write, ts.readWrite))
    }) {
  /** Shorthand type. */
  type Rwrw = (Double, Double, Double)
  def interpolate(cs: Int, left: (Int, Rwrw), right: (Int, Rwrw)): Rwrw = {
    val l = left._1.toDouble
    val r = right._1.toDouble
    val f = (cs.toDouble - l) / (r - l)
    (f * (right._2._1 - left._2._1) + left._2._1,
     f * (right._2._2 - left._2._2) + left._2._2,
     f * (right._2._3 - left._2._3) + left._2._3)
  }
}
final case class Benchmark (
      descPath: Path,
      timestamp: LocalDateTime,
      host: Host,
      libraryVersions: LibraryVersions,
      transferSpeed: Seq[TransferSpeedMeasurement],
      interruptLatency: Seq[InterruptLatency]
    ) extends Description(descPath) {
  /** Function to compute interpolated latency values. */
  lazy val latency = new LatencyInterpolator(interruptLatency)
  /** Function to compute interpolated transfer speed values. */
  lazy val speed   = new TransferSpeedInterpolator(transferSpeed)
}

object Benchmark extends Builds[Benchmark]
