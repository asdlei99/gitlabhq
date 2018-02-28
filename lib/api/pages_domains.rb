module API
  class PagesDomains < Grape::API
    include PaginationParams

    before do
      authenticate!
      require_pages_enabled!
    end

    after_validation do
      normalize_params_file_to_string
    end

    helpers do
      def find_pages_domain!
        user_project.pages_domains.find_by(domain: params[:domain]) || not_found!('PagesDomain')
      end

      def pages_domain
        @pages_domain ||= find_pages_domain!
      end

      def normalize_params_file_to_string
        params.each do |k, v|
          if v.is_a?(Hash) && v.key?(:tempfile)
            params[k] = v[:tempfile].to_a.join('')
          end
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get all pages domains' do
        success Entities::PagesDomain
      end
      params do
        use :pagination
      end
      get ":id/pages/domains" do
        authorize! :read_pages, user_project

        present paginate(user_project.pages_domains.order(:domain)), with: Entities::PagesDomain
      end

      desc 'Get a single pages domain' do
        success Entities::PagesDomain
      end
      params do
        requires :domain, type: String, desc: 'The domain'
      end
      get ":id/pages/domains/:domain", requirements: { domain: %r{[^/]+} } do
        authorize! :read_pages, user_project

        present pages_domain, with: Entities::PagesDomain
      end

      desc 'Create a new pages domain' do
        success Entities::PagesDomain
      end
      params do
        requires :domain, type: String, desc: 'The domain'
        optional :certificate, allow_blank: false, types: [File, String], desc: 'The certificate'
        optional :key, allow_blank: false, types: [File, String], desc: 'The key'
        all_or_none_of :certificate, :key
      end
      post ":id/pages/domains" do
        authorize! :update_pages, user_project

        pages_domain_params = declared(params, include_parent_namespaces: false)
        pages_domain = user_project.pages_domains.create(pages_domain_params)

        if pages_domain.persisted?
          present pages_domain, with: Entities::PagesDomain
        else
          render_validation_error!(pages_domain)
        end
      end

      desc 'Updates a pages domain'
      params do
        requires :domain, type: String, desc: 'The domain'
        optional :certificate, allow_blank: false, types: [File, String], desc: 'The certificate'
        optional :key, allow_blank: false, types: [File, String], desc: 'The key'
      end
      put ":id/pages/domains/:domain", requirements: { domain: %r{[^/]+} } do
        authorize! :update_pages, user_project

        pages_domain_params = declared(params, include_parent_namespaces: false)

        # Remove empty private key if certificate is not empty.
        if pages_domain_params[:certificate] && !pages_domain_params[:key]
          pages_domain_params.delete(:key)
        end

        if pages_domain.update(pages_domain_params)
          present pages_domain, with: Entities::PagesDomain
        else
          render_validation_error!(pages_domain)
        end
      end

      desc 'Delete a pages domain'
      params do
        requires :domain, type: String, desc: 'The domain'
      end
      delete ":id/pages/domains/:domain", requirements: { domain: %r{[^/]+} } do
        authorize! :update_pages, user_project

        status 204
        pages_domain.destroy
      end
    end
  end
end
