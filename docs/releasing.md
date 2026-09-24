# Publish `@vidot/vitest`

The [CI workflow](../.github/workflows/ci.yml) runs the repository checks on pull requests and changes to `main`.
The [npm workflow](../.github/workflows/npm-publish.yml) runs the same checks for each `v*` tag.
It publishes the package when npm does not have the tagged version.

## First release

The first release needs a manual npm publish. npm lets you add a trusted publisher after the package exists.
An npm account with publish access to the `@vidot` scope must do this step.

1. Merge the release changes into `main` and wait for CI to pass.
2. Check out that commit in a clean working tree.
3. Install the pinned tools and dependencies:

   ```sh
   mise install
   mise run setup
   ```

4. Run the checks and examine the package contents:

   ```sh
   mise run check
   mise x -- npm pack --dry-run
   ```

5. Make sure that the npm account can publish packages in the `@vidot` scope.
6. Publish version `0.1.0` from the repository root:

   ```sh
   mise x -- npm login
   mise x -- npm publish
   ```

7. Add a GitHub Actions trusted publisher for `@vidot/vitest`:

   ```sh
   mise x -- npm trust github @vidot/vitest --repo LemonNekoGH/vidot --file npm-publish.yml --allow-publish
   ```

   If you use the npm website, enter these exact values:

   | Field | Value |
   | --- | --- |
   | Organization or user | `LemonNekoGH` |
   | Repository | `vidot` |
   | Workflow filename | `npm-publish.yml` |
   | Environment name | Leave empty |
   | Allowed action | `npm publish` |

8. Tag the same commit and push the tag:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   ```

The tag workflow runs its checks and skips the npm upload because version `0.1.0` already exists.

## Later releases

1. Update `package.json` with the next version.
2. Run `mise run check` and `mise x -- npm pack --dry-run`.
3. Merge the version change into `main` and wait for CI to pass.
4. Tag the release commit and push the tag. For version `0.1.1`, run:

   ```sh
   git tag v0.1.1
   git push origin v0.1.1
   ```

The tag must match the version in `package.json`. It must point to a commit on `main`.
Protect release tags in the GitHub repository settings so only maintainers can create them.
