# frozen_string_literal: true

require 'dry-schema'

require_relative 'schema_types'

NodeFormSchema = Dry::Schema.Params do
  required(:title).filled(SchemaTypes::StrippedString)
  required(:description).maybe(SchemaTypes::StrippedString)
end
