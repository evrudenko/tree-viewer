# frozen_string_literal: true

require 'tree'
require 'json'

# Simplest database analog
class Store
  attr_reader :root

  DATA_STORAGE_FILENAME = File.expand_path('../db/data.json', __dir__)

  def initialize
    read_data
    at_exit { save_data }
  end

  def read_data
    raw_data = File.read(DATA_STORAGE_FILENAME)
    @data = JSON.parse(raw_data, { symbolize_names: true })

    _process_data

    _create_tree(nil, @data[:tree_data])
  end

  def _process_data
    _process_empty_tree_case
    _validate_data
  end

  def _process_empty_tree_case
    return unless @data[:tree_data].empty?

    @data[:max_id] = -1
    @data[:valid] = true
    @root = nil
  end

  def _validate_data
    if @data[:valid]
      @max_id = @data[:max_id]
    else
      @max_id = -1
      _markup_data(@data[:tree_data])

      @data[:valid] = true
      @data[:max_id] = @max_id
    end
  end

  def save_data
    data_json = JSON.pretty_generate(@data)
    File.write(DATA_STORAGE_FILENAME, data_json)
  end

  def _update_data(parent_id, child_node)
    parent = _find_by_id(@data[:tree_data], parent_id)
    child_params = child_node.content.merge({ id: child_node.name.to_i })
    if parent
      if parent[:children]
        parent[:children].push(child_params)
      else
        parent[:children] = [child_params]
      end
    end

    @data[:max_id] = @max_id
  end

  def get_node_by_id(node_id)
    _get_node_by_id(@root, node_id)
  end

  def _get_node_by_id(current_node, node_id)
    return current_node if current_node.name.to_i == node_id

    res = nil
    current_node.children.each do |child|
      res ||= _get_node_by_id(child, node_id)
    end

    res
  end

  def _find_by_id(current, id)
    return current if current[:id] == id

    res = nil
    current[:children]&.each do |child|
      res ||= _find_by_id(child, id)
    end

    res
  end

  def _markup_data(item)
    @max_id += 1
    item[:id] = @max_id

    return unless item[:children].is_a?(Array)

    item[:children].each do |child|
      _markup_data(child)
    end
  end

  def _create_node_from_hash(item)
    Tree::TreeNode.new(
      item[:id].to_s, # key
      item.slice(:title, :description) # value
    )
  end

  def _create_tree(parent, item)
    return if item.nil?

    tree_node = _create_node_from_hash(item)

    if parent
      parent << tree_node # make tree_node a child of parent
    else
      # Child getter overloaded, numeric indexes return ordinal child
      @root = tree_node
    end

    return unless item[:children].is_a?(Array)

    item[:children].each do |child|
      _create_tree(tree_node, child)
    end
  end

  def _create_node(id, params)
    Tree::TreeNode.new(
      id.to_s,
      params.to_h.slice(:title, :description)
    )
  end

  def add_child(parent, child_params)
    child = _create_node(@max_id + 1, child_params)

    parent << child
    @max_id += 1

    _update_data(parent.name.to_i, child)
  end

  def remove_node(node)
    id_for_delete = node.name
    if @root == node
      @data[:tree_data] = {}
      process_empty_tree_case
    else
      parent_item = _find_by_id(@data[:tree_data], node.parent.name.to_i)
      parent_item[:children].reject! { |child_item| child_item[:id] == id_for_delete.to_i }

      node.remove_from_parent!
    end
  end
end
