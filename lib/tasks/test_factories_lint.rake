# frozen_string_literal: true

namespace :test do
  namespace :factories do
    desc 'Lint the factories'
    task lint: :environment do
      FactoryBot.find_definitions

      puts 'Linting factories...'
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        FactoryBot.lint verbose: ENV['VERBOSE'].present?
      rescue FactoryBot::InvalidFactoryError => e
        puts e.message
        exit 1
      end

      complete = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      puts "Done in #{complete - starting}"
    end
  end
end
