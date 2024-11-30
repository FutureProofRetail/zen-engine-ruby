require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = "x86_64-linux"
  spec.files += Dir["vendor/linux_amd64/*"]
end