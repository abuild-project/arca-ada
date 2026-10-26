/* SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>

/* Independent target-header oracle, without importing the production bridge. */
int main(void)
{
    printf("{\"at_fdcwd\":%d,\"rename_noreplace\":%u,"
           "\"einval\":%d,\"enosys\":%d,\"eopnotsupp\":%d,\"enoent\":%d}\n",
           AT_FDCWD, (unsigned int)RENAME_NOREPLACE,
           EINVAL, ENOSYS, EOPNOTSUPP, ENOENT);
    return 0;
}
