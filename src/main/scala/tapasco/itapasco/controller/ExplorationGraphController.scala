package de.tu_darmstadt.cs.esa.tapasco.itapasco.controller
import  de.tu_darmstadt.cs.esa.tapasco.itapasco.globals._
import  de.tu_darmstadt.cs.esa.tapasco.itapasco.model.DesignSpaceGraph.N
import  de.tu_darmstadt.cs.esa.tapasco.itapasco.view._
import  de.tu_darmstadt.cs.esa.tapasco.itapasco.view.dse.graph._
import  de.tu_darmstadt.cs.esa.tapasco.itapasco.view.table._
import  de.tu_darmstadt.cs.esa.tapasco.dse._
import  de.tu_darmstadt.cs.esa.tapasco.reports._
import  de.tu_darmstadt.cs.esa.tapasco.task._
import  de.tu_darmstadt.cs.esa.tapasco.util.Listener
import  scala.collection.JavaConverters._

/** Controls "live" view of a DSE run, i.e., the DSE graph.
 *  This is a complex monitoring panel, consisting of two halves:
 *    - The upper half shows the DSE graph along with detail panels for the
 *      reports of a selected composition.
 *    - The lower half shows a table view of the DSE log and a "minimap", which
 *      only highlights finished runs (white), current runs (red) and pruned
 *      elements (gray).
 *
 *  ==DSE Graph==
 *  The DSE graph spans the design space along utilization (x-axis) and design
 *  frequency (y-axis). Each composition run is represented as a node, colored
 *  with a heat map that reflects its heuristic value relative to the other
 *  nodes. This view is purely informative for the user, it provides a basic
 *  monitoring of the progress while the DSE runs.
 *
 *  ''Interactions with the graph'':
 *    - move around by selecting 'transform mode' (key '''T''') and clicking +
 *      dragging
 *    - zoom in and out via mouse scroll wheel
 *    - pick nodes by selection 'picking mode' (key '''P''') and either clicking
 *      on nodes, or drawing a rectangular selection by clicking and dragging
 *
 *  ''Navigating the graph'':
 *    - keyboard shortcuts are shown at the top, apply only when an element is
 *      picked:
 *    - '''n'''/'''p''' jumps to previous/next element in the same batch
 *    - '''g'''/'''f''' jump to element which generated / was generated by the
 *      current element
 *    - '''pgup'''/'''pgdown''' jumps to elements pruned by / pruning reasons of
 *      the current element (alternative keys: '''up'''/'''down''')
 *  
 *  ==DSE Log Table==
 *  Table with all DSE events ordered by timestamp; shows a short textual
 *  representation of the event (e.g., Run XY started). This log is later written
 *  in human-readable Json format to a file.
 *
 *  ''Interactions with the log'':
 *    - click any event to select and focus the concerned elements in the main
 *      DSE graph
 *
 * ==Detail Tables==
 * When an element in the main graph is picked, the detail panels will show
 * additional information about the elements gathered from several reports that
 * were generated during execution.
 *
 */
class ExplorationGraphController extends ViewController {
  private[this] final val _logger = de.tu_darmstadt.cs.esa.tapasco.Logging.logger(getClass)
  val egp = new ExplorationGraphPanel(Some(ExplorationGraphController.keyboardLegend))
  override def view: View = egp
  override def controllers: Seq[ViewController] = Seq()
  Graph.mainViewer.addKeyListener(KeyListener)

  egp.elog.EventSelection += new Listener[ExplorationLogTable.Event] {
    import ExplorationLogTable.Events._, Exploration.Events._
    // scalastyle:off cyclomatic.complexity
    def update(e: ExplorationLogTable.Event): Unit = (e match {
      case EventSelected(ev: Exploration.Event) => ev match {
        case RunDefined(e, _)        => Seq(e)
        case RunStarted(e, _)        => Seq(e)
        case RunFinished(e, _)       => Seq(e)
        case RunGenerated(e0, e1, _) => Seq(e0, e1)
        case RunPruned(es, _, _)     => es
        case BatchStarted(_, es)     => es
        case BatchFinished(_, es, _) => es
        case _                       => Seq()
      }
    }) match {
      case n +: ns => focus(n, ns:_*)
      case _       => {}
    }
    // scalastyle:on cyclomatic.complexity
  }

  Graph += new Listener[Graph.Event] {
    import Graph.Events._
    def update(e: Graph.Event): Unit = e match {
      case ExplorationChanged(oe) => oe foreach { ex =>
        egp.elog.explorationListeners foreach { ex += _ }
      }
      case NodePicked(n, true) =>
        egp.detailPanel.element = n
        Graph.graph.result(n) foreach { cr => {
          _logger.trace("{} -> {}", n: Any, cr)
          cr.synth foreach  { Reports += _ }
          cr.timing foreach { Reports += _ }
          cr.power foreach  { Reports += _ }
        }}
      case _ => {}
    }
  }

