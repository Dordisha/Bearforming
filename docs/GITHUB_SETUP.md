# GitHub setup

One private repository, Dordisha/bearforming, is sufficient for the native app, core package, tests and docs. No backend is implemented; a second repository would add overhead now.

The connected GitHub tool can commit files to an accessible repository but cannot create a repository. At last check, only Kuvend and Philly Scan were accessible; bearforming returned 404 (absent or inaccessible). No browser login is needed to use the established connection.

## Publish from your Mac

With Git and GitHub CLI installed and authenticated as Dordisha, open Terminal in this extracted Bearforming folder and run:

```sh
bash Scripts/publish-github.sh
```

This creates a PRIVATE repository and pushes this source. It stops if the repo already exists to avoid overwriting it. Git commit identity must already be configured. The script is provided but has not been executed here.

Alternatively create the private repository in GitHub, ensure the ChatGPT GitHub connection includes access to it, and share its link. We can then populate it via that connection.

The included workflow is configured to run persistence tests and an unsigned simulator build on GitHub's macOS runner. It has not run yet. It does not sign, archive, deploy or submit an app.
