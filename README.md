# simply-cpp-postgrest

[PostgREST](https://postgrest.org) (a REST API straight from a PostgreSQL database's schema),
its official static Linux build packaged as an apt package. There's no source of ours here
beyond the packaging: the binary is the release PostgREST publishes, downloaded and checked
against `SHA256.txt`.

This exists so a server or container gets PostgREST with `apt install` from apt.roelof.co.za,
updated like any other package, instead of a binary copied by hand.

## Install

```bash
curl -fsSL https://apt.roelof.co.za/setup.sh | bash
sudo apt -y install simply-cpp-postgrest
postgrest --version
```

It installs `/usr/bin/postgrest` and PostgREST's licence. The binary is statically linked, so the
same package serves jammy, noble and resolute. It brings no configuration or service: run it with
your own configuration file (`postgrest /etc/postgrest.conf`) under whatever starts it.

## The version

`VERSION.txt` is the PostgREST release packaged (13.0.7, the version 1Web's api containers ran
from a copied binary, byte for byte the same file), `SHA256.txt` the checksum of its
`postgrest-v<version>-linux-static-x86-64.tar.xz`.

## Publishing a new version

Set `VERSION.txt` to the release (it must have a `postgrest-v<version>-linux-static-x86-64.tar.xz`
asset on [the releases page](https://github.com/PostgREST/postgrest/releases)) and `SHA256.txt` to
that file's SHA-256, commit, then:

```bash
scripts/deploy.sh          # publishes to jammy/noble/resolute in one shot
```

The suite's `scripts/publish.sh` does the same for it, as for every module. The same version
packaged again (a packaging change) takes a `REVISION.txt`: 13.0.7-1.

## Licence

The packaging scripts are Apache-2.0 (`LICENSE`); PostgREST itself is MIT, its licence shipped in
the package (`/usr/share/doc/simply-cpp-postgrest/copyright`).
