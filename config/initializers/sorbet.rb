# Disable Sorbet runtime checks; keep signatures for documentation.
if T::Configuration.respond_to?(:enable_checked_level=)
  T::Configuration.enable_checked_level = :never
elsif T::Configuration.respond_to?(:default_checked_level=)
  T::Configuration.default_checked_level = :never
end
