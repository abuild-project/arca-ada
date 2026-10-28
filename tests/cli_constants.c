/* SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>

/* Independent target-header oracle, without importing the production bridge. */
int main(void)
{
    printf("{\"at_fdcwd\":%d,\"rename_noreplace\":%u,"
           "\"einval\":%d,\"enosys\":%d,\"eopnotsupp\":%d,\"enoent\":%d,"
           "\"directory_flags\":%d,\"archive_flags\":%d,"
           "\"remove_directory\":%d}\n",
           AT_FDCWD, (unsigned int)RENAME_NOREPLACE,
           EINVAL, ENOSYS, EOPNOTSUPP, ENOENT,
           O_PATH | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC,
           O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
           AT_REMOVEDIR);
    return 0;
}