  TaskScheduler += new Listener[Tasks.Event] {
    import Tasks.Events._
    def update(e: Tasks.Event): Unit = e match {
      case TaskStarted(_, t) => t match {
        case et: ExplorationTask => egp.exitEnabled = false
        case _ => {}
      }
      case TaskCompleted(_, t) => t match {
        case et: ExplorationTask => egp.exitEnabled = true
        case _ => {}
      }
      case _ => {}
    }
  }

  /** Focuses main graph on the given elements
   *  Puts them into ''picked'' state and centers the view on the middle of the
   *  group of nodes.
   *  @todo Add zoom to fit?
   *  @param n First element to focus on.
   *  @param ns Further elements to focus on (optional).
   */
  def focus(n: N, ns: N*) {
    import java.awt.geom._
    val coords = (n +: ns) map (Graph.layout.apply _)
    val xs = coords map (_.getX())
    val ys = coords map (_.getY())
    val rect = new Rectangle2D.Double(xs.min, ys.min, xs.max - xs.min, ys.max - ys.min)
    val pvs = Graph.mainViewer.getPickedVertexState()
    egp.mainGraph.center = new Point2D.Double(rect.x + rect.width / 2.0, rect.y + rect.height / 2.0)
    pvs.clear()
    (n +: ns) foreach { e => pvs.pick(e, true) }
    Graph.mainViewer.repaint()
  }

  /** Controller object for the displayed detail reports.
   *  Reports can simply be added by [[Reports.+=]], [[Reports.++=]], [[Reports.-=]]
   *  and [[Reports.--=]] methods, will be matched to their panel automatically
   *  based on the type of report.
   *  @note supports currently [[reports.SynthesisReport]], [[reports.TimingReport]],
   *        [[reports.PowerReport]]
   */
  object Reports {
    private val _reports = scala.collection.mutable.Set[Report]()
    def apply: Seq[Report] = _reports.toSeq.sortBy(_.file.toString)
    def +=(r: Report) {
      _reports += r
      r match {
        case sr: SynthesisReport => egp.reportPanel(0).report = sr
        case tr: TimingReport    => egp.reportPanel(1).report = tr
        case pr: PowerReport     => egp.reportPanel(2).report = pr
        case _                   => {}
      }
    }
    def ++=(rs: Seq[Report]) { rs foreach { _reports += _ } }
    def -=(r: Report) { _reports -= r }
    def --=(rs: Seq[Report]) { rs foreach { _reports -= _ } }
  }

  private object KeyListener extends java.awt.event.KeyListener {
    import java.awt.event.KeyEvent
    import  de.tu_darmstadt.cs.esa.tapasco.itapasco.model.DesignSpaceGraph._

    override def keyPressed(e: KeyEvent) {}
    override def keyTyped(e: KeyEvent) {}
    // scalastyle:off cyclomatic.complexity
    override def keyReleased(e: KeyEvent) {
      e.getKeyChar() match {
        case 'n' => moveInBatch(true)
        case 'p' => moveInBatch(false)
        case 'g' => generatedBy(true)
        case 'f' => generatedBy(false)
        case _   => e.getKeyCode() match {
          case KeyEvent.VK_UP        => prunedBy(false)
          case KeyEvent.VK_PAGE_UP   => prunedBy(false)
          case KeyEvent.VK_DOWN      => prunedBy(true)
          case KeyEvent.VK_PAGE_DOWN => prunedBy(true)
          case _                     => {}
        }
      }
    }
    // scalastyle:on cyclomatic.complexity

    private def moveInBatch(forward: Boolean = true) {
      val pvs = Graph.mainViewer.getPickedVertexState()
      def ffs(e: N) = if (forward) Graph.graph.nextInBatch(e) else Graph.graph.prevInBatch(e)
      pvs.getPicked().asScala.headOption foreach { el => ffs(el) foreach { e =>
        pvs.clear()
        pvs.pick(e, true)
      }}
    }
    private def generatedBy(forward: Boolean = true) {
      val pvs = Graph.mainViewer.getPickedVertexState()
      def ffs(e: N) = if (forward) Graph.graph.generatees(e) else Graph.graph.generators(e)
      pvs.getPicked().asScala.headOption foreach { el => ffs(el) match {
        case n +: ns => focus(n, ns:_*)
        case _ => {}
      }}
    }
    private def prunedBy(forward: Boolean = true) {
      val pvs = Graph.mainViewer.getPickedVertexState()
      def ffs(e: N) = if (forward) Graph.graph.prunees(e) else Graph.graph.pruners(e)
      pvs.getPicked().asScala.headOption foreach { el => ffs(el) match {
        case n +: ns => focus(n, ns:_*)
        case _ => {}
      }}
    }
  }
}

private object ExplorationGraphController {
  private final val keyboardLegend: String =
    "t/p: Move/pick n/p: next/prev in batch g/f: generatees/generators up/down: pruners/prunees"
}