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
    @data = JSON.parse(raw_data, {:symbolize_names => true})

    if @data[:tree_data].empty?
      @max_id = @data[:max_id] = -1
      @data[:valid] = true
      @root = nil
      return
    end

    if @data[:valid]
      @max_id = @data[:max_id]
      _create_tree(nil, @data[:tree_data])
    else
      @max_id = -1
      _markup_data(@data[:tree_data])

      @data[:valid] = true
      @data[:max_id] = @max_id

      _create_tree(nil, @data[:tree_data])
    end
  end

  def save_data
    data_json = JSON.pretty_generate(@data)
    File.write(DATA_STORAGE_FILENAME, data_json)
  end

  def _update_tree_data(parent_id, child_node)
    parent = _find_by_id(@data[:tree_data], parent_id)
    child = child_node.content.merge({:id => child_node.name.to_i})
    if parent
      if parent[:children]
        parent[:children].push(child)
      else
        parent[:children] = [child]
      end
    end
    pp parent
  end

  def _find_by_id(current, id)
    if current[:id] == id
      return current
    end

    res = nil
    if current[:children]
      current[:children].each do |child|
        res = res || _find_by_id(child, id)
      end
    end

    return res
  end

  def _markup_data(item)
    @max_id += 1
    item[:id] = @max_id

    children = item[:children]
    if children && children.kind_of?(Array)
      children.each do |child|
        _markup_data(child)
      end
    end
  end

  def _create_tree(parent, item)
    tree_node = Tree::TreeNode.new(
      item[:id].to_s, # key
      item.slice(:title, :description) # value
    )

    unless parent
      # Child getter overloaded, numeric indexes return ordinal child
      @root = parent = tree_node
    else
      parent << tree_node # make tree_node a child of parent
    end
    
    children = item[:children]
    if children && children.kind_of?(Array)
      children.each do |child|
        _create_tree(tree_node, child)
      end
    end
  end

  def add_child(parent, child_params)
    child = Tree::TreeNode.new(
      (@max_id + 1).to_s,
      child_params.to_h.slice(:title, :description)
    )
    
    parent << child
    @max_id += 1

    _update_tree_data(parent.name.to_i, child)
  end
end
