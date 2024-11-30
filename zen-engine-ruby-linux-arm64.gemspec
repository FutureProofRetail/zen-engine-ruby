require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = "aarch64-linux"
  spec.files += Dir["vendor/linux_arm64/*"]
end