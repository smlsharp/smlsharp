/**
 * loadelf.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: loadelf.c,v 1.4 2010/01/19 12:15:23 katsu Exp $
 */

#include <limits.h>
#include <string.h>
#include <dlfcn.h>
#include "error.h"
#include "memory.h"
#include "file.h"
#include "env.h"
#include "exe.h"

#define ELF_SIZE 32
#include "elf.h"

typedef ELF_TYPE(Word)  Elf_Word;
#define WORD_SIZE(x) ((x + ELF_TSIZE(Word) - 1) / ELF_TSIZE(Word))

static const Elf_Magic magic = ELF_EI_MAGIC_VALUES;
static const Elf_Byte smlsharp[] = "SML#";
static const Elf_Byte version[] = "0.30";

#define SMLSHARP_VERSION_MAXLEN 16  /* including sentinel */
#define SMLSHARP_NOTE_MAXSIZE					\
	(ELF_TSIZE(Nhdr) +					\
	 ELF(NOTE_STRLEN)(sizeof(smlsharp)) +			\
	 ELF(NOTE_STRLEN)(SMLSHARP_VERSION_MAXLEN))

struct range {
	size_t offset, size;
};

struct elf {
	file_t *file;
	int bswap;               /* 1 = byteorder swapping is needed. */
	unsigned int e_shnum;
	unsigned int e_shstrndx;
	ELF_TYPE(Shdr) *shdr;    /* section headers */
	void **content;          /* section contents */
	executable_t *exe;
	struct range prog_range; /* range of progbits */
	struct range mem_range;  /* range of nobits */
};

static void
elf_init(struct elf *elf, file_t *file)
{
	elf->file = file;
	elf->e_shnum = 0;
	elf->shdr = NULL;
	elf->content = NULL;
	elf->exe = NULL;
}

static void
elf_free(struct elf *elf)
{
	unsigned int i;

	if (elf->content) {
		for (i = 0; i < elf->e_shnum; i++)
			free(elf->content[i]);
	}
	free(elf->content);
	free(elf->shdr);
	exe_free(elf->exe);
}

static void
range_init(struct range *range)
{
	range->offset = 0;
	range->size = 0;
}

static int
range_add(struct range *range, size_t offset, size_t size)
{
	if (range->offset == 0 && range->size == 0) {
		range->offset = offset;
		range->size = size;
		return 0;
	}
	else if (range->offset + range->size <= offset) {
		range->size += offset - (range->offset + range->size) + size;
		return 0;
	}
	else if (offset + size <= range->offset) {
		range->offset = offset;
		range->size += size + range->offset - (offset + size);
		return 0;
	}
	return ERR_FAILED;
}

static status_t
read_shdr(struct elf *elf, size_t offset)
{
	status_t err;
	unsigned int i;
	size_t shdr_size;

	DBG(("loading section headers: e_shnum=%u", elf->e_shnum));

	if (elf->e_shnum == 0) {
		error(0, "%s: no section header", elf->file->filename);
		return ERR_INVALID;
	}

	shdr_size = elf->e_shnum * ELF_TSIZE(Shdr);
	elf->shdr = xmalloc(shdr_size);
	elf->content = xmalloc(elf->e_shnum * sizeof(void*));

	for (i = 0; i < elf->e_shnum; i++)
		elf->content[i] = NULL;

	err = elf->file->read(elf->file, offset, shdr_size, elf->shdr);
	if (err) {
		error(err, "%s: could not read section header",
		      elf->file->filename);
		return err;
	}

	if (elf->bswap) {
		for (i = 0; i < shdr_size / ELF_TSIZE(Word); i++)
			ELF(WORD_BSWAP)(((ELF_TYPE(Word)*)elf->shdr)[i]);
	}

#ifdef DEBUG
	for (i = 0; i < elf->e_shnum; i++) {
		DBG(("section %u: "
		     "SH_NAME=%"PRIuMAX", "
		     "SH_TYPE=%"PRIuMAX", "
		     "SH_FLAGS=%"PRIuMAX", "
		     "SH_ADDR=%"PRIuMAX", "
		     "SH_OFFSET=%"PRIuMAX", "
		     "SH_SIZE=%"PRIuMAX", "
		     "SH_LINK=%"PRIuMAX", "
		     "SH_INFO=%"PRIuMAX", "
		     "SH_ADDRALIGN=%"PRIuMAX", "
		     "SH_ENTSIZE=%"PRIuMAX,
		     i,
		     (uintmax_t)ELF(SH_NAME)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_TYPE)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_FLAGS)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_ADDR)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_OFFSET)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_SIZE)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_LINK)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_INFO)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_ADDRALIGN)(&elf->shdr[i]),
		     (uintmax_t)ELF(SH_ENTSIZE)(&elf->shdr[i])));
	}
