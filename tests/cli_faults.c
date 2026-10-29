/* SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Child-process-only fault injection. No production unit imports this file. */
#define NEXT(name, target) do { \
    void *address = dlsym(RTLD_NEXT, name); \
    _Static_assert(sizeof(target) == sizeof(address), "function pointer ABI"); \
    memcpy(&(target), &address, sizeof(target)); \
    if (!(target)) _exit(125); \
} while (0)

static int fault(const char *name)
{
    const char *selected = getenv("ARCA_TEST_FAULT");
    return selected && strstr(selected, name);
}

static void trace(const char *message)
{
    int saved = errno;
    const char *path = getenv("ARCA_TEST_FAULT_LOG");
    int fd = path ? open(path, O_WRONLY | O_CREAT | O_APPEND, 0600) : -1;
    if (fd < 0 || write(fd, message, strlen(message)) < 0 || close(fd) != 0)
        _exit(125);
    errno = saved;
}

static int phase_fd(const char *name)
{
    const char *value = getenv(name);
    char *end;
    if (!value || !*value)
        _exit(125);
    errno = 0;
    long fd = strtol(value, &end, 10);
    if (errno || *end || fd < 3 || fd > INT_MAX)
        _exit(125);
    return (int)fd;
}

static void phase_barrier(const char *path, const char *point)
{
    static int entered;
    if (!fault(point) || entered ||
        (!strstr(path, "/.arca-") && !strstr(path, "/proc/self/fd/")) ||
        (strcmp(point, "setup-barrier") && !strstr(path, "/archive")))
        return;
    entered = 1;

    /* Hold the selected setup/open boundary until the parent acknowledges
       its mutation. No writer operation proceeds before the release token. */
    int saved = errno;
    int ready = phase_fd("ARCA_TEST_READY_FD");
    int release = phase_fd("ARCA_TEST_RELEASE_FD");
    char token = 'R';
    ssize_t count;
    trace("barrier ready\n");
    do {
        count = write(ready, &token, 1);
    } while (count < 0 && errno == EINTR);
    if (count != 1)
        _exit(125);
    do {
        count = read(release, &token, 1);
    } while (count < 0 && errno == EINTR);
    if (count != 1 || token != 'G' || close(release) != 0 || close(ready) != 0)
        _exit(125);
    trace("barrier released\n");
    errno = saved;
}

