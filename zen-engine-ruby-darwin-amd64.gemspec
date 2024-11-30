require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = "x86_64-darwin"
  spec.files += Dir["vendor/darwin_amd64/*"]
end