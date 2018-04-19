#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/device.h>
#include <linux/version.h>
#include <linux/atomic.h>
#include "tlkm_logging.h"
#include "tlkm_control.h"
#include "pcie/pcie.h"
#include "pcie/pcie_irq.h"
#include "pcie/pcie_device.h"

#define _INTR(nr) 					\
void tlkm_pcie_slot_irq_work_ ## nr(struct work_struct *work) \
{ \
	struct tlkm_pcie_device *dev = (struct tlkm_pcie_device *)atomic_long_read(&work->data); \
	BUG_ON(! dev->parent->ctrl); \
	tlkm_control_signal_slot_interrupt(dev->parent->ctrl, nr); \
} \
\
irqreturn_t tlkm_pcie_slot_irq_ ## nr(int irq, void *dev_id) 		\
{ 									\
	struct pci_dev *pdev = (struct pci_dev *)dev_id; \
	struct tlkm_pcie_device *dev = (struct tlkm_pcie_device *) dev_get_drvdata(&pdev->dev); \
	BUG_ON(! dev); \
	schedule_work(&dev->irq_work[nr]); \
	return IRQ_HANDLED; \
}

TLKM_PCIE_SLOT_INTERRUPTS
#undef _INTR

int pcie_irqs_init(struct tlkm_device *dev)
{
	struct tlkm_pcie_device *pdev = (struct tlkm_pcie_device *)dev->private_data;
#define _INTR(nr) + 1
	size_t const n = 0 TLKM_PCIE_SLOT_INTERRUPTS;
#undef _INTR
	int ret = 0, irqn, err[n];
	BUG_ON(! dev);
	DEVLOG(dev->dev_id, TLKM_LF_PCIE, "registering %zu interrupts ...", n);
#define _INTR(nr) \
	irqn = nr + TLKM_PLATFORM_INTERRUPTS; \
	if ((err[nr] = request_irq(pci_irq_vector(pdev->pdev, irqn), \
			tlkm_pcie_slot_irq_ ## nr, \
			IRQF_EARLY_RESUME, \
			TLKM_PCI_NAME, \
			pdev->pdev))) { \
		DEVERR(dev->dev_id, "could not request interrupt %d: %d", irqn, err[nr]); \
		goto irq_error; \
	} else { \
		pdev->irq_mapping[irqn] = pci_irq_vector(pdev->pdev, irqn); \
		DEVLOG(dev->dev_id, TLKM_LF_PCIE, "created mapping from interrupt %d -> %d", irqn, pdev->irq_mapping[irqn]); \
		DEVLOG(dev->dev_id, TLKM_LF_PCIE, "interrupt line %d/%d assigned with return value %d", \
				irqn, pci_irq_vector(pdev->pdev, irqn), err[nr]); \
		INIT_WORK(&pdev->irq_work[nr], tlkm_pcie_slot_irq_work_ ## nr); \
		atomic_long_set(&pdev->irq_work[nr].data, (long)pdev->pdev); \
	}
	TLKM_PCIE_SLOT_INTERRUPTS
#undef _INTR
	return 0;

irq_error:
#define _INTR(nr) \
	irqn = nr + TLKM_PLATFORM_INTERRUPTS; \
	if (! err[nr]) { \
		free_irq(pdev->irq_mapping[irqn], pdev->pdev); \
		pdev->irq_mapping[irqn] = -1; \
	} else { \
		ret = err[nr]; \
	}
	TLKM_PCIE_SLOT_INTERRUPTS
#undef _INTR
	return ret;
}

void pcie_irqs_exit(struct tlkm_device *dev)
{
	struct tlkm_pcie_device *pdev = (struct tlkm_pcie_device *)dev->private_data;
	int irqn;
#define _INTR(nr) \
	irqn = nr + TLKM_PLATFORM_INTERRUPTS; \
	if (pdev->irq_mapping[irqn] != -1) { \
		DEVLOG(dev->dev_id, TLKM_LF_PCIE, "freeing interrupt %d with mappping %d", irqn, pdev->irq_mapping[irqn]); \
		free_irq(pdev->irq_mapping[irqn], pdev->pdev); \
		pdev->irq_mapping[irqn] = -1; \
	}
	TLKM_PCIE_SLOT_INTERRUPTS
#undef _INTR
	DEVLOG(dev->dev_id, TLKM_LF_IRQ, "interrupts deactivated");
}

int pcie_irqs_request_platform_irq(struct tlkm_device *dev, int irq_no, irqreturn_t (*intr_handler)(int, void *))
{
	int err = 0;
	struct tlkm_pcie_device *pdev = (struct tlkm_pcie_device *)dev->private_data;
	BUG_ON(! pdev);
	if (irq_no >= TLKM_PLATFORM_INTERRUPTS) {
		DEVERR(dev->dev_id, "invalid platform interrupt number: %d (must be < %d)", irq_no, TLKM_PLATFORM_INTERRUPTS);
		return -ENXIO;
	}

	BUG_ON(! pdev->pdev);
	DEVLOG(dev->dev_id, TLKM_LF_IRQ, "requesting platform irq #%d", irq_no);
	if ((err = request_irq(pci_irq_vector(pdev->pdev, irq_no),
			intr_handler,
			IRQF_EARLY_RESUME,
			TLKM_PCI_NAME,
			pdev->pdev))) {
		DEVERR(dev->dev_id, "could not request interrupt #%d: %d", irq_no, err);
		return err;
	}
	pdev->irq_mapping[irq_no] = pci_irq_vector(pdev->pdev, irq_no);
	DEVLOG(dev->dev_id, TLKM_LF_PCIE, "created mapping from interrupt %d -> %d", irq_no, pdev->irq_mapping[irq_no]);
	DEVLOG(dev->dev_id, TLKM_LF_PCIE, "interrupt line %d/%d assigned with return value %d",
			irq_no, pci_irq_vector(pdev->pdev, irq_no), err);
	return err;
}

void pcie_irqs_release_platform_irq(struct tlkm_device *dev, int irq_no)
{
	struct tlkm_pcie_device *pdev = (struct tlkm_pcie_device *)dev->private_data;
	if (irq_no >= TLKM_PLATFORM_INTERRUPTS) {
		DEVERR(dev->dev_id, "invalid platform interrupt number: %d (must be < %d)", irq_no, TLKM_PLATFORM_INTERRUPTS);
		return;
	}
	DEVLOG(dev->dev_id, TLKM_LF_IRQ, "freeing platform interrupt #%d with mapping %d", irq_no, pdev->irq_mapping[irq_no]);
	free_irq(pdev->irq_mapping[irq_no], pdev->pdev);
	pdev->irq_mapping[irq_no] = -1;
}
