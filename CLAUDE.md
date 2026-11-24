# Github-ReleaseFetcher

This is a Perl distribution. It fetches the latest release asset, or a named release asset, from a GitHub project. It reads the HTML release page, because GitHub has no public listing that a program can read.

## Layout

- `lib/Github/ReleaseFetcher.pm` holds the module and its POD.
- `t/` holds the tests. They mock HTTP with `Test::Mock::HTTP::Tiny`, so they need no network.
- `dist.ini` and `weaver.ini` configure Dist::Zilla.
- `prereqs.yml` holds the prerequisites that AutoPrereqs cannot find.
- `.perlcriticrc` and `.perltidyrc` set the code standards.

## Rules

- The target is perl 5.014. Put `use 5.014;` in every module and test.
- Run `prove -l t` before each commit.
- Run `perlcritic --profile .perlcriticrc lib t`. It must report no violation.
- Turn a policy off only on purpose. Put the reason in a comment beside it.
- Run `perltidy --profile=.perltidyrc` on each file that you change.
- Commit through the hooks in `git-hooks/`. Do not use `--no-verify`.
- Add an entry to `Changes` for each change that a user can see.
- Write documentation in plain English: short sentences, active voice, no contractions.

## API

The call is `Github::ReleaseFetcher::fetch($outdir, $owner, $project, \%options)`. The keys of `%options` are `search`, `rename`, `version` and `ua`. The POD in the module describes each one.
