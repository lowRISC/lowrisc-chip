#include "elf.h"
#include "loadelf.hpp"
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <assert.h>
#include <unistd.h>
#include <vector>
#include <cstring>

std::map<std::string, uint64_t> elfLoader::operator() (const std::string& fn) {
  int fd = open(fn.c_str(), O_RDONLY);
  struct stat s;
  assert(fd != -1);
  assert(fstat(fd, &s) != -1);
  size_t size = s.st_size;

  char* buf = (char*)mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
  assert(buf != MAP_FAILED);
  close(fd);

  assert(size >= sizeof(Elf64_Ehdr));
  const Elf64_Ehdr* eh = (const Elf64_Ehdr*)buf;
  assert(IS_ELF64(*eh));

  std::vector<uint8_t> zeros;
  std::map<std::string, uint64_t> symbols;

  Elf64_Phdr* ph = (Elf64_Phdr*)(buf + eh->e_phoff);
  assert(size >= eh->e_phoff + eh->e_phnum*sizeof(*ph));
  for (unsigned i = 0; i < eh->e_phnum; i++) {
    if(ph[i].p_type == PT_LOAD && ph[i].p_memsz) {
      if (ph[i].p_filesz) {
        assert(size >= ph[i].p_offset + ph[i].p_filesz);
        write(ph[i].p_paddr, ph[i].p_filesz, (uint8_t*)buf + ph[i].p_offset);
      }
      if(ph[i].p_memsz - ph[i].p_filesz > 0) {
        zeros.resize(ph[i].p_memsz - ph[i].p_filesz);
        write(ph[i].p_paddr + ph[i].p_filesz, ph[i].p_memsz - ph[i].p_filesz, &zeros[0]);
      }
    }
  }
  Elf64_Shdr* sh = (Elf64_Shdr*)(buf + eh->e_shoff);
  assert(size >= eh->e_shoff + eh->e_shnum*sizeof(*sh));
  assert(eh->e_shstrndx < eh->e_shnum);
  assert(size >= sh[eh->e_shstrndx].sh_offset + sh[eh->e_shstrndx].sh_size);
  char *shstrtab = buf + sh[eh->e_shstrndx].sh_offset;
  unsigned strtabidx = 0, symtabidx = 0;
  for (unsigned i = 0; i < eh->e_shnum; i++) {
    unsigned max_len = sh[eh->e_shstrndx].sh_size - sh[i].sh_name;
    assert(sh[i].sh_name < sh[eh->e_shstrndx].sh_size);
    assert(strnlen(shstrtab + sh[i].sh_name, max_len) < max_len);
    if (sh[i].sh_type & SHT_NOBITS) continue;
    assert(size >= sh[i].sh_offset + sh[i].sh_size);
    if (strcmp(shstrtab + sh[i].sh_name, ".strtab") == 0)
      strtabidx = i;
    if (strcmp(shstrtab + sh[i].sh_name, ".symtab") == 0)
      symtabidx = i;
  }
  if (strtabidx && symtabidx) {
    char* strtab = buf + sh[strtabidx].sh_offset;
    Elf64_Sym* sym = (Elf64_Sym*)(buf + sh[symtabidx].sh_offset);
    for (unsigned i = 0; i < sh[symtabidx].sh_size/sizeof(Elf64_Sym); i++) {
      unsigned max_len = sh[strtabidx].sh_size - sym[i].st_name;
      assert(sym[i].st_name < sh[strtabidx].sh_size);
      assert(strnlen(strtab + sym[i].st_name, max_len) < max_len);
      symbols[strtab + sym[i].st_name] = sym[i].st_value;
    }
  }

  munmap(buf, size);

  return symbols;
}