#endif

	return 0;
}

static status_t
read_header(struct elf *elf)
{
	status_t err;
	Elf_Word buf[WORD_SIZE(ELF_TSIZE(Ehdr))];
	size_t e_shoff;

	DBG(("loading ELF header"));

	err = elf->file->read(elf->file, 0, ELF_TSIZE(Ehdr), buf);
	if (err) {
		error(err, "%s: could not read ELF header",
		      elf->file->filename);
		return err;
	}

	/* ELF identifier */
	if (!(memcmp(ELF_EI_MAGIC(buf), magic, sizeof(magic)) == 0
	      && ELF_EI_CLASS(buf) == ELFCLASS
	      && ELF_EI_VERSION(buf) == ELF_EV_CURRENT
	      && (ELF_EI_DATA(buf) == ELFDATA2LSB
		  || ELF_EI_DATA(buf) == ELFDATA2MSB))) {
		error(0, "%s: is not smlsharp-elf 1", elf->file->filename);
		return ERR_INVALID;
	}

	/* to load N bit format, we require that size of native pointer
	 * is equal to N. */
	if (ELF_SIZE != sizeof(void*) * CHAR_BIT) {
		error(0, "%s: is not fit to pointer size", elf->file->filename);
		return ERR_INVALID;
	}

	elf->bswap = (ELF_EI_DATA(buf) != ELFDATA_HOST);

	DBG(("bswap: %d", elf->bswap));

	/* ELF header */
	if (elf->bswap) {
		ELF(HALF_BSWAP)(ELF(E_TYPE)(buf));
		ELF(HALF_BSWAP)(ELF(E_MACHINE)(buf));
		ELF(WORD_BSWAP)(ELF(E_VERSION)(buf));
		ELF(ADDR_BSWAP)(ELF(E_ENTRY)(buf));
		ELF(HALF_BSWAP)(ELF(E_EHSIZE)(buf));
		ELF(HALF_BSWAP)(ELF(E_SHENTSIZE)(buf));
		ELF(OFF_BSWAP)(ELF(E_SHOFF)(buf));
		ELF(HALF_BSWAP)(ELF(E_SHNUM)(buf));
		ELF(HALF_BSWAP)(ELF(E_SHSTRNDX)(buf));
	}

	DBG(("E_TYPE: %u", ELF(E_TYPE)(buf)));
	DBG(("E_MACHINE: %u", ELF(E_MACHINE)(buf)));
	DBG(("E_VERSION: %u", ELF(E_VERSION)(buf)));
	DBG(("E_ENTRY: %u", ELF(E_ENTRY)(buf)));
	DBG(("E_EHSIZE: %u", ELF(E_EHSIZE)(buf)));
	DBG(("E_SHENTSIZE: %u", ELF(E_SHENTSIZE)(buf)));

	if (ELF(E_TYPE)(buf) != ELF_ET_REL
	    || ELF(E_MACHINE)(buf) != ELF_EM_NONE
	    || ELF(E_VERSION)(buf) != ELF_EV_CURRENT
	    || ELF(E_ENTRY)(buf) != 0
	    || ELF(E_EHSIZE)(buf) != ELF_TSIZE(Ehdr)
	    || ELF(E_SHENTSIZE)(buf) != ELF_TSIZE(Shdr)) {
		error(0, "%s: is not smlsharp-elf", elf->file->filename);
		return ERR_INVALID;
	}

	e_shoff = ELF(E_SHOFF)(buf);
	elf->e_shnum = ELF(E_SHNUM)(buf);
	elf->e_shstrndx = ELF(E_SHSTRNDX)(buf);

	err = read_shdr(elf, e_shoff);
	if (err)
		return err;

	return 0;
}

