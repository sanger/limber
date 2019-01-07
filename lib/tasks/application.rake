# frozen_string_literal: true

namespace :application do
  task deploy: ['config:generate']
end
