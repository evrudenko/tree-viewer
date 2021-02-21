# frozen_string_literal: true

require 'tree'

# Simplest database analog
class Store
  attr_reader :root

  DATA_STORAGE_FILENAME = File.expand_path('../db/data.json', __dir__)

  def initialize
    read_data
    at_exit { write_data }
  end

  def read_data; end

  def write_data; end
end