/* Cover both libc stdio entry points used by GNAT runtimes. */
#define FOPEN_HOOK(name) \
FILE *name(const char *path, const char *mode) \
{ \
    FILE *(*original)(const char *, const char *); \
    NEXT(#name, original); \
    phase_barrier(path, "before-barrier"); \
    FILE *result = original(path, mode); \
    if (result) \
        phase_barrier(path, "phase-barrier"); \
    return result; \
}

FOPEN_HOOK(fopen)
FOPEN_HOOK(fopen64)

char *mkdtemp(char *path)
{
    char *(*original)(char *);
    NEXT("mkdtemp", original);
    char *result = original(path);
    if (result) {
        if (fault("stage-mode-0755") || fault("stage-mode-0775") ||
            fault("stage-mode-0757")) {
            mode_t mode = fault("stage-mode-0755") ? 0755 :
                fault("stage-mode-0775") ? 0775 : 0757;
            if (chmod(path, mode) != 0)
                _exit(125);
            trace("staging mode adjusted\n");
        }
        phase_barrier(path, "setup-barrier");
    }
    return result;
}

int sigwait(const sigset_t *set, int *number)
{
    int (*original)(const sigset_t *, int *);
    static _Thread_local int previous;
    NEXT("sigwait", original);

    /* GNAT 14 s-interr.adb invokes the protected handler between successive
       sigwait calls on its dedicated server thread. Report completion only
       on re-entry, never merely when the kernel delivers the signal. */
    int handled = previous;
    previous = 0;
    if (fault("phase-barrier") &&
        (handled == SIGINT || handled == SIGTERM || handled == SIGHUP)) {
        int saved = errno;
        int ready = phase_fd("ARCA_TEST_READY_FD");
        unsigned char token = (unsigned char)handled;
        ssize_t count;
        trace("signal handled\n");
        do {
            count = write(ready, &token, 1);
        } while (count < 0 && errno == EINTR);
        if (count != 1)
            _exit(125);
        errno = saved;
    }

    int result = original(set, number);
    if (result == 0)
        previous = *number;
    return result;
}

static int selected_directory(DIR *dir)
{
    char descriptor[64], path[4096];
    const char *source = getenv("ARCA_TEST_SOURCE");
    if (!source)
        return 0;
    snprintf(descriptor, sizeof(descriptor), "/proc/self/fd/%d", dirfd(dir));
    ssize_t length = readlink(descriptor, path, sizeof(path) - 1);
    if (length < 0)
        return 0;
    path[length] = '\0';
    return strcmp(path, source) == 0;
}

/* GNAT's readdir ABI differs with large-file configuration; cover both. */
#define READDIR_HOOK(name, entry) \
struct entry *name(DIR *dir) \
{ \
    struct entry *(*original)(DIR *); \
    static unsigned int calls; \
    NEXT(#name, original); \
    int selected = selected_directory(dir); \
    if (selected && fault("read-eio") && ++calls == 4) { \
        trace("read EIO\n"); \
        errno = EIO; \
        return NULL; \
    } \
    struct entry *result = original(dir); \
    if (selected && fault("read-stale") && result) { \
        trace("read stale errno\n"); \
        errno = EIO; \
    } \
    return result; \
}

READDIR_HOOK(readdir, dirent)
READDIR_HOOK(readdir64, dirent64)

int renameat2(int oldfd, const char *old, int newfd, const char *new,
              unsigned int flags)
{
    int (*original)(int, const char *, int, const char *, unsigned int);
    NEXT("renameat2", original);
    if (fault("rename-denied")) {
        trace("rename denied\n");
        errno = EACCES;
        return -1;
    }
    if (fault("rename-einval") || fault("rename-enosys") ||
        fault("rename-eopnotsupp")) {
        trace("rename unsupported\n");
        errno = fault("rename-enosys") ? ENOSYS :
            fault("rename-eopnotsupp") ? EOPNOTSUPP : EINVAL;
        return -1;
    }
    return original(oldfd, old, newfd, new, flags);
}

int linkat(int oldfd, const char *old, int newfd, const char *new, int flags)
{
    int (*original)(int, const char *, int, const char *, int);
    NEXT("linkat", original);
    trace("link attempted\n");
    if (fault("link-competitor")) {
        int fd = openat(newfd, new, O_WRONLY | O_CREAT | O_EXCL, 0600);
        const char message[] = "competing output";
        if (fd < 0 || write(fd, message, sizeof(message) - 1) !=
            (ssize_t)(sizeof(message) - 1) || close(fd) != 0)
            _exit(125);
        trace("competitor created\n");
    }
    if (fault("link-denied")) {
        errno = EACCES;
        return -1;
    }
    int result = original(oldfd, old, newfd, new, flags);
    if (result == 0 && fault("link-ambiguous")) {
        trace("link created with EIO reply\n");
        errno = EIO;
        return -1;
    }
    return result;
}

int unlinkat(int fd, const char *path, int flags)
{
    int (*original)(int, const char *, int);
    NEXT("unlinkat", original);
    if (fault("cleanup") && flags == AT_REMOVEDIR && strstr(path, ".arca-")) {
        trace("rmdir denied\n");
        errno = EACCES;
        return -1;
    }
    return original(fd, path, flags);
}

size_t fwrite(const void *ptr, size_t size, size_t count, FILE *stream)
{
    size_t (*original)(const void *, size_t, size_t, FILE *);
    NEXT("fwrite", original);
    if (fault("write-full")) {
        char descriptor[64], path[4096];
        snprintf(descriptor, sizeof(descriptor), "/proc/self/fd/%d",
                 fileno(stream));
        ssize_t length = readlink(descriptor, path, sizeof(path) - 1);
        if (length >= 0) {
            path[length] = '\0';
            if (strstr(path, "/.arca-") && strstr(path, "/archive")) {
                trace("write ENOSPC\n");
                errno = ENOSPC;
                return 0;
            }
        }
    }
    return original(ptr, size, count, stream);
}
