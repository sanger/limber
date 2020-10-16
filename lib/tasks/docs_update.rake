namespace :docs do
  desc 'Update the documentation for presenters, state changers and creators'
  task update: :environment do

    used_presenter = Hash.new { |h,i| h[i] = [] }
    used_creator = Hash.new { |h,i| h[i] = [] }
    used_state_changer = Hash.new { |h,i| h[i] = [] }

    Settings.purposes.each_value do |purpose|
      used_presenter[purpose['presenter_class']] << purpose['name']
      used_creator[purpose['creator_class']] << purpose['name']
      used_state_changer[purpose['state_changer_class']] << purpose['name']
    end

    Rails.application.eager_load!

    File.open('docs/presenters.md','w') do |file|
      template = File.read('docs/templates/presenters.md.erb')
      file << eval(Erubi::Engine.new(template).src)
    end

    File.open('docs/creators.md','w') do |file|
      template = File.read('docs/templates/creators.md.erb')
      file << eval(Erubi::Engine.new(template).src)
    end

    File.open('docs/state_changers.md','w') do |file|
      template = File.read('docs/templates/state_changers.md.erb')
      file << eval(Erubi::Engine.new(template).src)
    end
  end
end
