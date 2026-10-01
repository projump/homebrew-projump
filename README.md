# Homebrew Tap for Projump

```sh
brew install --cask projump/projump/projump
```

See https://github.com/projump/projump

## Development

Before shipping any change to `Casks/projump.rb`, run from the repository root:

```sh
ruby -c Casks/projump.rb
ruby test/projump_cask_test.rb
git diff --check
```

The tests run offline with Ruby's standard library and minitest (bundled with
Ruby); they need neither Homebrew nor network access. They evaluate the Cask and
check its contract:

- `version` is `X.Y.Z` and the URL is exactly
  `https://github.com/projump/projump/releases/download/v<version>/Projump-<version>.zip`;
- `sha256` is 64 lowercase hexadecimal characters (not `:no_check`, not all zeros);
- the only installed app is `Projump.app`;
- the macOS requirement is `depends_on macos: ">= :sonoma"`.

The expected values live in `test/cask_contract.rb`. They do not check that the
SHA-256 matches the published archive: compute it with
`shasum -a 256 dist/Projump-<version>.zip` when cutting a release.
