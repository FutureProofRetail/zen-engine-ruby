require_relative "gemspec_helper"

Gem::Specification.new do |spec|
  GemspecHelper.shared_specs.call(spec)
  spec.platform = "x64-mingw32"
  spec.files += Dir["vendor/windows_amd64/*"]
end