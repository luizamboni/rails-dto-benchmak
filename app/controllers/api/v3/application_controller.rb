# typed: true

module Api
  module V3
    class StrictDTO
      class Error < StandardError; end
      class TypeError < Error; end
      class UnknownFieldError < Error; end

      def self.field(name, type, required: true)
        @fields ||= {}
        @fields[name] = { type: type, required: required }
        attr_reader name
      end

      def self.fields
        @fields || {}
      end

      def self.fields_meta
        @fields || {}
      end

      def initialize(attrs)
        attrs = (attrs || {}).to_h
        attrs = attrs.transform_keys(&:to_sym)
        unknown = attrs.keys - self.class.fields.keys
        raise UnknownFieldError, unknown.join(", ") if unknown.any?

        self.class.fields.each do |name, meta|
          value = attrs[name]

          if value.nil?
            raise TypeError, "#{name} is required" if meta[:required]
            next
          end

          unless value.is_a?(meta[:type])
            raise TypeError, "#{name} must be #{meta[:type]}"
          end

          instance_variable_set("@#{name}", value)
        end
      end

      def to_h
        self.class.fields.keys.index_with { |k| instance_variable_get("@#{k}") }
      end
    end

    class ApplicationController < ActionController::Metal
      # Keep minimal stack: JSON rendering + instrumentation + head responses.
      include AbstractController::Rendering
      include ActionController::Rendering
      include ActionController::Renderers::All
      include ActionController::Instrumentation
      include ActionController::Logging
      include ActionController::StrongParameters
      include ActionController::Head

      def self.contract(path: nil, query: nil, body: nil, responds: nil)
        normalized_responds = responds&.each_with_object({}) do |(key, dto), acc|
          Array(key).each { |status| acc[status] = dto }
        end
        @__next_contract__ = { path: path, query: query, body: body, responds: normalized_responds }
      end

      def self.method_added(name)
        return unless @__next_contract__

        contracts[name] = @__next_contract__
        @__next_contract__ = nil
      end

      def self.contracts
        @contracts ||= {}
      end

      private

      def resolve_path!
        dto = self.class.contracts[action_name.to_sym][:path]
        return unless dto

        params = request.path_parameters
        dto.new(slice_dto_params(dto, params))
      end

      def resolve_query!
        dto = self.class.contracts[action_name.to_sym][:query]
        return unless dto

        params = request.query_parameters
        dto.new(slice_dto_params(dto, params))
      end

      def resolve_body!
        dto = self.class.contracts[action_name.to_sym][:body]
        return unless dto

        body = request.request_parameters
        body = body.to_unsafe_h if body.respond_to?(:to_unsafe_h)
        dto.new(body)
      end

      def slice_dto_params(dto, params)
        params = (params || {}).to_h
        params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
        allowed = dto.fields.keys.map(&:to_sym)
        params.transform_keys(&:to_sym).slice(*allowed)
      end

      def responds_for_status(status, params)
        dto = self.class.contracts[action_name.to_sym][:responds][status]
        payload = dto ? dto.new(params).to_h : params
        render json: payload, status: status
      end
    end
  end
end
