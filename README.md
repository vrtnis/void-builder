# Void Builder

This is a fork of VSCodium, which has a nice build pipeline that we're using for Void.

Big thanks to the CodeStory team for inspiring this.

The purpose of this repo is to run [Github Actions](https://github.com/voideditor/void-builder/actions).

These actions build all the Void assets (.dmg, .zip, etc), and then they store them on a release in the [`voideditor/binaries`](https://github.com/voideditor/binaries/releases) repo, and then they set the latest version in the [`voideditor/versions`](https://github.com/voideditor/versions) repo so the versions can be tracked for updating in the Desktop app.

## Notes

See `stable-macos.sh` for one of the main Actions with some comments added by the Void team.

VSCodium comes with `.patch` files, including relevant ones to auto-updating, which are being applied automatically. 

For a list of all the places Void edited in this repo, search "Void" and "voideditor".
