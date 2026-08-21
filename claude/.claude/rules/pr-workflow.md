# Before opening a PR

Check for an existing open PR authored by you on the same repo that
covers the same feature or task:

gh pr list --author @me --repo <owner>/<repo> --state open

If a matching open PR exists, checkout its branch, pull latest, add
the new commits there, and push - this updates the existing PR
instead of creating a duplicate. Only open a new PR when no open PR
already covers this work.
