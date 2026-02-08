# typed: true

module Api
  module V2
    class ApplicationController < ActionController::Metal
      # Keep minimal stack: JSON rendering + instrumentation + params access.
      include AbstractController::Rendering
      include ActionController::Rendering
      include ActionController::Renderers::All
      include ActionController::Instrumentation
      include ActionController::Head
    end
  end
end
