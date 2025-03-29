# Void Builder

This is a fork of VSCodium, which has a nice build pipeline that we're using for Void.

Big thanks to the CodeStory team for inspiring this.

## What it does

This repo has GitHub Actions that build Void assets (.dmg, .zip, etc) into the `voideditor/binaries` repo and update the `voideditor/versions` repo so the versions can be tracked for updating.

See `stable-macos.sh` for one of the main actions with some comments added by the Void team.

Actions like `stable-macos.sh` run when we manually run them (this might change in the future and be listener-based).

## Updating

VSCodium comes with `.patch` files that we manually applied to the void/ repo, including relevant ones to updating. See the `.patch` files for more info. Also see `abstractUpdateService.ts` in `void`, and look for "updateUrl" and "downloadUrl" in `void-builder`.

