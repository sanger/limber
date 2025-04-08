# frozen_string_literal: true

namespace :lint do
  desc 'Run Prettier, RuboCop, and ERB Lint in check mode'
  task check: :environment do
    puts 'Running Prettier in check mode...'
    system('yarn prettier --check .')

    puts 'Running RuboCop in check mode...'
    system('bundle exec rubocop')

    puts 'Running ERB Lint in check mode...'
    system('bundle exec erb_lint --lint-all')

    puts 'Lint check complete!'
  end

  desc 'Run Prettier, RuboCop, and ERB Lint in format mode'
  task format: :environment do
    puts 'Running Prettier in format mode...'
    system('yarn prettier --write .')

    puts 'Running RuboCop in auto-correct mode...'
    system('bundle exec rubocop -a')

    puts 'Running ERB Lint in auto-correct mode...'
    system('bundle exec erb_lint -a .')

    puts 'Lint formatting complete!'
  end
end
