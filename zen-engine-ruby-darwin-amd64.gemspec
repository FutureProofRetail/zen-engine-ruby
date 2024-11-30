require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = Gem::Platform.new(["amd64", "darwin"])
  spec.files += Dir["vendor/darwin_amd64/*"]
end