/*
 * elf.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: elf.h,v 1.4 2010/01/19 12:15:52 katsu Exp $
 */
#ifndef SMLSHARP__ELF_H__
#define SMLSHARP__ELF_H__

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "cdecl.h"
#include "value.h"

#ifndef ELF_SIZE
#define ELF_SIZE   POINTER_SIZE
#endif

typedef uint32_t Elf32_Addr;
typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Off;
typedef int32_t  Elf32_Sword;
typedef uint32_t Elf32_Word;
typedef unsigned char Elf_Byte;

#define ELF_CONCAT(x,y,z)    x ## y ## _ ## z
#define ELF_(x,y)            ELF_CONCAT(ELF,x,y)
#define ELF(x)               ELF_(ELF_SIZE,x)
#define ELF_TYPE_(x,y)       ELF_CONCAT(Elf,x,y)
#define ELF_TYPE(x)          ELF_TYPE_(ELF_SIZE,x)
#define ELF_TSIZE(x)         sizeof(ELF_TYPE(x))
#define ELF_FIELD(ty,buf,n)  (*(ty*)((char*)(buf) + n))

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define ELF32_WORD_BSWAP(x) do {		\
	asm ("bswap %0" : "+r" (x));		\
} while (0)
/* NOTE: xchgb causes partial register stall. */
#define ELF32_HALF_BSWAP(x) do {		\
	unsigned short x__ = (x);		\
	asm ("rorw %0" : "+r" (x__));		\
	x = x__;				\
} while (0)
#else
/* NOTE: Usually RISC CPU doesn't have logical AND instruction with
 *       32bit immediate value. */
#define ELF32_WORD_BSWAP(x) do {		\
	(x) = ((x) << 24)			\
		| (((x) & 0xff00) << 8)		\
		| (((x) >> 8) & 0xff00)		\
		| ((x) >> 24);			\
} while (0)
#define ELF32_HALF_BSWAP(x) do {		\
	(x) = ((x) << 8) | ((x) >> 8);		\
} while (0)
#endif

#define ELF32_ADDR_BSWAP      ELF32_WORD_BSWAP
#define ELF32_OFF_BSWAP       ELF32_WORD_BSWAP
#define ELF32_SWORD_BSWAP(x)  ELF32_WORD_BSWAP((Elf32_Word)(x))

/* e_ident */
typedef Elf_Byte Elf_Ident[16];
typedef Elf_Byte Elf_Magic[4];
#define ELF_EI_MAGIC_VALUES    { 0x7f, 0x45, 0x4c, 0x46 }  /* "\x7eELF" */
#define ELF_EI_MAGIC(buf)      ((Elf_Magic*)(buf))
#define ELF_EI_CLASS(buf)      ELF_FIELD(Elf_Byte, buf, 4)
#define ELF_EI_DATA(buf)       ELF_FIELD(Elf_Byte, buf, 5)
#define ELF_EI_VERSION(buf)    ELF_FIELD(Elf_Byte, buf, 6)
#define ELF_EI_OSABI(buf)      ELF_FIELD(Elf_Byte, buf, 7)
#define ELF_EI_ABIVERSION(buf) ELF_FIELD(Elf_Byte, buf, 8)
#define ELF_EI_PAD(buf)        ELF_FIELD(Elf_Byte, buf, 9)

/* e_ident[EI_OSABI]; copied from NetBSD */
#define ELF_OSABI_SYSV         0      /* UNIX System V ABI */
#define ELF_OSABI_HPUX         1      /* HP-UX operating system */
#define ELF_OSABI_NETBSD       2      /* NetBSD */
#define ELF_OSABI_LINUX        3      /* GNU/Linux */
#define ELF_OSABI_HURD         4      /* GNU/Hurd */
#define ELF_OSABI_86OPEN       5      /* 86Open */
#define ELF_OSABI_SOLARIS      6      /* Solaris */
#define ELF_OSABI_AIX          7      /* AIX */
#define ELF_OSABI_IRIX         8      /* IRIX */
#define ELF_OSABI_FREEBSD      9      /* FreeBSD */
#define ELF_OSABI_TRU64        10     /* TRU64 UNIX */
#define ELF_OSABI_MODESTO      11     /* Novell Modesto */
#define ELF_OSABI_OPENBSD      12     /* OpenBSD */
#define ELF_OSABI_OPENVMS      13     /* OpenVMS */
#define ELF_OSABI_NSK          14     /* Hewlett-Packard Non-Stop Kernel */
#define ELF_OSABI_ARM          97     /* ARM */
#define ELF_OSABI_STANDALONE   255    /* Standalone (embedded) application */

