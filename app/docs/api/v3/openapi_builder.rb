# typed: true

module Api
  module V3
    class OpenapiBuilder
      def build
        {
          openapi: "3.0.3",
          info: {
            title: "Registration API v3",
            version: "v3",
          },
          servers: [
            { url: "/api/v3" },
          ],
          paths: generate_paths,
        }
      end

      private

      def generate_paths
        routes = Rails.application.routes.routes
        v3_routes = routes.map { |r| route_info(r) }.compact.select { |r| r[:path].start_with?("/api/v3") }
        v3_routes.each_with_object({}) do |route, acc|
          controller = controller_class(route[:controller])
          next unless controller && controller.respond_to?(:contracts)

          action = route[:action].to_sym
          next unless controller.contracts.key?(action)

          path = route[:path].sub("/api/v3", "")
          acc[path] ||= {}
          route[:verbs].each do |verb|
            acc[path][verb.downcase.to_sym] =
              build_action_schema(controller, action, summary: route[:summary], operation_id: route[:operation_id])
          end
        end
      end

      def route_info(route)
        verb_raw = route.verb
        verb = if verb_raw.respond_to?(:source)
          verb_raw.source
        else
          verb_raw.to_s
        end
        verb = verb.gsub("$", "")
        return nil if verb.empty?
        verbs = verb.split("|").reject { |v| v == "HEAD" || v == "OPTIONS" }
        return nil if verbs.empty?

        {
          verbs: verbs,
          path: route.path.spec.to_s.gsub("(.:format)", ""),
          controller: route.defaults[:controller],
          action: route.defaults[:action],
          summary: "#{route.defaults[:controller]}##{route.defaults[:action]}",
          operation_id: "#{route.defaults[:controller].tr('/', '_')}_#{route.defaults[:action]}",
        }
      end

      def controller_class(name)
        return nil unless name

        "#{name.camelize}Controller".safe_constantize
      end

      def build_action_schema(controller, action, summary:, operation_id:)
        contract = controller.contracts.fetch(action)
        {
          summary: summary,
          operationId: operation_id,
          requestBody: build_request_body(contract[:body]),
          responses: build_responses(contract[:responds]),
        }
      end

      def build_request_body(dto)
        return nil unless dto

        {
          required: true,
          content: {
            "application/json" => {
              schema: dto_schema(dto),
            },
          },
        }
      end

      def build_responses(responds)
        return {} unless responds

        responds.each_with_object({}) do |(status, dto), acc|
          code = status_code(status)
          description = status.to_s.tr("_", " ").capitalize

          if dto.nil?
            acc[code] = { description: description }
            next
          end

          acc[code] = {
            description: description,
            content: {
              "application/json" => {
                schema: dto_schema(dto),
              },
            },
          }
        end
      end

      def status_code(status)
        {
          ok: "200",
          created: "201",
          bad_request: "400",
          unprocessable_entity: "422",
        }.fetch(status) { "200" }
      end

      def dto_schema(dto)
        meta = dto.fields_meta
        {
          type: "object",
          required: meta.select { |_, v| v[:required] }.keys.map(&:to_s),
          properties: meta.transform_values { |v| map_type(v[:type]) },
        }
      end

      def map_type(type)
        case type.name
        when "String"
          { type: "string" }
        when "Integer"
          { type: "integer" }
        when "Float"
          { type: "number" }
        when "Array"
          { type: "array", items: { type: "string" } }
        when "Hash"
          { type: "object" }
        else
          { type: "string" }
        end
      end
    end
  end
end
