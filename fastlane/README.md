fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build a signed IPA and upload it to TestFlight

### ios listing

```sh
[bundle exec] fastlane ios listing
```

Upload App Store metadata and screenshots without submitting

### ios release

```sh
[bundle exec] fastlane ios release
```

Build, upload, attach to the App Store version, and submit for review

----


## Android

### android internal

```sh
[bundle exec] fastlane android internal
```

Build a signed AAB and upload a draft to the internal track (binary only)

### android listing

```sh
[bundle exec] fastlane android listing
```

Upload Play listing text and images without a binary

### android ship

```sh
[bundle exec] fastlane android ship
```

Listing + images, then a signed AAB draft to internal

### android production

```sh
[bundle exec] fastlane android production
```

Signed AAB to production and send for review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
