if Rails.env.development?
  require "rack-mini-profiler"
  require "mini_profiler_rails/railtie"

  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.authorization_mode = :allow_all
  Rack::MiniProfiler.config.pre_authorize_cb = ->(_) { true }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  Rack::MiniProfiler.config.enabled = true
end
