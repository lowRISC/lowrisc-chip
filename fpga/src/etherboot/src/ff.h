/*---------------------------------------------------------------------------*/
/*  FatFs - FAT file system module include R0.11a    (C)ChaN, 2015           */
/*----------------------------------------------------------------------------*/
/* FatFs module is a free software that opened under license policy of
 * following conditions.
 *
 * Copyright (C) 2015, ChaN, all right reserved.
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this condition and the following disclaimer.
 *
 * This software is provided by the copyright holder and contributors "AS IS"
 * and any warranties related to this software are DISCLAIMED.
 * The copyright owner or contributors be NOT LIABLE for any damages caused
 * by use of this software.
 *
 * Copyright (c) 2015, University of Cambridge.
 * All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University of Cambridge nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * IN NO EVENT SHALL UNIVERSITY OF CAMBRIDGE BE LIABLE TO ANY PARTY FOR DIRECT,
 * INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS
 * HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * UNIVERSITY OF CAMBRIDGE SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT
 * NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY,
 * PROVIDED HEREUNDER IS PROVIDED "AS IS". UNIVERSITY OF CAMBRIDGE HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */
/*---------------------------------------------------------------------------*/

#ifndef _FATFS
#define _FATFS  64180   /* Revision ID */

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "ffconf.h"     /* FatFs configuration options */
#if _FATFS != _FFCONF
#error Wrong configuration file (ffconf.h).
#endif



  /* Definitions of volume management */

#if _MULTI_PARTITION        /* Multiple partition configuration */
  typedef struct {
    uint8_t pd;    /* Physical drive number */
    uint8_t pt;    /* Partition: 0:Auto detect, 1-4:Forced partition) */
  } PARTITION;
  extern PARTITION VolToPart[]; /* Volume - Partition resolution table */
#define LD2PD(vol) (VolToPart[vol].pd)  /* Get physical drive number */
#define LD2PT(vol) (VolToPart[vol].pt)  /* Get partition index */

#else                           /* Single partition configuration */
#define LD2PD(vol) (uint8_t)(vol)  /* Each logical drive is bound to the same physical drive number */
#define LD2PT(vol) 0            /* Find first valid partition or in SFD */

#endif



  /* Type of path name strings on FatFs API */

#if _LFN_UNICODE            /* Unicode string */
#if !_USE_LFN
#error _LFN_UNICODE must be 0 at non-LFN cfg.
#endif
#ifndef _INC_TCHAR
  typedef uint16_t TCHAR;
#define _T(x) L ## x
#define _TEXT(x) L ## x
#endif

#else                       /* ANSI/OEM string */
#ifndef _INC_TCHAR
  typedef char TCHAR;
#define _T(x) x
#define _TEXT(x) x
#endif

