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
 * @file     Import.scala
 * @brief    The Import activity import an IP-XACT IP core in a .zip file
 *           into the currently configured core library for TPC. If no
 *           synthesis report can be found, it will use the EvaluateIP
 *           activity to generate an out-of-context synthesis report to
 *           estimate area utilization and max. operating frequency.
 * @authors  J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
 **/
package de.tu_darmstadt.cs.esa.tapasco.activity
import  de.tu_darmstadt.cs.esa.tapasco.base._
import  de.tu_darmstadt.cs.esa.tapasco.base.json._
import  de.tu_darmstadt.cs.esa.tapasco.util._
import  de.tu_darmstadt.cs.esa.tapasco.filemgmt.FileAssetManager
import  java.nio.file._

/**
 * The Import activity imports an existing IP-XACT core into the cores library
 * of the current TPC configuration. Reports can either be supplied manually,
 * or will be generated by out-of-context synthesis, if not found.
 **/
object Import {
  private implicit final val logger =
    de.tu_darmstadt.cs.esa.tapasco.Logging.logger(getClass)

  /**
   * Import the given IP-XACT .zip file as Kernel with given id for the given target.
   * If no XML synthesis report is found (%NAME%_export.xml), will perform out-of-contex
   * synthesis and place-and-route for the Core to produce area and Fmax estimates.
   * @param zip Path to IP-XACT. zip.
   * @param id Kernel ID.
   * @param t Target Architecture + Platform combination to import for.
   * @param acc Average clock cycle count for a job execution on the PE (optional).
   * @param cfg Implicit [[base.Configuration]].
   **/
  def apply(zip: Path, id: Kernel.Id, t: Target, acc: Option[Int])(implicit cfg: Configuration): Boolean = {
    // get VLNV from the file
    val vlnv = VLNV.fromZip(zip)
    logger.trace("found VLNV in zip " + zip + ": " + vlnv)
    // extract version and name from VLNV, create Core
    val c = Core(
        descPath = zip.resolveSibling("core.description"),
        _zipPath = zip,
        name = vlnv.name,
        id = id,
        version = vlnv.version.toString,
        _target = t,
        Some("imported from %s on %s".format(zip.toString, java.time.LocalDateTime.now().toString)),
        acc)

    // write core.description to output directory (as per config)
    val p = cfg.outputDir(c, t).resolve("core.description")
    if (! p.toFile.exists) {
      importCore(zip, c, t, p)
    } else {
      logger.info("core already exists in {}, skipping", p)
      true
    }
  }

  /**
   * Imports the IP-XACT .zip to the default path structure (ipcore/) and performs
   * out-of-context synthesis (if no report from HLS was found).
   * @param zip Path to IP-XACT .zip.
   * @param c Core description.
   * @param t Target platform and architecture.
   * @param p Output path for core description file.
   * @param cfg Implicit [[Configuration]].
   **/
  private def importCore(zip: Path, c: Core, t: Target, p: Path)(implicit cfg: Configuration): Boolean = {
    Files.createDirectories(p.getParent)
    logger.trace("created directories: {}", p.getParent.toString)

    // add link to original .zip in the 'ipcore' subdir
    val linkp = cfg.outputDir(c, t).resolve("ipcore").resolve(c.zipPath.toString)
    if (! linkp.toFile.equals(zip.toAbsolutePath.toFile)) {
      Files.createDirectories(linkp.getParent)
      logger.trace("created directories: {}", linkp.getParent.toString)
      if (linkp.toFile.exists) linkp.toFile.delete()
      try {
        java.nio.file.Files.createSymbolicLink(linkp, zip.toAbsolutePath)
      } catch { case ex: java.nio.file.FileSystemException => {
        logger.warn("cannot create link " + linkp + " -> " + zip + ", copying data")
        java.nio.file.Files.copy(zip, linkp, java.nio.file.StandardCopyOption.REPLACE_EXISTING)
      }}
    }

    // finally, evaluate the ip core and store the report with the link
    val res = evaluateCore(zip, c, t)

    // write core.description
    logger.debug("writing core description: {}", p.toString)
    Core.to(c, p)
    res
  }

  /**
   * Searches for an existing synthesis report, otherwise performs out-of-context synthesis and
   * place-and-route to produce area and Fmax estimates
   * @param zip Path to IP-XACT .zip.
   * @param c Core description.
   * @param t Target Architecture + Platform combination.
   * @param cfg Implicit [[Configuration]].
   **/
  private def evaluateCore(zip: Path, c: Core, t: Target)(implicit cfg: Configuration): Boolean = {
    logger.trace("looking for SynthesisReport ...")
    val period = 1000.0 / t.pd.supportedFrequencies.sortWith(_>_).head
    val report = cfg.outputDir(c, t).resolve("ipcore").resolve("%s_export.xml".format(c.name))
    FileAssetManager.reports.synthReport(c.name, t) map { hls_report =>
      logger.trace("found existing synthesis report: " + hls_report)
      if (! report.equals(hls_report.file)) { // make link if not same
        java.nio.file.Files.createSymbolicLink(report, hls_report.file.toAbsolutePath)
      }
      true
    } getOrElse {
      logger.info("SynthesisReport for {} not found, starting evaluation ...", c.name)
      EvaluateIP(zip, period, t.pd.part, report)
    }
  }
}