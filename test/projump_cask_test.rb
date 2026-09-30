# Offline contract tests for Casks/projump.rb.
#
#   ruby test/projump_cask_test.rb

require "minitest/autorun"
require_relative "cask_contract"

class ProjumpCaskTest < Minitest::Test
  CASK_PATH = File.expand_path("../Casks/projump.rb", __dir__)
  SOURCE = File.read(CASK_PATH).freeze

  def test_current_cask_satisfies_contract
    assert_empty CaskContract.errors(CaskContract.load_file(CASK_PATH))
  end

  def test_current_cask_url_uses_its_version
    cask = CaskContract.load_file(CASK_PATH)

    assert_match CaskContract::VERSION_FORMAT, cask.version
    assert_equal "https://github.com/projump/projump/releases/download/v#{cask.version}/Projump-#{cask.version}.zip",
                 cask.url_value
    assert_equal ["Projump.app"], cask.apps
    assert_equal({ macos: ">= :sonoma" }, cask.depends_on_value)
  end

  def test_rejects_url_pinned_to_an_older_version
    assert_violation(%r{url "[^"]+"}, 'url "https://github.com/projump/projump/releases/download/v0.1.0/Projump-0.1.0.zip"',
                     /url must be .*v#{Regexp.escape(current_version)}/)
  end

  def test_rejects_version_bumped_without_url
    source = replace(SOURCE, /url "[^"]+"/, "url \"https://github.com/projump/projump/releases/download/v#{current_version}/Projump-#{current_version}.zip\"")
    source = replace(source, /version "[^"]+"/, 'version "9.9.9"')

    assert_includes_error source, /url must be .*v9\.9\.9/
  end

  def test_rejects_wrong_repository
    assert_violation("projump/projump/releases", "projump/other/releases", /url must be/)
  end

  def test_rejects_wrong_archive_name
    assert_violation("/Projump-\#{version}.zip", "/Projump-\#{version}.dmg", /url must be/)
    assert_violation("/Projump-\#{version}.zip", "/Projump-v\#{version}.zip", /url must be/)
  end

  def test_rejects_malformed_sha256
    sha256 = current_sha256

    assert_violation(sha256, sha256[0, 63], /sha256 must be 64 lowercase hexadecimal/)
    assert_violation(sha256, "g#{sha256[1..-1]}", /sha256 must be 64 lowercase hexadecimal/)
    assert_violation(sha256, sha256.upcase, /sha256 must be 64 lowercase hexadecimal/)
  end

  def test_rejects_unchecked_sha256
    assert_violation(/sha256 "[^"]+"/, "sha256 :no_check", /sha256 must be 64 lowercase hexadecimal/)
  end

  def test_rejects_placeholder_sha256
    assert_violation(current_sha256, "0" * 64, /all-zero placeholder/)
  end

  def test_rejects_renamed_app
    assert_violation('app "Projump.app"', 'app "Other.app"', /app must be/)
  end

  def test_rejects_missing_app
    assert_violation(/^\s*app "Projump.app"\n/, "", /app must be .*got \[\]/)
  end

  def test_rejects_extra_app
    assert_violation('app "Projump.app"', "app \"Projump.app\"\n  app \"Other.app\"", /app must be/)
  end

  def test_rejects_changed_macos_requirement
    assert_violation('">= :sonoma"', '">= :ventura"', /depends_on must be/)
  end

  def test_rejects_missing_macos_requirement
    assert_violation(/^\s*depends_on macos: .*\n/, "", /depends_on must be .*got \{\}/)
  end

  def test_rejects_version_not_in_x_y_z_form
    assert_violation(/version "[^"]+"/, 'version "0.1"', /version must match X\.Y\.Z/)
    assert_violation(/version "[^"]+"/, 'version "latest"', /version must match X\.Y\.Z/)
  end

  def test_rejects_wrong_token
    assert_violation('cask "projump"', 'cask "other"', /token must be "projump"/)
  end

  def test_unknown_stanza_fails_loudly
    source = replace(SOURCE, 'app "Projump.app"', "app \"Projump.app\"\n  pkg \"Projump.pkg\"")

    error = assert_raises(NoMethodError) { CaskContract.load(source) }
    assert_match(/unknown cask stanza `pkg`/, error.message)
  end

  private

  def current_version
    SOURCE[/version "([^"]+)"/, 1]
  end

  def current_sha256
    SOURCE[/sha256 "([^"]+)"/, 1]
  end

  # Substitutes in the Cask text and fails if nothing changed, so that a test
  # cannot silently check the unmodified Cask.
  def replace(source, pattern, replacement)
    changed = source.sub(pattern) { replacement }
    refute_equal source, changed, "pattern #{pattern.inspect} did not change the Cask"
    changed
  end

  def assert_violation(pattern, replacement, expected_error)
    assert_includes_error replace(SOURCE, pattern, replacement), expected_error
  end

  def assert_includes_error(source, expected_error)
    errors = CaskContract.errors(CaskContract.load(source))
    assert errors.any? { |message| message.match?(expected_error) },
           "expected an error matching #{expected_error.inspect}, got #{errors.inspect}"
  end
end
