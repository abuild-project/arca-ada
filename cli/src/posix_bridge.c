/* SPDX-License-Identifier: LGPL-2.1-or-later */
#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <unistd.h>

/* Fixed-width CLI ABI; never expose a platform-dependent struct stat to Ada. */
struct arca_metadata {
    uint64_t device, inode, size;
    int64_t mtime, mtime_ns;
    uint32_t mode, uid, gid, major, minor, kind;
};
_Static_assert(sizeof(struct arca_metadata) == 64, "metadata ABI size");
_Static_assert(sizeof(long) == 8, "CLI requires a 64-bit Linux ABI");

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

int arca_readlink(const char *path, char *target, size_t capacity)
{
    ssize_t length = readlink(path, target, capacity);
    if (length < 0)
        return errno;
    if ((size_t)length >= capacity)
        return ENAMETOOLONG;
    target[length] = '\0';
    return 0;
}

int arca_mkdtemp(char *path)
{
    return mkdtemp(path) == NULL ? errno : 0;
}

int arca_publish(const char *source, const char *target, int replace)
{
    /* Both paths are on the output parent's filesystem. No pre-unlink gap. */
    int result = replace ? rename(source, target) :
        renameat2(AT_FDCWD, source, AT_FDCWD, target, RENAME_NOREPLACE);
    return result == 0 ? 0 : errno;
}

/* One process-owned terminal flag; the handler performs no allocation/I/O. */
static volatile sig_atomic_t cancelled;
static void record_signal(int number)
{
    cancelled = number;
}

int arca_install_signals(void)
{
    struct sigaction action = {0};
    action.sa_handler = record_signal;
    /* Finish synchronous library I/O, then unwind at the next boundary. */
    action.sa_flags = SA_RESTART;
    sigemptyset(&action.sa_mask);
    if (sigaction(SIGINT, &action, NULL) || sigaction(SIGTERM, &action, NULL))
        return errno;
    return 0;
}

int arca_cancelled(void)
{
    return cancelled;
}
