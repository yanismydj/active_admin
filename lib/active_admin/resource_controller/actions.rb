module ActiveAdmin
  class ResourceController < BaseController

    # Override the InheritedResources actions to use the
    # Active Admin templates.
    #
    # We ensure that the functionality provided by Inherited
    # Resources is still available within any ResourceController
    around_filter :set_connection

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
    
    def set_connection
      if params[:cluster].present?
        SectorRecord.on_cluster(params[:cluster]) do
          yield
        end
      else
        yield
      end
    end
    
    def build_resource
      if get_resource_ivar
        get_resource_ivar
      else
        if type = resource_params[0]['type']
          base_ivar = end_of_association_chain.send(method_for_build, *resource_params)
          new_ivar = type.constantize.new(base_ivar.attributes)
          set_resource_ivar(new_ivar)
        else
          set_resource_ivar(end_of_association_chain.send(method_for_build, *resource_params))
        end
      end
    end
    
    # URL to redirect to when redirect implies resource url.
    def smart_resource_url
      url = nil
      if respond_to? :show
        url = resource_url rescue nil
      end
      url ||= smart_collection_url
      if params[:cluster].present?
        url += "?cluster=#{params[:cluster]}"
      end
      url
    end

    # URL to redirect to when redirect implies collection url.
    def smart_collection_url
      url = nil
      if respond_to? :index
        url ||= collection_url rescue nil
      end
      if respond_to? :parent
        url ||= parent_url rescue nil
      end
      url ||= root_url rescue nil
      if params[:cluster].present?
        url += "?cluster=#{params[:cluster]}"
      end
      url
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
