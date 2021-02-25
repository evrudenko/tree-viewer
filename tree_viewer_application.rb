# frozen_string_literal: true

require 'roda'
require 'forme'

require_relative 'models'

# Application class
class TreeViewerApplication < Roda
  opts[:root] = __dir__
  plugin :environments
  plugin :forme
  plugin :hash_routes
  plugin :path
  plugin :render
  plugin :status_handler
  plugin :view_options

  configure :development do
    plugin :public
    opts[:serve_static] = true
  end

  require_relative 'routes/tree'

  opts[:store] = Store.new
  opts[:current_node] = opts[:store].root

  status_handler(404) do
    view('not_found')
  end

  route do |r|
    r.public if opts[:serve_static]
    r.hash_branches

    r.root do
      r.redirect('/node/0')
    end
  end
end
