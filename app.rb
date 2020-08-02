require 'action_view'
require 'config'
require 'digest'
require 'fileutils'
require 'mini_magick'
require 'octicons'
require 'sinatra'
require 'sinatra/activerecord'
require 'will_paginate'
require 'will_paginate/active_record'
require 'yaml'

require_relative 'lib/BootstrapLinkRenderer'
require_relative 'lib/Helpers'
require_relative 'lib/Models'

set :method_override, true

include ActionView::Helpers::TextHelper

Config.load_and_set_settings(
  "#{File.dirname(__FILE__)}/config/settings.yml"
)

get '/' do
  erb :index, :locals => {:message => nil }
end

get '/config' do
  erb :config
end

get '/folders' do
  @thumb_path   = Settings.thumb_path
  erb :folders, :locals => {:folder_root => "#{Settings.originals_path}/"}
end

get '/folders/*' do |path|
  @thumb_path   = Settings.thumb_path
  erb :folders, :locals => {:folder_root => path}
end

get '/image/:md5' do
  image = Image.find_by(md5_path: params[:md5])
  send_file("#{image.file_path}", :disposition => 'inline')
end

delete '/image/:md5' do
  image = Image.find_by(md5_path: params[:md5])
  File.delete(image.file_path) if File.exist?(image.file_path)
  image.destroy
  redirect back
end

get '/indexer' do
  build_index(
    Settings.originals_path,
    Settings.thumb_target,
    Settings.thumb_res,
    Settings.image_extentions
  )
  erb :index, :locals => {:message => 'Index ready'}
end
