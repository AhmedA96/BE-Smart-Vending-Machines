# frozen_string_literal: true

# For more information regarding these settings check out our docs https://docs.avohq.io
# The values disaplayed here are the default ones. Uncomment and change them to fit your needs.
Avo.configure do |config|
  ## == Routing ==
  config.root_path = '/admin'
  # used only when you have custom `map` configuration in your config.ru
  # config.prefix_path = "/internal"

  # Where should the user be redirected when visiting the `/avo` url

  ## == Licensing ==
  # config.license_key = ENV['AVO_LICENSE_KEY']
  config.click_row_to_view_record = true
  config.alert_dismiss_time = 5000 # 5 seconds
  config.associations_lookup_list_limit = 500

  ## == Set the context ==
  config.set_context do
    # Return a context object that gets evaluated within Avo::ApplicationController
  end

  ## == Authentication ==
  config.current_user_method = :current_user
  config.authenticate_with do
    if current_user&.admin?
      current_user
    else
      sign_out(:user)
      redirect_to main_app.new_user_session_path
      throw :abort
    end
  end

  ## == Authorization ==
  # config.is_admin_method = :is_admin
  # config.is_developer_method = :is_developer
  config.authorization_methods = {
    index: 'index?',
    show: 'show?',
    edit: 'edit?',
    new: 'new?',
    update: 'update?',
    create: 'create?',
    destroy: 'destroy?',
    search: 'search?'
  }
  # config.raise_error_on_missing_policy = false
  config.authorization_client = :pundit
  # config.explicit_authorization = true

  ## == Localization ==
  config.locale = :en

  ## == Resource options ==
  config.resource_row_controls_config = {
    placement: :right,
    float: false,
    show_on_hover: false
  }

  # config.model_resource_mapping = {}
  #
  config.default_view_type = :table
  config.per_page = 24
  config.per_page_steps = [12, 24, 48, 72]
  config.via_per_page = 8
  # config.id_links_to_resource = false
  # config.pagination = -> do
  #   {
  #     type: :default,
  #     size: 9, # `[1, 2, 2, 1]` for pagy < 9.0
  #   }
  # end

  ## == Response messages dismiss time ==
  # config.alert_dismiss_time = 5000

  ## == Number of search results to display ==
  # config.search_results_count = 8

  ## == Associations lookup list limit ==
  # config.associations_lookup_list_limit = 1000

  ## == Cache options ==
  ## Provide a lambda to customize the cache store used by Avo.
  ## We compute the cache store by default, this is NOT the default, just an example.
  # config.cache_store = -> {
  #   ActiveSupport::Cache.lookup_store(:solid_cache_store)
  # }
  # config.cache_resources_on_index_view = true

  ## == Turbo options ==
  # config.turbo = -> do
  #   {
  #     instant_click: true
  #   }
  # end

  ## == Logger ==
  # config.logger = -> {
  #   file_logger = ActiveSupport::Logger.new(Rails.root.join("log", "avo.log"))
  #
  #   file_logger.datetime_format = "%Y-%m-%d %H:%M:%S"
  #   file_logger.formatter = proc do |severity, time, progname, msg|
  #     "[Avo] #{time}: #{msg}\n".tap do |i|
  #       puts i
  #     end
  #   end
  #
  #   file_logger
  # }

  ## == Customization ==
  config.click_row_to_view_record = true
  config.app_name = ''
  # config.timezone = 'UTC'
  # config.currency = 'USD'
  # config.hide_layout_when_printing = false
  # config.full_width_container = false
  # config.full_width_index_view = false
  # config.search_debounce = 300
  # config.view_component_path = "app/components"
  # config.display_license_request_timeout_error = true
  config.disabled_features = [:global_search]
  config.buttons_on_form_footers = true
  # config.field_wrapper_layout = true
  # config.resource_parent_controller = "Avo::ResourcesController"
  # config.first_sorting_option = :desc # :desc or :asc
  # config.exclude_from_status = []

  ## == Branding ==
  config.branding = {
    colors: {
      background: '248 246 242',
      100 => '#CEE7F8',
      400 => '#399EE5',
      500 => '#0886DE',
      600 => '#066BB2'
    },
    chart_colors: ['#0B8AE2', '#34C683', '#2AB1EE', '#34C6A8'],
    logo: '/avo-assets/logo.png',
    logomark: '/avo-assets/logomark.png',
    placeholder: '/avo-assets/placeholder.svg',
    favicon: '/avo-assets/favicon.ico'
  }

  config.turbo = lambda {
    {
      instant_click: true
    }
  }
  ## == Breadcrumbs ==
  # config.display_breadcrumbs = true
  # config.set_initial_breadcrumbs do
  #   add_breadcrumb "Home", '/avo'
  # end

  config.main_menu = lambda {
    # Machines & Operations Section
    section I18n.t('avo.sections.machines_operations'), icon: 'heroicons/outline/cog', collapsable: true,
                                                        collapsed: true do
      resource :machine
      resource :machine_status
      resource :machine_category
      resource :machine_payment_method
    end

    # Shop & Inventory Section
    section I18n.t('avo.sections.shop_inventory'), icon: 'heroicons/outline/shopping-cart', collapsable: true,
                                                   collapsed: true do
      group I18n.t('avo.groups.products'), collapsable: true, collapsed: true do
        resource :product
        resource :variant
        resource :category
        resource :brand
      end

      group I18n.t('avo.groups.pricing'), collapsable: true, collapsed: true do
        resource :price_list
        resource :price_list_item
        resource :line_item
      end
    end

    # Settings Section
    section I18n.t('avo.sections.settings'), icon: 'heroicons/outline/cog-6-tooth', collapsable: true,
                                             collapsed: true do
      group I18n.t('avo.groups.location_management'), collapsable: true, collapsed: true do
        resource :location
      end

      group I18n.t('avo.groups.access_control'), collapsable: true, collapsed: true do
        resource :role
      end

      group I18n.t('avo.groups.payments'), collapsable: true, collapsed: true do
        resource :payment
      end
    end
  }
end
