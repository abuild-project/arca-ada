/* SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>

/* Fixed-width CLI ABI; never expose a platform-dependent struct stat to Ada. */
struct arca_metadata {
    uint64_t device, inode, size;
    int64_t mtime, mtime_ns;
    uint32_t mode, uid, gid, major, minor, kind;
};
_Static_assert(sizeof(struct arca_metadata) == 64, "metadata ABI size");
_Static_assert(sizeof(long) == 8, "CLI requires a 64-bit Linux ABI");

/* Keep target-specific constants beside the target-specific metadata layout. */
int arca_at_fdcwd(void)
{
    return AT_FDCWD;
}

unsigned int arca_rename_noreplace(void)
{
    return RENAME_NOREPLACE;
}

int arca_einval(void)
{
    return EINVAL;
}

int arca_enosys(void)
{
    return ENOSYS;
}

int arca_eopnotsupp(void)
{
    return EOPNOTSUPP;
}

int arca_enoent(void)
{
    return ENOENT;
}

int arca_lstat(const char *path, struct arca_metadata *out)
{
    struct stat info;
    if (lstat(path, &info) != 0)
        return errno;
    if (info.st_size < 0)
        return EOVERFLOW;
    out->device = (uint64_t)info.st_dev;
    out->inode = (uint64_t)info.st_ino;
    out->size = (uint64_t)info.st_size;
    out->mtime = (int64_t)info.st_mtim.tv_sec;
    out->mtime_ns = (int64_t)info.st_mtim.tv_nsec;
    out->mode = (uint32_t)(info.st_mode & 07777);
    out->uid = (uint32_t)info.st_uid;
    out->gid = (uint32_t)info.st_gid;
    out->major = (uint32_t)major(info.st_rdev);
    out->minor = (uint32_t)minor(info.st_rdev);
    out->kind = S_ISREG(info.st_mode) ? 0 : S_ISDIR(info.st_mode) ? 1 :
        S_ISLNK(info.st_mode) ? 2 : S_ISFIFO(info.st_mode) ? 3 :
        S_ISBLK(info.st_mode) ? 4 : S_ISCHR(info.st_mode) ? 5 : 6;
    return 0;
}
