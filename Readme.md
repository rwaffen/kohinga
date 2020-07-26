# Install

    bundle install --path vendor/gems

# DB

    # # neue leere migration anlegen
    # bundle exec rake db:create_migration NAME=create_images_table
    
    bundle exec rake db:create
    bundle exec rake db:migrate

# Start

    bundle exec ruby app.rb
