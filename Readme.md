# Kohinga

Kohinga is the maori word for collection.
This is an app to handle your image collection.
It is a ruby sinatra web app bundled with bootstrap, jquery and fancybox.
There is a Dockerfile and a Docker-Compose YAML.
But no public docker image on dockerhub yet.

## Install

    bundle install --path vendor/gems

### DB

    bundle exec rake db:create
    bundle exec rake db:migrate

## Start

    bundle exec ruby app.rb

### Build index

To index your images run `bundle exec ruby index.rb` or use the `/indexer` path from inside the app.
The `/indexer` path will get no output at the moment, but will report when finished.
You can see the progress on the console or from `docker logs kohinga -f`

All png, jpg and jpeg files will be indexed into a sqlite3.
They will be referenced only by their md5 hashed path.

For example:

    https://kohinga.example.com:4567/image/7299f8a29c06b9bfa30c412c6082e884
