# frozen_string_literal: true

# Routes for tree nodes of the application
class TreeViewerApplication
  path :current_node, '/node'
  path :empty_tree, '/empty_tree'
  path :not_found, '/not_found'
  path :node_parent, '/node/parent'
  path :new_child, '/node/new-child'

  hash_branch('empty_tree') do |_r|
    view('empty_tree')
  end

  hash_branch('node') do |r|
    set_view_subdir('node')
    set_layout_options(template: '../views/layout')

    r.redirect(path(empty_tree_path)) if opts[:store].root.nil?

    r.on Integer do |node_id|
      @current_node = opts[:store].get_node_by_id(node_id)
      r.redirect(path(not_found_path)) if @current_node.nil?

      r.is do
        view('node')
      end

      r.on 'new-child' do
        r.get do
          @parameters = {}
          view('new_child')
        end

        r.post do
          @parameters = DryResultFormeWrapper.new(NodeFormSchema.call(r.params))
          if @parameters.success?
            opts[:store].add_child(@current_node, @parameters)
            r.redirect("/node/#{@current_node.name}")
          else
            view('new_child')
          end
        end
      end

      r.on 'delete' do
        r.get do
          @parameters = {}
          view('node_delete')
        end

        r.post do
          @parameters = DryResultFormeWrapper.new(NodeDeleteSchema.call(r.params))
          if @parameters.success?
            parent = @current_node.parent
            opts[:store].remove_node(@current_node)
            if parent
              r.redirect("/node/#{parent.name}")
            else
              r.redirect('/')
            end
          else
            view('node_delete')
          end
        end
      end
    end

    r.redirect(path(not_found_path))
  end
end