#endif



  /* File system object structure (FATFS) */

  typedef struct {
    uint8_t    fs_type;        /* FAT sub-type (0:Not mounted) */
    uint8_t    drv;            /* Physical drive number */
    uint8_t    csize;          /* Sectors per cluster (1,2,4...128) */
    uint8_t    n_fats;         /* Number of FAT copies (1 or 2) */
    uint8_t    wflag;          /* win[] flag (b0:dirty) */
    uint8_t    fsi_flag;       /* FSINFO flags (b7:disabled, b0:dirty) */
    uint16_t   id;             /* File system mount ID */
    uint16_t   n_rootdir;      /* Number of root directory entries (FAT12/16) */
#if _MAX_SS != _MIN_SS
    uint16_t   ssize;          /* Bytes per sector (512, 1024, 2048 or 4096) */
#endif
#if _FS_REENTRANT
    _SYNC_t    sobj;           /* Identifier of sync object */
#endif
#if !_FS_READONLY
    uint32_t   last_clust;     /* Last allocated cluster */
    uint32_t   free_clust;     /* Number of free clusters */
#endif
#if _FS_RPATH
    uint32_t   cdir;           /* Current directory start cluster (0:root) */
#endif
    uint32_t   n_fatent;       /* Number of FAT entries, = number of clusters + 2 */
    uint32_t   fsize;          /* Sectors per FAT */
    uint32_t   volbase;        /* Volume start sector */
    uint32_t   fatbase;        /* FAT start sector */
    uint32_t   dirbase;        /* Root directory start sector (FAT32:Cluster#) */
    uint32_t   database;       /* Data start sector */
    uint32_t   winsect;        /* Current sector appearing in the win[] */
    uint8_t    win[_MAX_SS];   /* Disk access window for Directory, FAT (and file data at tiny cfg) */
  } FATFS;



  /* File object structure (FIL) */

  typedef struct {
    FATFS*     fs;             /* Pointer to the related file system object (**do not change order**) */
    uint16_t   id;             /* Owner file system mount ID (**do not change order**) */
    uint8_t    flag;           /* Status flags */
    uint8_t    err;            /* Abort flag (error code) */
    uint32_t   fptr;           /* File read/write pointer (Zeroed on file open) */
    uint32_t   fsize;          /* File size */
    uint32_t   sclust;         /* File start cluster (0:no cluster chain, always 0 when fsize is 0) */
    uint32_t   clust;          /* Current cluster of fpter (not valid when fprt is 0) */
    uint32_t   dsect;          /* Sector number appearing in buf[] (0:invalid) */
#if !_FS_READONLY
    uint32_t   dir_sect;       /* Sector number containing the directory entry */
    uint8_t*   dir_ptr;        /* Pointer to the directory entry in the win[] */
#endif
#if _USE_FASTSEEK
    uint32_t*  cltbl;          /* Pointer to the cluster link map table (Nulled on file open) */
#endif
#if _FS_LOCK
    uint32_t   lockid;         /* File lock ID origin from 1 (index of file semaphore table Files[]) */
#endif
#if !_FS_TINY
    uint8_t    buf[_MAX_SS];   /* File private data read/write window */
#endif
  } FIL;



  /* Directory object structure (DIR) */

  typedef struct {
    FATFS*     fs;             /* Pointer to the owner file system object (**do not change order**) */
    uint16_t   id;             /* Owner file system mount ID (**do not change order**) */
    uint16_t   index;          /* Current read/write index number */
    uint32_t   sclust;         /* Table start cluster (0:Root dir) */
    uint32_t   clust;          /* Current cluster */
    uint32_t   sect;           /* Current sector */
    uint8_t*   dir;            /* Pointer to the current SFN entry in the win[] */
    uint8_t*   fn;             /* Pointer to the SFN (in/out) {file[8],ext[3],status[1]} */
#if _FS_LOCK
    uint32_t   lockid;         /* File lock ID (index of file semaphore table Files[]) */
#endif
#if _USE_LFN
    uint16_t*  lfn;            /* Pointer to the LFN working buffer */
    uint16_t   lfn_idx;        /* Last matched LFN index number (0xFFFF:No LFN) */
#endif
#if _USE_FIND
    const TCHAR* pat;          /* Pointer to the name matching pattern */
#endif
  } DIR;



  /* File information structure (FILINFO) */

  typedef struct {
    uint32_t   fsize;          /* File size */
    uint16_t   fdate;          /* Last modified date */
    uint16_t   ftime;          /* Last modified time */
    uint8_t    fattrib;        /* Attribute */
    TCHAR      fname[13];      /* Short file name (8.3 format) */
#if _USE_LFN
    TCHAR*     lfname;         /* Pointer to the LFN buffer */
    uint32_t   lfsize;         /* Size of LFN buffer in TCHAR */
#endif
  } FILINFO;



  /* File function return code (FRESULT) */

  typedef enum {
    FR_OK = 0,              /* (0) Succeeded */
    FR_DISK_ERR,            /* (1) A hard error occurred in the low level disk I/O layer */
    FR_INT_ERR,             /* (2) Assertion failed */
    FR_NOT_READY,           /* (3) The physical drive cannot work */
    FR_NO_FILE,             /* (4) Could not find the file */
    FR_NO_PATH,             /* (5) Could not find the path */
    FR_INVALID_NAME,        /* (6) The path name format is invalid */
    FR_DENIED,              /* (7) Access denied due to prohibited access or directory full */
    FR_EXIST,               /* (8) Access denied due to prohibited access */
    FR_INVALID_OBJECT,      /* (9) The file/directory object is invalid */
    FR_WRITE_PROTECTED,     /* (10) The physical drive is write protected */
    FR_INVALID_DRIVE,       /* (11) The logical drive number is invalid */
    FR_NOT_ENABLED,         /* (12) The volume has no work area */
    FR_NO_FILESYSTEM,       /* (13) There is no valid FAT volume */
    FR_MKFS_ABORTED,        /* (14) The f_mkfs() aborted due to any parameter error */
    FR_TIMEOUT,             /* (15) Could not get a grant to access the volume within defined period */
    FR_LOCKED,              /* (16) The operation is rejected according to the file sharing policy */
    FR_NOT_ENOUGH_CORE,     /* (17) LFN working buffer could not be allocated */
    FR_TOO_MANY_OPEN_FILES, /* (18) Number of open files > _FS_LOCK */
    FR_INVALID_PARAMETER    /* (19) Given parameter is invalid */
  } FRESULT;



  /*--------------------------------------------------------------*/
  /* FatFs module application interface                           */

  FRESULT f_open (FIL* fp, const TCHAR* path, uint8_t mode);         /* Open or create a file */
  FRESULT f_close (FIL* fp);                                         /* Close an open file object */
  FRESULT f_read (FIL* fp, void* buff, uint32_t btr, uint32_t* br);  /* Read data from a file */
  FRESULT f_write (FIL* fp, const void* buff, uint32_t btw, uint32_t* bw);  /* Write data to a file */
  FRESULT f_forward (FIL* fp, uint32_t(*func)(const uint8_t*,uint32_t), uint32_t btf, uint32_t* bf);   /* Forward data to the stream */
  FRESULT f_lseek (FIL* fp, uint32_t ofs);                           /* Move file pointer of a file object */
  FRESULT f_truncate (FIL* fp);                                      /* Truncate file */
  FRESULT f_sync (FIL* fp);                                          /* Flush cached data of a writing file */
  FRESULT f_opendir (DIR* dp, const TCHAR* path);                    /* Open a directory */
  FRESULT f_closedir (DIR* dp);                                      /* Close an open directory */
  FRESULT f_readdir (DIR* dp, FILINFO* fno);                         /* Read a directory item */
  FRESULT f_findfirst (DIR* dp, FILINFO* fno, const TCHAR* path, const TCHAR* pattern); /* Find first file */
  FRESULT f_findnext (DIR* dp, FILINFO* fno);                        /* Find next file */
  FRESULT f_mkdir (const TCHAR* path);                               /* Create a sub directory */
  FRESULT f_unlink (const TCHAR* path);                              /* Delete an existing file or directory */
  FRESULT f_rename (const TCHAR* path_old, const TCHAR* path_new);   /* Rename/Move a file or directory */
  FRESULT f_stat (const TCHAR* path, FILINFO* fno);                  /* Get file status */
  FRESULT f_chmod (const TCHAR* path, uint8_t attr, uint8_t mask);   /* Change attribute of the file/dir */
  FRESULT f_utime (const TCHAR* path, const FILINFO* fno);           /* Change times-tamp of the file/dir */
  FRESULT f_chdir (const TCHAR* path);                               /* Change current directory */
  FRESULT f_chdrive (const TCHAR* path);                             /* Change current drive */
  FRESULT f_getcwd (TCHAR* buff, uint32_t len);                      /* Get current directory */
  FRESULT f_getfree (const TCHAR* path, uint32_t* nclst, FATFS** fatfs);   /* Get number of free clusters on the drive */
  FRESULT f_getlabel (const TCHAR* path, TCHAR* label, uint32_t* vsn); /* Get volume label */
  FRESULT f_setlabel (const TCHAR* label);                           /* Set volume label */
  FRESULT f_mount (FATFS* fs, const TCHAR* path, uint8_t opt);       /* Mount/Unmount a logical drive */
  FRESULT f_mkfs (const TCHAR* path, uint8_t sfd, uint32_t au);      /* Create a file system on the volume */
  FRESULT f_fdisk (uint8_t pdrv, const uint32_t szt[], void* work);  /* Divide a physical drive into some partitions */
  int f_putc (TCHAR c, FIL* fp);                                     /* Put a character to the file */
  int f_puts (const TCHAR* str, FIL* cp);                            /* Put a string to the file */
  int f_printf (FIL* fp, const TCHAR* str, ...);                     /* Put a formatted string to the file */
  TCHAR* f_gets (TCHAR* buff, int len, FIL* fp);                     /* Get a string from the file */

