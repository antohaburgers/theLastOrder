# THE LAST ORDER — one-time Roblox publishing setup

The game source is in `antohaburgers/theLastOrder`. Code commits are not
live Roblox releases until a Roblox experience is linked to this repository.

## First Roblox publication (once, on a computer with Roblox Studio)

1. Open [THE LAST ORDER — Build](https://github.com/antohaburgers/theLastOrder/actions/workflows/build.yml) in GitHub Actions; open the latest **successful** build.
2. Download the **TheLastOrder-place** artifact from that run. Extract `TheLastOrder.rbxlx`.
3. In Roblox Studio, use **File → Open from File**, choose that XML place, and run **Play**. Check camera, bots, projectiles and output errors.
4. Use **File → Publish to Roblox** to create THE LAST ORDER as a new experience, or publish the file to its designated existing testing place. Do not point it at the Niva experience.
5. In [Creator Dashboard](https://create.roblox.com/dashboard/creations), copy its **Universe ID**, then obtain its start **Place ID** in the places view.
6. In [this repository's GitHub Actions variables](https://github.com/antohaburgers/theLastOrder/settings/variables/actions), set:
   - `ROBLOX_UNIVERSE_ID`: numeric universe identifier of THE LAST ORDER.
   - `ROBLOX_PLACE_ID`: numeric place identifier of THE LAST ORDER.
7. In [Roblox Creator Dashboard API Keys](https://create.roblox.com/dashboard/credentials?activeTab=ApiKeys), create an API key with universe-places **Write** permission scoped to THE LAST ORDER. Store it under `ROBLOX_API_KEY` in [this repository's GitHub Actions secrets](https://github.com/antohaburgers/theLastOrder/settings/secrets/actions). **Never paste API keys in chat or commit them to source.**
8. Open [THE LAST ORDER — Publish to Roblox](https://github.com/antohaburgers/theLastOrder/actions/workflows/publish.yml) and choose **Run workflow**. The workflow will build then upload the place; review its summary for the confirmed Roblox place version.
9. Restart a fresh Roblox server to verify the new version. A successful API response does not replace Studio/playtesting.

## Automatic publication after setup

In GitHub Actions repository variables, add `ROBLOX_AUTO_PUBLISH=true`
**only after the first manual publish and smoke test succeed**. Then every
successful `main` build automatically deploys the same validated commit.
By default this is OFF, so ordinary code commits build but do not publish.
A single main commit containing `[publish]` can also opt in after setup.
Manual **Run workflow** is available regardless of this variable.

## Troubleshooting / safety

- No place ID or no matching API key: workflow stops before attempting a release.
- HTTP 401/403: check the key's correct experience scope, permissions and IP restrictions.
- HTTP 404: verify universe/place ID pairing.
- The upload endpoint updates **an existing** place; it does not create one.
- Files edited only in Studio may be overwritten by the next Rojo-based upload.
- Roblox public visibility and access permissions are separate from code publishing.
- The workflows do not read or reuse credentials from `nivaRoblox`.

Official reference: https://create.roblox.com/docs/cloud/guides/usage-place-publishing
