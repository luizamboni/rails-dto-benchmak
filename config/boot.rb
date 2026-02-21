ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Ensure Sorbet runtime defaults are configured before any sigs are evaluated.
begin
  require "sorbet-runtime"
  if T::Configuration.respond_to?(:enable_checked_level=)
    T::Configuration.enable_checked_level = :never
  elsif T::Configuration.respond_to?(:default_checked_level=)
    T::Configuration.default_checked_level = :never
  end
rescue LoadError
  # Sorbet runtime not available in this environment.
end
