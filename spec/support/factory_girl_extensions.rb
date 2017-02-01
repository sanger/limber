# frozen_string_literal: true
module FactoryGirl
  class DefinitionProxy
    # Auto generate the necessary attributes for building
    # client api has_many associations. Can take multiple
    # association names
    # Usage:
    # ```
    # with_has_many_associations 'wells', 'comments'
    # ```
    # Generates:
    # ```
    # transient do
    #   wells_count 0
    #   comments_count 0
    # end
    #
    # wells { { "size" => wells_count, "actions" => { "read" => resource_url + '/wells' } } }
    # comments { { "size" => comments_count, "actions" => { "read" => resource_url + '/comments' } } }
    # @param [*String] names 1 or more association names
    # @return [nil] nil
    def with_has_many_associations(*names)
      transient do
        names.each do |association|
          send(association + '_count', 0)
          send(association + '_actions', ['read'])
        end
      end
      names.each do |association|
        send(association) do
          {
            'size' => send(association + '_count'),
            'actions' =>  Hash[send(association + '_actions').map { |action_name| [action_name, resource_url + '/' + association] }]
          }
        end
      end
      nil
    end

    def with_belongs_to_associations(*names)
      transient do
        names.each do |association|
          send(association + '_uuid', "#{association}-uuid")
          send(association + '_actions', ['read'])
        end
      end
      names.each do |association|
        send(association) do
          {
            'actions' =>  Hash[send(association + '_actions').map { |action_name| [action_name, api_root + send(association + '_uuid')] }],
            'uuid'    => send(association + '_uuid')
          }
        end
      end
      nil
    end
  end
end
