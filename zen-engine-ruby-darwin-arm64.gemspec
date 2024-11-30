require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = "aarch64-darwin"
  spec.files += Dir["vendor/darwin_arm64/*"]
end