static status_t
check_note(struct elf *elf, size_t offset, size_t size)
{
	status_t err;
	Elf_Word buf[WORD_SIZE(SMLSHARP_NOTE_MAXSIZE)];
	size_t namesz, namelen, descsz, desclen;
	char *name, *desc;

	DBG(("offset=%"PRIuMAX", size=%"PRIuMAX", maxsize=%"PRIuMAX,
	     (uintmax_t)offset, (uintmax_t)size,
	     (uintmax_t)SMLSHARP_NOTE_MAXSIZE));

	if (size < ELF_TSIZE(Nhdr) || size > SMLSHARP_NOTE_MAXSIZE)
		return ERR_FAILED;

	err = elf->file->read(elf->file, offset, size, buf);
	if (err)
		return ERR_FAILED;

        if (elf->bswap) {
		ELF(WORD_BSWAP)(ELF(NH_TYPE)(buf));
		ELF(WORD_BSWAP)(ELF(NH_NAMESZ)(buf));
		ELF(WORD_BSWAP)(ELF(NH_DESCSZ)(buf));
        }

	DBG(("NH_TYPE: %"PRIuMAX, (uintmax_t)ELF(NH_TYPE)(buf)));

	if (ELF(NH_TYPE)(buf) != 0)
		return ERR_FAILED;

	namesz = ELF(NH_NAMESZ)(buf);
	namelen = ELF(NOTE_STRLEN)(namesz);
	descsz = ELF(NH_DESCSZ)(buf);
	desclen = ELF(NOTE_STRLEN)(descsz);

	DBG(("namesz=%"PRIuMAX", namelen=%"PRIuMAX", "
	     "descsz=%"PRIuMAX", desclen=%"PRIuMAX,
	     (uintmax_t)namesz, (uintmax_t)namelen,
	     (uintmax_t)descsz, (uintmax_t)desclen));

	if (ELF_TSIZE(Nhdr) + namelen + desclen > SMLSHARP_NOTE_MAXSIZE)
		return ERR_FAILED;

	name = (char*)buf + ELF_TSIZE(Nhdr);
	desc = name + namelen;

	if (namesz != sizeof(smlsharp)
	    || memcmp(name, smlsharp, namesz) != 0)
		return ERR_FAILED;

	if (descsz != sizeof(version)
	    || memcmp(desc, version, descsz) != 0)
		return ERR_FAILED;

	return 0;
}

static status_t
identify(struct elf *elf)
{
	unsigned int i;
	status_t err;
	int ident = 0;

	for (i = 0; !ident && i < elf->e_shnum; i++) {
		if (ELF(SH_TYPE)(&elf->shdr[i]) != ELF_SHT_NOTE)
			continue;
		err = check_note(elf,
				 ELF(SH_OFFSET)(&elf->shdr[i]),
				 ELF(SH_SIZE)(&elf->shdr[i]));
		if (err == 0) {
			DBG(("note section %u : identified", i));
			return 0;
		}
		if (err != ERR_FAILED)
			return err;
		DBG(("note section %u : cannot identify", i));
	}

	error(0, "%s: no valid SML# descriptor", elf->file->filename);
	return ERR_INVALID;
}

#define CHECK_WORD_ALIGNED(shdr) \
	(ELF(SH_OFFSET)(shdr) % ELF_TSIZE(Word) == 0 \
	 && ELF(SH_OFFSET)(shdr) % sizeof(void*) == 0)

