# Go Language Profile

**Status:** proposed for adoption with the Heartime implementation and the new Continuity institution packages.  
**Canonical basis:** PF-04 §2.1 Language Profiles, §3 Code Editorial Standard, §4.1 normal change path.

No adopted Go profile existed. Go is already a Powerfarm production language through Continuity; this profile does not retroactively declare existing code conforming.

| Element | Standard |
| --- | --- |
| Version policy | Go 1.26.x for Heartime. Continuity keeps its declared minimum (`go 1.23`) until a separate change raises it. Dependencies are pinned in `go.mod` and `go.sum`. |
| Authoritative guidance | [Effective Go](https://go.dev/doc/effective_go), [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments), the standard library documentation. |
| Formatter | `gofmt`; CI fails on any unformatted file. |
| Linter | [Staticcheck](https://staticcheck.dev) pinned per repository (currently `honnef.co/go/tools/cmd/staticcheck@v0.8.1`). |
| Static analysis | `go vet ./...` and the compiler. Further analyzers are added when a concrete defect justifies them. |
| Required checks | `gofmt`, `go vet`, Staticcheck, `go test -race ./...`, `go build ./...`. Durability and crash behavior are tested against real files and real processes, including SIGKILL. |
| Errors | Errors are part of the contract: exported sentinel errors wrapped with `%w`, checked with `errors.Is`. Persistence failures are never ignored; transport acknowledgement never implies an effect. |
| Persistence | `database/sql` with parameterized statements, explicit transactions, foreign keys, WAL and `synchronous=FULL` for SQLite ledgers. |
| Time | Business logic receives explicit instants; commands default to the system UTC clock and record operator-supplied instants as such. |
| Technical language | English identifiers, comments, errors, commits and technical documentation. |

## Material exceptions

- The SQLite drivers use cgo, so builds and tests need a C compiler; Continuity's effect journal links the system `libsqlite3`. Initial targets are Linux and macOS.
- In `powerfarm-continuity`, Staticcheck is required for the packages added with this profile (`internal/institution`, `cmd/institution-turn`, `cmd/census-turn`, `cmd/occupant-chat`). Three findings in imported code remain until a separate change: an unused function in `internal/semanticgraph`, a capitalized error string in `internal/runtime/smoke.go`, and a no-op branch in `internal/bus/nats_test.go`.

This profile introduces no local formatting or style alternative and makes no claim of production deployment readiness.
