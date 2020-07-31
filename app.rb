require 'action_view'
require 'digest'
require 'fileutils'
require 'mini_magick'
require 'octicons'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/config_file'
require 'will_paginate'
require 'will_paginate/active_record'

require_relative 'lib/BootstrapLinkRenderer'
require_relative 'lib/Helpers'
require_relative 'lib/Models'

config_file 'config/settings.yml'

include ActionView::Helpers::TextHelper

set :method_override, true

get '/' do
  erb :index, :locals => {:message => nil }
end

get '/folders' do
  @thumb_path   = settings.thumb_path
  erb :folders, :locals => {:folder_root => "#{settings.originals_path}/"}
end

get '/folders/*' do |path|
  @thumb_path   = settings.thumb_path
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
    settings.originals_path,
    settings.thumb_target,
    settings.thumb_res,
    settings.image_extentions
  )
  erb :index, :locals => {:message => 'Index ready'}
end
