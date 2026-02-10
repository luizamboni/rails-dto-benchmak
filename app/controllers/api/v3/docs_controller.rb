# typed: true

module Api
  module V3
    class DocsController < Api::V3::ApplicationController
      def show
        render html: swagger_ui.html_safe, content_type: "text/html"
      end

      def spec
        render json: Api::V3::OpenapiBuilder.new.build
      end

      private

      def swagger_ui
        <<~HTML
          <!doctype html>
          <html lang="en">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>Registration API v3 Docs</title>
              <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
              <style>
                body { margin: 0; background: #f5f5f5; }
                #swagger-ui { max-width: 1100px; margin: 0 auto; }
              </style>
            </head>
            <body>
              <div id="swagger-ui"></div>
              <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
              <script>
                window.ui = SwaggerUIBundle({
                  url: "/api/v3/docs.json",
                  dom_id: "#swagger-ui",
                  presets: [SwaggerUIBundle.presets.apis],
                  layout: "BaseLayout"
                });
              </script>
            </body>
          </html>
        HTML
      end

    end
  end
end
