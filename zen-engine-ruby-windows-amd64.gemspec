require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = Gem::Platform.new(["amd64", "windows"])
  spec.files += Dir["vendor/windows_amd64/*"]
end