require_relative "lib/zen-engine-ruby/version"

module GemspecHelper
  def self.shared_specs
    Proc.new do |spec|
      spec.name = "zen-engine-ruby"
      spec.version = ZenRuby::VERSION
      spec.authors = ["Alex Matchneer"]
      spec.email = ["amatchneer@futureproofretail.com"]
    
      spec.summary = "Ruby bindings for GoRules ZEN engine"
      spec.description = "Ruby FFI bindings for the Zen library"
      spec.homepage = "https://github.com/FutureProofRetail/zen-engine-ruby"
      spec.license = "MIT"
    
      spec.required_ruby_version = ">= 3.0.0"
    
      spec.files = Dir["lib/**/*", "README.md", "LICENSE"]
      
      spec.add_dependency "ffi", "~> 1.17"
      
      spec.add_development_dependency "minitest", "~> 5.25"
    end
  end
end 