/* ELF header */
typedef Elf_Byte Elf32_Ehdr[52];
#define ELF32_E_TYPE(buf)      ELF_FIELD(Elf32_Half, buf, 16)
#define ELF32_E_MACHINE(buf)   ELF_FIELD(Elf32_Half, buf, 18)
#define ELF32_E_VERSION(buf)   ELF_FIELD(Elf32_Word, buf, 20)
#define ELF32_E_ENTRY(buf)     ELF_FIELD(Elf32_Addr, buf, 24)
#define ELF32_E_PHOFF(buf)     ELF_FIELD(Elf32_Off,  buf, 28)
#define ELF32_E_SHOFF(buf)     ELF_FIELD(Elf32_Off,  buf, 32)
#define ELF32_E_FLAGS(buf)     ELF_FIELD(Elf32_Word, buf, 36)
#define ELF32_E_EHSIZE(buf)    ELF_FIELD(Elf32_Half, buf, 40)
#define ELF32_E_PHENTSIZE(buf) ELF_FIELD(Elf32_Half, buf, 42)
#define ELF32_E_PHNUM(buf)     ELF_FIELD(Elf32_Half, buf, 44)
#define ELF32_E_SHENTSIZE(buf) ELF_FIELD(Elf32_Half, buf, 46)
#define ELF32_E_SHNUM(buf)     ELF_FIELD(Elf32_Half, buf, 48)
#define ELF32_E_SHSTRNDX(buf)  ELF_FIELD(Elf32_Half, buf, 50)

/* EI_CLASS */
#define ELFCLASS32          1
#define ELFCLASS64          2

#define ELFCLASS__(x,y)     x ## y
#define ELFCLASS_(x,y)      ELFCLASS__(x,y)
#define ELFCLASS            ELFCLASS_(ELFCLASS,ELF_SIZE)

/* EI_DATA */
#define ELFDATA2LSB         1
#define ELFDATA2MSB         2

#ifdef WORDS_BIGENDIAN
#define ELFDATA_HOST ELFDATA2MSB
#else
#define ELFDATA_HOST ELFDATA2LSB
#endif /* WORDS_BIGENDIAN */

/* version */
#define ELF_EV_CURRENT      1

/* file type */
#define ELF_ET_NONE         0
#define ELF_ET_REL          1
#define ELF_ET_EXEC         2
#define ELF_ET_DYN          3

