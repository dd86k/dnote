# dnote
## CLI note application

dnote is perfect for fast and quick notes. It is a simple CLI note application, saving notes in `~/.dnote` (or `C:\Users\%USERNAME%\.dnote` in Windows).

Only Windows is supported at the moment.

# Simple example in order
## Creating a note
`dnote create Hello!` will create a note `1` containing `Hello!`.

## Show the content of a note
`dnote show 1` will show `Hello!`.

## Listing notes
`dnote list` will show `1`.

## Modifying a note
`dnote modify 1 See you!` will override `1` from `Hello!` to `See you!`.

## Deleting a note
`dnote delete 1` will prompt the user to remove `1`, if `y`, deletes `1`.

More information is available with `/?` or `--help` per command.