# Offline reader and contract check for Casks/projump.rb.
#
# Homebrew is not loaded: the Cask file is evaluated against a minimal recorder
# of the DSL stanzas it uses, so the URL is checked as Homebrew would build it
# (with `#{version}` interpolated). Standard library only; Ruby 2.6 compatible.

module CaskContract
  EXPECTED_TOKEN = "projump".freeze
  EXPECTED_URL_TEMPLATE =
    "https://github.com/projump/projump/releases/download/v%{version}/Projump-%{version}.zip".freeze
  EXPECTED_APPS = ["Projump.app"].freeze
  EXPECTED_DEPENDS_ON = { macos: ">= :sonoma" }.freeze

  VERSION_FORMAT = /\A\d+\.\d+\.\d+\z/.freeze
  SHA256_FORMAT = /\A[0-9a-f]{64}\z/.freeze
  PLACEHOLDER_SHA256 = ("0" * 64).freeze

  # Records the stanzas of a `cask "…" do … end` block.
  class Recorder
    attr_reader :token, :sha256_value, :url_value, :names, :desc_value,
                :homepage_value, :depends_on_value, :apps, :zap_value

    def initialize(token)
      @token = token
      @names = []
      @apps = []
      @depends_on_value = {}
    end

    # Without argument, returns the recorded version, like Homebrew, so that
    # `url "…#{version}…"` interpolates it.
    def version(value = nil)
      return @version_value if value.nil?

      @version_value = value
    end

    def sha256(value)
      @sha256_value = value
    end

    def url(value)
      @url_value = value
    end

    def name(value)
      @names << value
    end

    def desc(value)
      @desc_value = value
    end

    def homepage(value)
      @homepage_value = value
    end

    def depends_on(**options)
      @depends_on_value = @depends_on_value.merge(options)
    end

    def app(*values)
      @apps.concat(values)
    end

    def zap(**options)
      @zap_value = options
    end

    def method_missing(stanza, *_args)
      raise NoMethodError,
            "unknown cask stanza `#{stanza}`: extend CaskContract::Recorder in test/cask_contract.rb"
    end

    def respond_to_missing?(_stanza, _include_private = false)
      false
    end
  end

  # Evaluation context of the Cask file: only `cask` is defined.
  class Loader
    attr_reader :casks

    def initialize
      @casks = []
    end

    def cask(token, &block)
      recorder = Recorder.new(token)
      recorder.instance_eval(&block)
      @casks << recorder
    end
  end

  def self.load(source, path = "(cask)")
    loader = Loader.new
    loader.instance_eval(source, path)
    raise ArgumentError, "#{path}: expected exactly one `cask` block, found #{loader.casks.size}" unless loader.casks.size == 1

    loader.casks.first
  end

  def self.load_file(path)
    load(File.read(path), path)
  end

  # Returns the contract violations of a recorded Cask (empty when compliant).
  def self.errors(cask)
    errors = []

    errors << "token must be #{EXPECTED_TOKEN.inspect}, got #{cask.token.inspect}" unless cask.token == EXPECTED_TOKEN

    version = cask.version
    if version.is_a?(String) && version.match?(VERSION_FORMAT)
      expected_url = format(EXPECTED_URL_TEMPLATE, version: version)
      unless cask.url_value == expected_url
        errors << "url must be #{expected_url.inspect} for version #{version}, got #{cask.url_value.inspect}"
      end
    else
      errors << "version must match X.Y.Z, got #{version.inspect}"
    end

    sha256 = cask.sha256_value
    if !sha256.is_a?(String) || !sha256.match?(SHA256_FORMAT)
      errors << "sha256 must be 64 lowercase hexadecimal characters, got #{sha256.inspect}"
    elsif sha256 == PLACEHOLDER_SHA256
      errors << "sha256 must not be the all-zero placeholder"
    end

    errors << "app must be #{EXPECTED_APPS.inspect}, got #{cask.apps.inspect}" unless cask.apps == EXPECTED_APPS

    unless cask.depends_on_value == EXPECTED_DEPENDS_ON
      errors << "depends_on must be #{EXPECTED_DEPENDS_ON.inspect}, got #{cask.depends_on_value.inspect}"
    end

    errors
  end
end
