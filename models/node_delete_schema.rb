# frozen_string_literal: true

require 'dry-schema'

NodeDeleteSchema = Dry::Schema.Params do
  required(:confirmation).filled(true)
end