#define f_eof(fp) ((int)((fp)->fptr == (fp)->fsize))
#define f_error(fp) ((fp)->err)
#define f_tell(fp) ((fp)->fptr)
#define f_size(fp) ((fp)->fsize)
#define f_rewind(fp) f_lseek((fp), 0)
#define f_rewinddir(dp) f_readdir((dp), 0)

#ifndef EOF
#define EOF (-1)
#endif




  /*--------------------------------------------------------------*/
  /* Additional user defined functions                            */

  /* RTC function */
#if !_FS_READONLY && !_FS_NORTC
  uint32_t get_fattime (void);
#endif

  /* Unicode support functions */
#if _USE_LFN                                          /* Unicode - OEM code conversion */
  uint16_t ff_convert (uint16_t chr, uint32_t dir);   /* OEM-Unicode bidirectional conversion */
  uint16_t ff_wtoupper (uint16_t chr);                /* Unicode upper-case conversion */
#if _USE_LFN == 3                                     /* Memory functions */
  void* ff_memalloc (uint32_t msize);                 /* Allocate memory block */
  void ff_memfree (void* mblock);                     /* Free memory block */
#endif
#endif

  /* Sync functions */
#if _FS_REENTRANT
  int ff_cre_syncobj (uint8_t vol, _SYNC_t* sobj);    /* Create a sync object */
  int ff_req_grant (_SYNC_t sobj);                    /* Lock sync object */
  void ff_rel_grant (_SYNC_t sobj);                   /* Unlock sync object */
  int ff_del_syncobj (_SYNC_t sobj);                  /* Delete a sync object */
