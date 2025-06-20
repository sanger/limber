# frozen_string_literal: true

# The production configuration is set in the Deployment project and not here.
# See roles/deploy_limber/templates/environment_template.rb.j2 for the actual production configuration.

# The configuration below is required by the build workflow to pass the workflows.
# They will not be used in production.
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Label printing services
  config.pmb_uri = ENV.fetch('PMB_URI', 'http://localhost:3002/v1/')
  # config.sprint_uri = 'http://sprint.psd.sanger.ac.uk/graphql' # copied from development.rb
end
