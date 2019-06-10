# coding: utf-8
require 'sinatra'
require 'sinatra/reloader' if development?
require 'base64'
require "tempfile"

require './lib/cv_maker'
require './lib/txt2yaml'
require './lib/util'

include Util

get '/' do
  @title = "YAML to 履歴書"
  @date = Date.today
  @data_yml = load_as_erb("templates/data.yaml")
  @style_txt = load_as_erb("templates/style.txt")
  erb :index
end

post '/create' do
  begin
    @data = YAML.load(params[:data_yml])
    @style = TXT2YAMLConverter.new.convert(params[:style_txt])

    # TODO: detect file type
    if !params[:photo_base64].nil?
      # p params[:photo_base64]
      path = nil
      Tempfile.create("photo_base64") do |f|
        f.write(Base64.decode64(params[:photo_base64]))
        path = f.path
      end
      @data["photo"] = path
    end

    if !params[:photo].nil?
      @photo = params[:photo][:tempfile]
      @data["photo"] = @photo.path
    end

    @doc = CVMaker.new.generate(@data, @style)
    content_type 'application/pdf'
    @doc.render
  rescue => exception
    p exception
    @error_msg = exception.message
    status 403
    erb :error
  end
end
