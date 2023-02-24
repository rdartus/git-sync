# Converting from git-sync v3.x to v4.x

Git-sync v4 is a significant change from v3.  It includes several flag changes
(though many of the old flags are kept for backwards compatibility), but more
importantly it fundamentally changes the way the internal sync-loop works.

## The v3 loop

The way git-sync v3.x works is sort of like how a human might work:

  1) `git clone <repo> <branch>`
  2) `git fetch <remote>`
  3) `git checkout <ref>`

This made the code somewhat complicated, since it had to keep track of whether
this was the first pass (clone) or a subsequent pass (fetch).  This led to a
number of bugs related to back-to-back runs of git-sync, and some race
conditions.

## The v4 loop

In v4.x the loop is simpler - every pass is the same.  This takes advantage of
some idempotent behaviors (e.g. `git init` is safe to re-run) and uses git more
efficiently.  Instead of cloning a branch, git-sync will now fetch exactly the
commit (by SHA) it needs.  This transfers less data and closes the race
condition where a symbolic name can change after `git ls-remote` but before
`git fetch`.

## Flags

The flag syntax parsing has changed in v4.  git-sync v3 accept flags in Go's
own style: either `-flag` or `--flag` were accepted.  git-sync v4 only accepts
long flag names in the more common two-dash style (`--flag`), and accepts short
(single-character) flags in the one-dash style (`-v 2`).

The following does not detail every flag available in v4 - just the one that
existed in v3 and are different in v4.

### Verbosity: `--v` -> `-v` or `--verbose`

The change in flag parsing affects the old `--v` syntax.  To set verbosity
either use `-v` or `--verbose`.  For backwards compatibility, `--v` will be
used if it is specified.

### Sync target: `--branch` and `--rev` -> `--ref`

The old `--branch` and `--rev` flags are deprecated in favor of the new `--ref`
flag.  `--ref` can be either a branch name, a tag name, or a commit hash (aka
SHA).  For backwards compatibility, git-sync will still accept the old flags
and try to set `--ref` from them.

    |----------|---------|---------|------------------------------|
    | --branch |  --rev  |  --ref  |            meaning           |
    |----------|---------|---------|------------------------------|
    |    ""    |   ""    | "HEAD"  | remote repo's default branch |
    |  brname  |   ""    | brname  | remote branch `brname`       |
    |  brname  | "HEAD"  | brname  | remote branch `brname`       |
    |    ""    | tagname | tagname | remote tag `tagname`         |
    |   other  |  other  |   ""    | error                        |
    |----------|---------|---------|------------------------------|

### Log-related flags

git-sync v3 exposed a number of log-related flags (e.g. `-logtostderr`).  These
have all been removed.  git-sync v4 always logs to stderr, and the only control
offered is the verbosity level (`-v / --verbose`).

### Symlink: `--dest` -> `--link`

The old `--dest` flag is deprecated in favor of `--link`, which more clearly
conveys what it does.  The allowed values remain the same, and for backwards
compatibility, `--dest` will be used if it is specified.

### Loop: `--wait` -> `--period`

The old `--wait` flag took a floating-point number of seconds as an argument
(e.g. "0.1" = 100ms).  The new `--period` flag takes a Go-style duration string
(e.g. "100ms" or "0.1s" = 100ms).  For backwards compatibility, `--wait` will
be used if it is specified.

### Failures: `--max-sync-failures` -> `--max-failures`

The new name of this flag is shorter and captures the idea that any
non-recoverable error in the sync loop counts as a failure.  For backwards
compatibility, `--max-sync-failures` will be used if it is specified.

### Timeouts: `--timeout` -> `--sync-timeout`

The old `--timeout` flag took an integer number of seconds as an argument.  The
new `--sync-timeout` flag takes a Go-style duration string (e.g. "30s" or
"0.5m").  For backwards compatibility, `--timeout` will be used if it is
specified.

### Manual: `--man`

The new `--man` flag prints a man-page style help document and exits.

## Env vars

Most flags can also be configured by environment variables.  In v3 the
variables all start with `GIT_SYNC_`.  In v4 they all start with `GITSYNC_`,
though the old names are still accepted for compatibility.

## Defaults

### Depth

git-sync v3 would sync the entire history of the remote repo by default.  v4
syncs just one commit, by default.  This can be a significant performance and
disk-space savings for large repos.  Users who want the full history can
specify `--depth=0`.

## Logs

The logging output for v3 was semi-free-form text.  Log output in v4 is
structured and rendered as strict JSON.

## Other changes

git-sync v3 would allow invalidly formatted env vars (e.g. a value that was
expected to be boolean holding an integer) and just ignore them with
a warning.  v4 requires that they parse correctly.