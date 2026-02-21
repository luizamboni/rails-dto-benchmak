if Rails.env.development?
  require "rack-mini-profiler"
  require "mini_profiler_rails/railtie"

  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.authorization_mode = :allow_all
  Rack::MiniProfiler.config.pre_authorize_cb = ->(_) { true }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  Rack::MiniProfiler.config.enabled = true
  Rack::MiniProfiler.config.show_children = true
  Rack::MiniProfiler.config.show_trivial = true
  Rack::MiniProfiler.config.show_controls = true
  Rack::MiniProfiler.config.backtrace_threshold_ms = 0
  Rack::MiniProfiler.config.backtrace_includes = [/^\/?app\//, /^\/?lib\//, /^\/?config\//]
  Rack::MiniProfiler.config.enable_advanced_debugging_tools = true

  if defined?(BCrypt::Password) && !BCrypt::Password.respond_to?(:create_without_profiler)
    class << BCrypt::Password
      alias_method :create_without_profiler, :create

      def create(*args, **kwargs, &block)
        Rack::MiniProfiler.step("bcrypt.create") do
          create_without_profiler(*args, **kwargs, &block)
        end
      end
    end
  end
end
