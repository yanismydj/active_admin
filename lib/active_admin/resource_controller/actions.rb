module ActiveAdmin
  class ResourceController < BaseController

    # Override the InheritedResources actions to use the
    # Active Admin templates.
    #
    # We ensure that the functionality provided by Inherited
    # Resources is still available within any ResourceController

    def index(options={}, &block)
      super(options) do |format|
        block.call(format) if block
        format.html { render active_admin_template('index') }
        format.csv do
          headers['Content-Type'] = 'text/csv; charset=utf-8'
          headers['Content-Disposition'] = %{attachment; filename="#{csv_filename}"}
          render active_admin_template('index')
        end
      end
    end
    alias :index! :index

    def show(options={}, &block)
      super do |format|
        block.call(format) if block
        format.html { render active_admin_template('show') }
      end
    end
    alias :show! :show

    def new(options={}, &block)
      super do |format|
        block.call(format) if block
        format.html { render active_admin_template('new') }
      end
    end
    alias :new! :new

    def edit(options={}, &block)
      super do |format|
        block.call(format) if block
        format.html { render active_admin_template('edit') }
      end
    end
    alias :edit! :edit

    def create(options={}, &block)
      super(options) do |success, failure|
        block.call(success, failure) if block
        failure.html { render active_admin_template('new') }
      end
    end
    alias :create! :create

    def update(options={}, &block)
      super do |success, failure|
        block.call(success, failure) if block
        failure.html { render active_admin_template('edit') }
      end
    end
    alias :update! :update

    # Make aliases protected
    protected :index!, :show!, :new!, :create!, :edit!, :update!

    protected
    
    # Returns the association chain, with all parents (does not include the
    # current resource).
    #
    def association_chain
      @association_chain ||=
        symbols_for_association_chain.inject([begin_of_association_chain]) do |chain, symbol|
          chain << evaluate_my_parent(symbol, resources_configuration[symbol], chain.last)
        end.compact.freeze
    end
    
    def evaluate_my_parent(parent_symbol, parent_config, chain = nil) #:nodoc:
      instantiated_object = instance_variable_get("@#{parent_config[:instance_name]}")
      return instantiated_object if instantiated_object
      parent = nil
      parent = if chain
        chain.send(parent_config[:collection_name])
      else
        parent_config[:parent_class]
      end
      
      if params[:cluster].present?
        parent = parent.where(:id => params[parent_config[:param]]).on_db(params[:cluster]).first
      else
        parent = parent.where(:id => params[parent_config[:param]]).first
      end

      instance_variable_set("@#{parent_config[:instance_name]}", parent)
    end

    def resource
      if get_resource_ivar
        get_resource_ivar
      else
        if params[:cluster].present?
          set_resource_ivar(end_of_association_chain.send(:where, {:id => params[:id]}).on_db(params[:cluster]).first)
        else
          set_resource_ivar(end_of_association_chain.send(:where, {:id => params[:id]}).first)
        end
      end
    end
    # Returns the full location to the Active Admin template path
    def active_admin_template(template)
      "active_admin/resource/#{template}"
    end

    # Returns a filename for the csv file using the collection_name
    # and current date such as 'my-articles-2011-06-24.csv'.
    def csv_filename
      "#{resource_collection_name.to_s.gsub('_', '-')}-#{Time.now.strftime("%Y-%m-%d")}.csv"
    end
  end
end