/* machine; copied from NetBSD */
#define ELF_EM_NONE         0       /* No machine */
#define ELF_EM_M32          1       /* AT&T WE 32100 */
#define ELF_EM_SPARC        2       /* SUN SPARC */
#define ELF_EM_386          3       /* Intel 80386 */
#define ELF_EM_68K          4       /* Motorola m68k family */
#define ELF_EM_88K          5       /* Motorola m88k family */
#define ELF_EM_486          6       /* Intel 80486 */
#define ELF_EM_860          7       /* Intel 80860 */
#define ELF_EM_MIPS         8       /* MIPS I Architecture */
#define ELF_EM_S370         9       /* Amdahl UTS on System/370 */
#define ELF_EM_MIPS_RS3_LE  10      /* MIPS RS3000 Little-endian */
#define ELF_EM_RS6000       11      /* IBM RS/6000 XXX reserved */
#define ELF_EM_PARISC       15      /* Hewlett-Packard PA-RISC */
#define ELF_EM_NCUBE        16      /* NCube XXX reserved */
#define ELF_EM_VPP500       17      /* Fujitsu VPP500 */
#define ELF_EM_SPARC32PLUS  18      /* Enhanced instruction set SPARC */
#define ELF_EM_960          19      /* Intel 80960 */
#define ELF_EM_PPC          20      /* PowerPC */
#define ELF_EM_PPC64        21      /* 64-bit PowerPC */
#define ELF_EM_S390         22      /* IBM S/390 */
#define ELF_EM_V800         36      /* NEC V800 */
#define ELF_EM_FR20         37      /* Fujitsu FR20 */
#define ELF_EM_RH32         38      /* TRW RH-32 */
#define ELF_EM_MCORE        39      /* Motorola M*Core */
#define ELF_EM_RCE          39      /* Motorola RCE */
#define ELF_EM_ARM          40      /* Advanced RISC Machines ARM */
#define ELF_EM_ALPHA        41      /* DIGITAL Alpha */
#define ELF_EM_SH           42      /* Hitachi Super-H */
#define ELF_EM_SPARCV9      43      /* SPARC Version 9 */
#define ELF_EM_TRICORE      44      /* Siemens Tricore */
#define ELF_EM_ARC          45      /* Argonaut RISC Core */
#define ELF_EM_H8_300       46      /* Hitachi H8/300 */
#define ELF_EM_H8_300H      47      /* Hitachi H8/300H */
#define ELF_EM_H8S          48      /* Hitachi H8S */
#define ELF_EM_H8_500       49      /* Hitachi H8/500 */
#define ELF_EM_IA_64        50      /* Intel Merced Processor */
#define ELF_EM_MIPS_X       51      /* Stanford MIPS-X */
#define ELF_EM_COLDFIRE     52      /* Motorola Coldfire */
#define ELF_EM_68HC12       53      /* Motorola MC68HC12 */
#define ELF_EM_MMA          54      /* Fujitsu MMA Multimedia Accelerator */
#define ELF_EM_PCP          55      /* Siemens PCP */
#define ELF_EM_NCPU         56      /* Sony nCPU embedded RISC processor */
#define ELF_EM_NDR1         57      /* Denso NDR1 microprocessor */
#define ELF_EM_STARCORE     58      /* Motorola Star*Core processor */
#define ELF_EM_ME16         59      /* Toyota ME16 processor */
#define ELF_EM_ST100        60      /* STMicroelectronics ST100 processor */
#define ELF_EM_TINYJ        61      /* Advanced Logic Corp. TinyJ embedded family processor */
#define ELF_EM_X86_64       62      /* AMD x86-64 architecture */
#define ELF_EM_PDSP         63      /* Sony DSP Processor */
#define ELF_EM_PDP10        64      /* Digital Equipment Corp. PDP-10 */
#define ELF_EM_PDP11        65      /* Digital Equipment Corp. PDP-11 */
#define ELF_EM_FX66         66      /* Siemens FX66 microcontroller */
#define ELF_EM_ST9PLUS      67      /* STMicroelectronics ST9+ 8/16 bit microcontroller */
#define ELF_EM_ST7          68      /* STMicroelectronics ST7 8-bit microcontroller */
#define ELF_EM_68HC16       69      /* Motorola MC68HC16 Microcontroller */
#define ELF_EM_68HC11       70      /* Motorola MC68HC11 Microcontroller */
#define ELF_EM_68HC08       71      /* Motorola MC68HC08 Microcontroller */
#define ELF_EM_68HC05       72      /* Motorola MC68HC05 Microcontroller */
#define ELF_EM_SVX          73      /* Silicon Graphics SVx */
#define ELF_EM_ST19         74      /* STMicroelectronics ST19 8-bit CPU */
#define ELF_EM_VAX          75      /* Digital VAX */
#define ELF_EM_CRIS         76      /* Axis Communications 32-bit embedded processor */
#define ELF_EM_JAVELIN      77      /* Infineon Technologies 32-bit embedded CPU */
#define ELF_EM_FIREPATH     78      /* Element 14 64-bit DSP processor */
#define ELF_EM_ZSP          79      /* LSI Logic's 16-bit DSP processor */
#define ELF_EM_MMIX         80      /* Donald Knuth's educational 64-bit processor */
#define ELF_EM_HUANY        81      /* Harvard's machine-independent format */
#define ELF_EM_PRISM        82      /* SiTera Prism */
#define ELF_EM_AVR          83      /* Atmel AVR 8-bit microcontroller */
#define ELF_EM_FR30         84      /* Fujitsu FR30 */
#define ELF_EM_D10V         85      /* Mitsubishi D10V */
#define ELF_EM_D30V         86      /* Mitsubishi D30V */
#define ELF_EM_V850         87      /* NEC v850 */
#define ELF_EM_M32R         88      /* Mitsubishi M32R */
#define ELF_EM_MN10300      89      /* Matsushita MN10300 */
#define ELF_EM_MN10200      90      /* Matsushita MN10200 */
#define ELF_EM_PJ           91      /* picoJava */
#define ELF_EM_OPENRISC     92      /* OpenRISC 32-bit embedded processor */
#define ELF_EM_ARC_A5       93      /* ARC Cores Tangent-A5 */
#define ELF_EM_XTENSA       94      /* Tensilica Xtensa Architecture */
#define ELF_EM_NS32K        97      /* National Semiconductor 32000 series */
#define ELF_EM_IP2K         101     /* Ubicom IP2022 micro controller */
#define ELF_EM_CR           103     /* National Semiconductor CompactRISC */
#define ELF_EM_MSP430       105     /* TI msp430 micro controller */
#define ELF_EM_BLACKFIN     106     /* ADI Blackfin */
#define ELF_EM_ALTERA_NIOS2 113     /* Altera Nios II soft-core processor */
#define ELF_EM_CRX          114     /* National Semiconductor CRX */

/* Unofficial machine types follow */
#define ELF_EM_AVR32        6317    /* used by NetBSD/avr32 */
#define ELF_EM_ALPHA_EXP    36902   /* used by NetBSD/alpha; obsolete */
#define ELF_EM_NUM          36903













