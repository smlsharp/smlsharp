/**
 * SMLSharpGC.c
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <llvm/CodeGen/AsmPrinter.h>
#include <llvm/CodeGen/GCStrategy.h>
#include <llvm/CodeGen/GCMetadataPrinter.h>
#include <llvm/IR/Mangler.h>
#include <llvm/MC/MCContext.h>
#include <llvm/MC/MCStreamer.h>
#include <llvm/MC/MCSymbol.h>
#include <llvm/Target/TargetLoweringObjectFile.h>
#include <llvm/Target/TargetMachine.h>
using namespace llvm;

namespace {
class SMLSharpGC : public GCStrategy {
public:
	SMLSharpGC();
};
class SMLSharpGCPrinter : public GCMetadataPrinter {
public:
	void finishAssembly(Module &, GCModuleInfo &, AsmPrinter &) override;
};
}

static GCRegistry::Add<SMLSharpGC> X("smlsharp", "SML#");
static GCMetadataPrinterRegistry::Add<SMLSharpGCPrinter> Y("smlsharp", "SML#");

SMLSharpGC::SMLSharpGC()
{
	NeededSafePoints = 1 << GC::PostCall;
	UsesMetadata = true;
}

static void
EmitUInt16(AsmPrinter &ap, uint64_t value, uint64_t unit = 1)
{
	if (value % unit != 0 || value / unit >= 65536)
		report_fatal_error("EmitUInt16: out of range");
	ap.OutStreamer->EmitIntValue(value / unit, 2);
}

static MCSymbol *
GetLabel(AsmPrinter &ap, const Module &m, const std::string &name)
{
	SmallString<128> mname;
	Mangler::getNameWithPrefix(mname, name, m.getDataLayout());
	return ap.OutContext.getOrCreateSymbol(mname);
}

/*
 * frame table format:
 *   struct align(uintptr_t) {
 *     uint16_t   NumSafePoints;
 *     uint16_t   FrameSize;                        // in words
 *     uint16_t   NumRoots;
 *     uint16_t   RootOffsets[NumRoots];            // in words
 *     uintptr_t  SafePointOffsets[NumSafePoints];  // in bytes
 *   } Descriptors[]; // terminated with NumSafePoints == 0
 */
static void
EmitFunctionInfo(AsmPrinter &ap, GCFunctionInfo &fi, MCSymbol *base,
		 unsigned int ptrsize)
{
	// skip functions that have no safe point.
	if (fi.size() == 0) return;

	ap.OutStreamer->AddComment(fi.getFunction().getName());
	EmitUInt16(ap, fi.size());
	EmitUInt16(ap, fi.getFrameSize(), ptrsize);
	EmitUInt16(ap, fi.roots_size());

	// LLVM does not compute liveness of each gc root; therefore
	// all safe points in a function have identical set of gc roots.
	for (GCFunctionInfo::roots_iterator
		     i = fi.roots_begin(), ie = fi.roots_end();
	     i != ie; ++i)
		EmitUInt16(ap, i->StackOffset, ptrsize);

	ap.OutStreamer->EmitValueToAlignment(ptrsize);
	for (GCFunctionInfo::iterator j = fi.begin(), je = fi.end();
	     j != je; ++j)
		ap.OutStreamer->emitAbsoluteSymbolDiff(j->Label, base, ptrsize);
}

void
SMLSharpGCPrinter::finishAssembly(Module &m, GCModuleInfo &info, AsmPrinter &ap)
{
	unsigned int ptrsize = ap.TM.getDataLayout()->getPointerSize();
	MCSymbol *top = GetLabel(ap, m, "_SML_top");
	MCSymbol *ftab = GetLabel(ap, m, "_SML_ftab");

	ap.OutStreamer->SwitchSection
		(ap.getObjFileLowering().getSectionForConstant
		 (SectionKind::getReadOnly(), nullptr));
	ap.OutStreamer->EmitValueToAlignment(ptrsize);
	ap.OutStreamer->EmitLabel(ftab);

	for (GCModuleInfo::FuncInfoVec::iterator
		     i = info.funcinfo_begin(), ie = info.funcinfo_end();
	     i != ie; ++i) {
		if ((**i).getStrategy().getName() == getStrategy().getName())
			EmitFunctionInfo(ap, **i, top, ptrsize);
		ap.OutStreamer->EmitValueToAlignment(ptrsize);
	}

	ap.OutStreamer->AddComment("end of frame table");
	EmitUInt16(ap, 0);
}