#endif




  /*--------------------------------------------------------------*/
  /* Flags and offset address                                     */


  /* File access control and file status flags (FIL.flag) */

#define FA_READ             0x01
#define FA_OPEN_EXISTING    0x00

#if !_FS_READONLY
#define FA_WRITE            0x02
#define FA_CREATE_NEW       0x04
#define FA_CREATE_ALWAYS    0x08
#define FA_OPEN_ALWAYS      0x10
#define FA__WRITTEN         0x20
#define FA__DIRTY           0x40
#endif


  /* FAT sub type (FATFS.fs_type) */

#define FS_FAT12    1
#define FS_FAT16    2
#define FS_FAT32    3


  /* File attribute bits for directory entry */

#define AM_RDO  0x01    /* Read only */
#define AM_HID  0x02    /* Hidden */
#define AM_SYS  0x04    /* System */
#define AM_VOL  0x08    /* Volume label */
#define AM_LFN  0x0F    /* LFN entry */
#define AM_DIR  0x10    /* Directory */
#define AM_ARC  0x20    /* Archive */
#define AM_MASK 0x3F    /* Mask of defined bits */


  /* Fast seek feature */
#define CREATE_LINKMAP  0xFFFFFFFF



  /*--------------------------------*/
  /* Multi-byte word access macros  */
  /* Use byte-by-byte access to the FAT structure */
  /* converted to functions due to compiler bug (?) */
  
static uint16_t LD_WORD(const uint8_t *ptr)
{
  return (uint16_t)(((uint16_t)*((uint8_t*)(ptr)+1)<<8)|(uint16_t)*(uint8_t*)(ptr));
}
  
static uint32_t LD_DWORD(const uint8_t *ptr)
{
  return (uint32_t)(((uint32_t)*((uint8_t*)(ptr)+3)<<24)|((uint32_t)*((uint8_t*)(ptr)+2)<<16)|((uint16_t)*((uint8_t*)(ptr)+1)<<8)|*(uint8_t*)(ptr));
}
  
static void ST_WORD(uint8_t *ptr, uint16_t val)
  {
    *(uint8_t*)(ptr)=(uint8_t)(val); *((uint8_t*)(ptr)+1)=(uint8_t)((uint16_t)(val)>>8);
  }
  
static void ST_DWORD(uint8_t *ptr, uint32_t val)
{
  *(uint8_t*)(ptr)=(uint8_t)(val); *((uint8_t*)(ptr)+1)=(uint8_t)((uint16_t)(val)>>8); *((uint8_t*)(ptr)+2)=(uint8_t)((uint32_t)(val)>>16); *((uint8_t*)(ptr)+3)=(uint8_t)((uint32_t)(val)>>24);
}

#ifdef __cplusplus
}
#endif

#endif /* _FATFS */