/* section header */
typedef Elf_Byte Elf32_Shdr[40];
#define ELF32_SH_NAME(buf)      ELF_FIELD(Elf32_Word, buf, 0)
#define ELF32_SH_TYPE(buf)      ELF_FIELD(Elf32_Word, buf, 4)
#define ELF32_SH_FLAGS(buf)     ELF_FIELD(Elf32_Word, buf, 8)
#define ELF32_SH_ADDR(buf)      ELF_FIELD(Elf32_Addr, buf, 12)
#define ELF32_SH_OFFSET(buf)    ELF_FIELD(Elf32_Off,  buf, 16)
#define ELF32_SH_SIZE(buf)      ELF_FIELD(Elf32_Word, buf, 20)
#define ELF32_SH_LINK(buf)      ELF_FIELD(Elf32_Word, buf, 24)
#define ELF32_SH_INFO(buf)      ELF_FIELD(Elf32_Word, buf, 28)
#define ELF32_SH_ADDRALIGN(buf) ELF_FIELD(Elf32_Word, buf, 32)
#define ELF32_SH_ENTSIZE(buf)   ELF_FIELD(Elf32_Word, buf, 36)

/* section index */
#define ELF_SHN_UNDEF      0
#define ELF_SHN_ABS        0xfff1
#define ELF_SHN_COMMON     0xfff2

/* section types */
#define ELF_SHT_NULL       0
#define ELF_SHT_PROGBITS   1
#define ELF_SHT_SYMTAB     2
#define ELF_SHT_STRTAB     3
#define ELF_SHT_NOTE       7
#define ELF_SHT_NOBITS     8
#define ELF_SHT_REL        9
#define ELF_SHT_LOUSER     0x80000000

/* section flags */
#define ELF_SHF_WRITE      (1 << 0)
#define ELF_SHF_ALLOC      (1 << 1)
#define ELF_SHF_EXECINSTR  (1 << 2)

/* symbol */
typedef Elf_Byte Elf32_Sym[16];
#define ELF32_ST_NAME(buf)      ELF_FIELD(Elf32_Word, buf, 0)
#define ELF32_ST_ADDR(buf)      ELF_FIELD(Elf32_Addr, buf, 4)
#define ELF32_ST_SIZE(buf)      ELF_FIELD(Elf32_Word, buf, 8)
#define ELF32_ST_INFO(buf)      ELF_FIELD(Elf_Byte, buf, 12)
#define ELF32_ST_BIND(buf)      (ELF32_ST_INFO(buf) >> 4)
#define ELF32_ST_TYPE(buf)      (ELF32_ST_INFO(buf) & 0xf)
#define ELF32_ST_OTHER(buf)     ELF_FIELD(Elf_Byte, buf, 13)
#define ELF32_ST_SHNDX(buf)     ELF_FIELD(Elf32_Half, buf, 14)

/* symbol name */
#define ELF_STN_UNDEF      0

/* symbol bindings */
#define ELF_STB_LOCAL      0
#define ELF_STB_GLOBAL     1
#define ELF_STB_LOPROC     13
#define ELF_STB_HIPROC     15

/* symbol types */
#define ELF_STT_NOTYPE     0
#define ELF_STT_LOPROC     13
#define ELF_STT_HIPROC     15

/* relocation */
typedef Elf_Byte Elf32_Rel[8];
#define ELF32_REL_OFFSET(buf)   ELF_FIELD(Elf32_Word, buf, 0)
#define ELF32_REL_INFO(buf)     ELF_FIELD(Elf32_Word, buf, 4)
#define ELF32_R_SYM(buf)        (ELF32_REL_INFO(buf) >> 8)
#define ELF32_R_TYPE(buf)       (ELF32_REL_INFO(buf) & 0xff)

/* relocation types */
#define ELF_R_NONE          0
#define ELF_R_SMLSHARP_32   1

/* note */
typedef Elf_Byte Elf32_Nhdr[12];
#define ELF32_NH_NAMESZ(buf)    ELF_FIELD(Elf32_Word, buf, 0)
#define ELF32_NH_DESCSZ(buf)    ELF_FIELD(Elf32_Word, buf, 4)
#define ELF32_NH_TYPE(buf)      ELF_FIELD(Elf32_Word, buf, 8)
#define ELF32_NOTE_STRLEN(x) \
	((((x)+sizeof(Elf32_Word)-1) / sizeof(Elf32_Word)) * sizeof(Elf32_Word))

#define ELF_NT_SMLSHARP_VERSION 0

#endif /* SMLSHARP__ELF_H__ */
