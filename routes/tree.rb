# frozen_string_literal: true

# Routes for tree nodes of the application
class TreeViewerApplication
  path :current_node, '/node'
  path :empty_tree, '/empty_tree'
  path :not_found, '/not_found'
  path :node_parent, '/node/parent'

  hash_branch('empty_tree') do |r|
    view('empty_tree')
  end

  hash_branch('node') do |r|
    set_view_subdir('node')
    set_layout_options(template: '../views/layout')

    @current_node = opts[:current_node]
    next r.redirect(path(empty_tree_path)) if @current_node.nil?

    r.is do
      view('node')
    end

    r.on 'parent' do
      parent = @current_node.parent
      next r.redirect(path(not_found_path)) if parent.nil?

      opts[:current_node] = parent
      r.redirect(current_node_path)
    end

    r.on 'child', Integer do |node_id|
      # Child getter overloaded, numeric indexes return ordinal child
      child = @current_node.children.find {|child| child.name == node_id.to_s}
      next r.redirect(path(not_found_path)) if child.nil?

      opts[:current_node] = child
      r.redirect(current_node_path)
    end

    r.redirect(not_found_path)
  end
end