static status_t
check_section_valid(struct elf *elf, unsigned int shndx,
		    unsigned int shty, unsigned int entsize)
{
	if (shndx == ELF_SHN_UNDEF || shndx >= elf->e_shnum) {
		error(0, "%s: invalid section index %u",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}
	if (ELF(SH_TYPE)(&elf->shdr[shndx]) != shty) {
		error(0, "%s: section %u has invalid type %u (expected %u)",
		      elf->file->filename, shndx,
		      ELF(SH_TYPE)(&elf->shdr[shndx]), shty);
		return ERR_INVALID;
	}
	if (ELF(SH_ENTSIZE)(&elf->shdr[shndx]) != entsize) {
		error(0, "%s: section %u has invalid entsize %u (expected %u)",
		      elf->file->filename, shndx,
		      ELF(SH_ENTSIZE)(&elf->shdr[shndx]), entsize);
		return ERR_INVALID;
	}
	if (!CHECK_WORD_ALIGNED(&elf->shdr[shndx])) {
		error(0, "%s: section %u is not word-aligned",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}
	if (ELF(SH_ADDRALIGN)(&elf->shdr[shndx]) != 0
	    && (ELF(SH_OFFSET)(&elf->shdr[shndx])
		% ELF(SH_ADDRALIGN)(&elf->shdr[shndx]) != 0)) {
		error(0, "%s: unaligned section %u",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}

	return 0;
}

static void *
read_section(struct elf *elf, unsigned int shndx, status_t *err_ret)
{
	status_t err;
	size_t offset, size;
	void *buf;

	/* assume that shndx is valid */
	offset = ELF(SH_OFFSET)(&elf->shdr[shndx]);
	size = ELF(SH_SIZE)(&elf->shdr[shndx]);

	DBG(("shndx=%u, offset=%"PRIuMAX", size=%"PRIuMAX,
	     shndx, (uintmax_t)offset, (uintmax_t)size));

	if (size == 0) {
		error(0, "%s: section %u has no content",
		      elf->file->filename, shndx);
		*err_ret = ERR_INVALID;
		return NULL;
	}

	buf = xmalloc(size);
	err = elf->file->read(elf->file, offset, size, buf);
	if (err) {
		error(err, "%s: could not read section %u",
		      elf->file->filename, shndx);
		free(buf);
		*err_ret = err;
		return NULL;
	}

	*err_ret = err;
	return buf;
}

static status_t
read_strtab(struct elf *elf, unsigned int shndx)
{
	status_t err;
	char *strtab;

	DBG(("loading strtab %u", shndx));

	err = check_section_valid(elf, shndx, ELF_SHT_STRTAB, 0);
	if (err)
		return err;

	if (elf->content[shndx])
		return 0;

	strtab = read_section(elf, shndx, &err);
	if (strtab == NULL)
		return err;

	if (strtab[ELF(SH_SIZE)(&elf->shdr[shndx]) - 1] != '\0') {
		error(0, "%s: unterminated strtab %u",
		      elf->file->filename, shndx);
		free(strtab);
		return ERR_INVALID;
	}

	elf->content[shndx] = strtab;
	return 0;
}

static status_t
get_name(struct elf *elf, unsigned int strtabndx,
	 size_t namendx, const char **dst)
{
	status_t err;

	if (namendx == ELF_STN_UNDEF) {
		*dst = NULL;
		return 0;
	}
	if (namendx >= ELF(SH_SIZE)(&elf->shdr[strtabndx])) {
		error(0, "%s: name index %lu exceeded with %u",
		      elf->file->filename, (unsigned long)namendx, strtabndx);
		return ERR_INVALID;
	}
	if (elf->content[strtabndx] == NULL) {
		err = read_strtab(elf, strtabndx);
		if (err)
			return err;
	}

	*dst = (char*)elf->content[strtabndx] + namendx;
	return 0;
}

static status_t
add_section_to_range(struct elf *elf, unsigned int shndx, unsigned int shtype,
		     struct range *range)
{
	int err;

	if (ELF(SH_TYPE)(&elf->shdr[shndx]) != shtype) {
		error(0, "%s: invalid type of section %u",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}
	err = range_add(range,
			ELF(SH_OFFSET)(&elf->shdr[shndx]),
			ELF(SH_SIZE)(&elf->shdr[shndx]));
	if (err) {
		error(0, "%s: section %u must be clustered",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}
	return 0;
}

static status_t
read_prog(struct elf *elf)
{
	status_t err;
	unsigned int i;
	const char *name;
	struct range init_range, insn_range, bbss_range;

	DBG(("loading progbits"));

	range_init(&elf->prog_range);
	range_init(&elf->mem_range);
	range_init(&init_range);
	range_init(&insn_range);
	range_init(&bbss_range);

	for (i = 0; i < elf->e_shnum; i++) {
		switch (ELF(SH_TYPE)(&elf->shdr[i])) {
		case ELF_SHT_PROGBITS:
			/* must be word-aligned */
			if (!CHECK_WORD_ALIGNED(&elf->shdr[i])) {
				error(0, "%s: section %u is not word-aligned",
				      elf->file->filename, i);
				return ERR_INVALID;
			}
			if (!(ELF(SH_FLAGS)(&elf->shdr[i]) & ELF_SHF_ALLOC)) {
				error(0, "%s: unalloced progbits section",
				      elf->file->filename);
				return ERR_INVALID;
			}
			if (ELF(SH_FLAGS)(&elf->shdr[i]) & ELF_SHF_WRITE) {
				error(0, "%s: writable progbits section",
				      elf->file->filename);
				return ERR_INVALID;
			}

			err = range_add(&elf->prog_range,
					ELF(SH_OFFSET)(&elf->shdr[i]),
					ELF(SH_SIZE)(&elf->shdr[i]));
			if (err) {
				error(0, "%s: non-clustered progbits section",
				      elf->file->filename);
				return ERR_INVALID;
			}

			if (ELF(SH_FLAGS)(&elf->shdr[i]) & ELF_SHF_EXECINSTR) {
				err = range_add(&insn_range,
						ELF(SH_OFFSET)(&elf->shdr[i]),
						ELF(SH_SIZE)(&elf->shdr[i]));
				if (err) {
					error(0, "%s: non-clustered EXECINSTR"
					      " section",
					      elf->file->filename);
					return ERR_INVALID;
				}
			}

			break;

		case ELF_SHT_NOBITS:
			/* must be word-aligned */
			if (!CHECK_WORD_ALIGNED(&elf->shdr[i])) {
				error(0, "%s: section %u is not word-aligned",
				      elf->file->filename, i);
				return ERR_INVALID;
			}
			if (!(ELF(SH_FLAGS)(&elf->shdr[i]) & ELF_SHF_ALLOC)) {
				error(0, "%s: unalloced nobits section",
				      elf->file->filename);
				return ERR_INVALID;
			}
			if (!(ELF(SH_FLAGS)(&elf->shdr[i]) & ELF_SHF_WRITE)) {
				error(0, "%s: unwritable nobits section",
				      elf->file->filename);
				return ERR_INVALID;
			}

			err = range_add(&elf->mem_range,
 					ELF(SH_OFFSET)(&elf->shdr[i]),
					ELF(SH_SIZE)(&elf->shdr[i]));
			if (err) {
				error(0, "%s: non-clustered nobits section",
				      elf->file->filename);
				return ERR_INVALID;
			}
			break;

		default:
			break;
		}

		err = get_name(elf, elf->e_shstrndx,
			       ELF(SH_NAME)(&elf->shdr[i]), &name);
		if (err)
			return err;

		if (name == NULL)  /* STN_UNDEF */
			err = 0;
		else if (strcmp(name, ".init") == 0)
			err = add_section_to_range(elf, i, ELF_SHT_PROGBITS,
						   &init_range);
		else if (strcmp(name, ".sml#.bbss") == 0)
			err = add_section_to_range(elf, i, ELF_SHT_NOBITS,
						   &bbss_range);
		else
			err = 0;

		if (err)
			return err;
	}

	DBG(("prog_range: offset=%"PRIuMAX", size=%"PRIuMAX,
	     (uintmax_t)elf->prog_range.offset,
	     (uintmax_t)elf->prog_range.size));
	DBG(("mem_range: offset=%"PRIuMAX", size=%"PRIuMAX,
	     (uintmax_t)elf->mem_range.offset,
	     (uintmax_t)elf->mem_range.size));
	DBG(("init_range: offset=%"PRIuMAX", size=%"PRIuMAX,
	     (uintmax_t)init_range.offset,
	     (uintmax_t)init_range.size));
	DBG(("insn_range: offset=%"PRIuMAX", size=%"PRIuMAX,
	     (uintmax_t)insn_range.offset,
	     (uintmax_t)insn_range.size));
	DBG(("bbss_range: offset=%"PRIuMAX", size=%"PRIuMAX,
	     (uintmax_t)bbss_range.offset,
	     (uintmax_t)bbss_range.size));

	elf->exe = exe_new(elf->prog_range.size, elf->mem_range.size);

	if (elf->prog_range.offset != 0) {
		err = elf->file->read(elf->file,
				      elf->prog_range.offset,
				      elf->prog_range.size,
				      elf->exe->prog);
		if (err) {
			error(err, "%s: could not read program",
			      elf->file->filename);
			return err;
		}
		elf->exe->init_beg = (char*)elf->exe->prog
			+ (init_range.offset - elf->prog_range.offset);
		elf->exe->insn_beg = (char*)elf->exe->prog
			+ (insn_range.offset - elf->prog_range.offset);
		elf->exe->init_size = init_range.size;
		elf->exe->insn_size = insn_range.size;
	}

	if (elf->mem_range.offset != 0) {
		/* initialize bbs and bbss section with null pointer */
		for (i = 0; i < elf->mem_range.size; i += sizeof(void*))
			*(void**)((char*)elf->exe->mem + i) = NULL;

		elf->exe->bbss_beg = (char*)elf->exe->mem
			+ (bbss_range.offset - elf->mem_range.offset);
		elf->exe->bbss_size = bbss_range.size;
	}

	return 0;
}

static status_t
load_address(struct elf *elf, unsigned int shndx, size_t offset, void **dst)
{
	if (shndx == ELF_SHN_UNDEF) {
		*dst = NULL;
		return 0;
	}
	if (shndx >= elf->e_shnum) {
		error(0, "%s: invalid section index %u",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}
	if (!(ELF(SH_FLAGS)(&elf->shdr[shndx]) & ELF_SHF_ALLOC)) {
		error(0, "%s: unalloced section %u",
		      elf->file->filename, shndx);
		return ERR_INVALID;
	}
	/* allow to indicate the first byte of follower */
	if (offset > ELF(SH_SIZE)(&elf->shdr[shndx])) {
		error(0, "%s: address 0x%lu exceeded with %u",
		      elf->file->filename, (unsigned long)offset, shndx);
		return ERR_INVALID;
	}

	/* program must be loaded to memory before calling load_address */
	ASSERT(elf->exe != NULL);

	switch (ELF(SH_TYPE)(&elf->shdr[shndx])) {
	case ELF_SHT_PROGBITS:
		if (elf->exe->prog == NULL) {
			error(0, "%s: no program loaded", elf->file->filename);
			return ERR_INVALID;
		}
		*dst = (char*)elf->exe->prog
			+ (ELF(SH_OFFSET)(&elf->shdr[shndx])
			   - elf->prog_range.offset
			   + offset);
		return 0;
	case ELF_SHT_NOBITS:
		if (elf->exe->mem == NULL) {
			error(0, "%s: no memory allocated",
			      elf->file->filename);
			return ERR_INVALID;
		}
		*dst = (char*)elf->exe->mem
			+ (ELF(SH_OFFSET)(&elf->shdr[shndx])
			   - elf->mem_range.offset
			   + offset);
		return 0;
	default:
		error(0, "%s: invalid section type %u of section %u",
		      elf->file->filename, ELF(SH_TYPE)(&elf->shdr[shndx]), shndx);
		return ERR_INVALID;
	}
}

static status_t
define_symbol(struct elf *elf, env_t *symenv,
	      unsigned int symbind, const char *name, void *addr)
{
	status_t err;

	if (symbind != ELF_STB_LOCAL && addr == NULL) {
		error(0, "%s: intended to define anonymous symbol",
		      elf->file->filename);
		return ERR_INVALID;
	}

	switch (symbind) {
	case ELF_STB_LOCAL:
		return 0;

	case ELF_STB_GLOBAL:
		err = env_define(symenv, name, addr);
		if (err == ERR_REDEFINED) {
			error(0, "%s: redefined symbol `%s'",
			      elf->file->filename, name);
			return ERR_INVALID;
		}
		else if (err) {
			error(err, "%s: symbol `%s' registration failed",
			      elf->file->filename, name);
			return err;
		}
		return 0;

	default:
		error(0, "%s: invalid symbol binding %u",
		      elf->file->filename, symbind);
		return ERR_INVALID;
	}
}

static status_t
resolve_symbol(struct elf *elf, env_t *symenv,
	       unsigned int symbind, const char *name, void **addr_ret)
{
	status_t err;

	if (name == NULL) {
		error(0, "%s: intended to resolve anonymous symbol",
		      elf->file->filename);
		return ERR_INVALID;
	}

	switch (symbind) {
	case ELF_STB_LOCAL:
		error(0, "%s: intended to resolve local symbol",
		      elf->file->filename);
		return ERR_INVALID;

	case ELF_STB_GLOBAL:
		err = env_lookup(symenv, name, addr_ret);
		if (err) {
			*addr_ret = dlsym(RTLD_DEFAULT, name);
			if (*addr_ret == NULL) {
				error(0, "%s: undefined symbol `%s'",
				      elf->file->filename, name);
				return ERR_UNDEFINED;
			}
		}
		break;

	default:
		error(0, "%s: invalid symbol binding %u",
		      elf->file->filename, symbind);
		return ERR_INVALID;
	}

	return 0;
}

static status_t
read_symtab(struct elf *elf, unsigned int symtabndx, env_t *symenv)
{
	status_t err, err_ret;
	unsigned int i;
	unsigned int strtabndx, namendx, shndx, bind;
	ELF_TYPE(Sym) *symtab;
	size_t num_syms, offset;
	void **dst;
	const char *name;
	void *addr;

	DBG(("resolving symtab %u", symtabndx));

	err = check_section_valid(elf, symtabndx,
				  ELF_SHT_SYMTAB, ELF_TSIZE(Sym));
	if (err)
		return err;

	strtabndx = ELF(SH_LINK)(&elf->shdr[symtabndx]);

	symtab = read_section(elf, symtabndx, &err);
	if (symtab == NULL)
		return err;
	num_syms = ELF(SH_SIZE)(&elf->shdr[symtabndx]) / ELF_TSIZE(Sym);

	/* overwrite symtab with array of symbol addresses. */
	dst = (void**)symtab;
	err_ret = 0;

	for (i = 0; i < num_syms; i++) {
		if (i == ELF_STN_UNDEF)
			continue;

		if (elf->bswap) {
			ELF(WORD_BSWAP)(ELF(ST_NAME)(&symtab[i]));
			ELF(ADDR_BSWAP)(ELF(ST_ADDR)(&symtab[i]));
			ELF(HALF_BSWAP)(ELF(ST_SHNDX)(&symtab[i]));
		}

		namendx = ELF(ST_NAME)(&symtab[i]);
		offset = ELF(ST_ADDR)(&symtab[i]);
		shndx = ELF(ST_SHNDX)(&symtab[i]);

		err = get_name(elf, strtabndx, namendx, &name);
		if (err) {
			error(0, "%s: invalid symbol name %u in %u",
			      elf->file->filename, i, symtabndx);
			err_ret = ERR_FAILED;
			continue;
		}
		err = load_address(elf, shndx, offset, &addr);
		if (err) {
			error(0, "%s: invalid symbol address %u in %u",
			      elf->file->filename, i, symtabndx);
			err_ret = ERR_FAILED;
			continue;
		}

		bind = ELF(ST_BIND)(&symtab[i]);
		if (addr)
			err = define_symbol(elf, symenv, bind, name, addr);
		else
			err = resolve_symbol(elf, symenv, bind, name, &addr);

		if (err) {
			DBG(("error at symbol %u in section %u", i, symtabndx));
			err_ret = err;
			continue;
		}

		DBG(("symbol %u `%s' -> %p", i, name, (void*)addr));
		dst[i] = addr;
	}

	if (err_ret) {
		free(symtab);
		return err_ret;
	}

	symtab = xrealloc(symtab, num_syms * sizeof(void*));
	elf->content[symtabndx] = symtab;
	return 0;
}

static status_t
read_symbols(struct elf *elf, env_t *symenv)
{
	status_t err;
	unsigned int i;

	for (i = 0; i < elf->e_shnum; i++) {
		if (ELF(SH_TYPE)(&elf->shdr[i]) != ELF_SHT_SYMTAB)
			continue;
		err = read_symtab(elf, i, symenv);
		if (err)
			return err;
	}

	return 0;
}

static status_t
read_reltab(struct elf *elf, unsigned int reltabndx)
{
	status_t err;
	unsigned int i;
	unsigned int symtabndx, secndx, symndx;
	void **symtab;
	void *base, **addr;
	size_t num_syms, num_rels, offset;
	ELF_TYPE(Rel) *reltab;

	DBG(("applying relocation %u", reltabndx));

	err = check_section_valid(elf, reltabndx,
				  ELF_SHT_REL, ELF_TSIZE(Rel));
	if (err)
		return err;

	symtabndx = ELF(SH_LINK)(&elf->shdr[reltabndx]);
	secndx = ELF(SH_INFO)(&elf->shdr[reltabndx]);

	DBG(("symtabndx=%"PRIuMAX", secndx=%"PRIuMAX,
	     (uintmax_t)symtabndx, (uintmax_t)secndx));

	err = check_section_valid(elf, symtabndx,
				  ELF_SHT_SYMTAB, ELF_TSIZE(Sym));
	if (err)
		return err;

	/* symtab must be resolved before calling read_rel */
	symtab = elf->content[symtabndx];
	ASSERT(symtab != NULL);
	num_syms = ELF(SH_SIZE)(&elf->shdr[symtabndx]) / ELF_TSIZE(Sym);

	/* program must be loaded before reading symtab */
	err = load_address(elf, secndx, 0, &base);
	if (err)
		return err;

	reltab = read_section(elf, reltabndx, &err);
	if (reltab == NULL)
		return err;
	num_rels = ELF(SH_SIZE)(&elf->shdr[reltabndx]) / ELF_TSIZE(Rel);

	err = 0;

	for (i = 0; i < num_rels; i++) {
		if (elf->bswap) {
			ELF(WORD_BSWAP)(ELF(REL_OFFSET)(&reltab[i]));
			ELF(WORD_BSWAP)(ELF(REL_INFO)(&reltab[i]));
		}

		offset = ELF(REL_OFFSET)(&reltab[i]);
		symndx = ELF(R_SYM)(&reltab[i]);

		if (symndx >= num_syms) {
			error(0, "%s: symbol index exceeded",
			      elf->file->filename);
			err = ERR_INVALID;
			break;
		}

		switch (ELF(R_TYPE)(&reltab[i])) {
		case ELF_R_SMLSHARP_32:
			addr = (void**)((char*)base + offset);
			*addr = symtab[symndx] + *(Elf32_Sword*)addr;
			DBG(("32: %p = %p (%u:%p)",
			     addr, *addr, symndx, symtab[symndx]));
			break;

		case ELF_R_NONE:
		default:
			error(0, "%s: invalid reloc type %u of %u in %u",
			      elf->file->filename, ELF(R_TYPE)(&reltab[i]),
			      i, reltabndx);
			err = ERR_INVALID;
			break;
		}
	}

	free(reltab);
	return err;
}

static status_t
relocate(struct elf *elf)
{
	status_t err;
	unsigned int i;

	for (i = 0; i < elf->e_shnum; i++) {
		if (ELF(SH_TYPE)(&elf->shdr[i]) != ELF_SHT_REL)
			continue;
		err = read_reltab(elf, i);
		if (err)
			return err;
	}

	return 0;
}

status_t
load_elf(file_t *file, env_t *symenv, executable_t **exe)
{
	status_t err;
	struct elf elf;

	elf_init(&elf, file);

	err = read_header(&elf);
	if (err)
		goto error;
	err = identify(&elf);
	if (err)
		goto error;
	err = read_prog(&elf);
	if (err)
		goto error;
	err = read_symbols(&elf, symenv);
	if (err) {
		env_rollback(symenv);
		goto error;
	}
	err = relocate(&elf);
	if (err) {
		env_rollback(symenv);
		goto error;
	}

	DBG(("loading complete."));

	*exe = elf.exe;
	elf.exe = NULL;
	err = 0;

 error:
	elf_free(&elf);
	return err;
}
