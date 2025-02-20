# coding: utf-8
require "mini_magick"
require "open-uri"
require "prawn"
require "yaml"
require "./lib/txt2yaml"
require "./lib/util"

$font_faces = Hash.new
$font_faces["mincho"] = "fonts/ipaexm.ttf"
$font_faces["gothic"] = "fonts/ipaexg.ttf"

DEFAULT_FONT_FACE = "mincho"
DEFAULT_FONT_SIZE = 12
DEFAULT_LINE_WIDTH = 0.5

class CVMaker
  include TXT2YAML
  include Util

  def line_style(h)
    if h.has_key?("line_style")
      case h["line_style"]
      when "solid"
        undash
      when "dashed"
        d = DEFAULT_LINE_WIDTH
        @doc.dash([d, d])
      end
    else
      @doc.undash
    end
    if h.has_key?("line_width")
      @doc.line_width(h["line_width"])
    else
      @doc.line_width(DEFAULT_LINE_WIDTH)
    end
  end

  def get_value(h)
    value = h["value"]
    if value =~ /\$(.*)$/
      value = @data.fetch($1, "")
    end
    value
  end

  def get_font(h)
    font_size = h.fetch("font_size", DEFAULT_FONT_SIZE).to_f
    face = h.fetch("font_face", DEFAULT_FONT_FACE)
    font_face = ""
    if $font_faces.has_key?(face)
      font_face = $font_faces[face]
    else
      font_face = face
    end
    return font_size, font_face
  end

  def put_string(x, y, str, font_size, font_face)
    return if str == ""
    w = font_size * str.size
    h = font_size
    @doc.bounding_box([x, y], :width => w, :height => h) do
      @doc.font_size font_size
      @doc.font font_face
      @doc.text str
    end
  end

  def photo(h)
    return if !@data.has_key?("photo")
    x = size(h["x"])
    y = size(h["y"])
    width = size(h["width"])
    height = size(h["height"])
    file = @data["photo"]
    unless file.strip !~ /^https?|^ftp\:\/\//
      file = open(file).path
    end
    image = MiniMagick::Image.new(file)
    # 画像の向きを調整、切り抜き
    image.combine_options do |img|
      img.auto_orient
      img.strip # EXIF情報の除去
      img.gravity(:center)
      img.crop(resize_image_opt(image, width, height))
    end
    @doc.image(image.path, :at => [x, y], :width => width, :height => height)
  end

  def string(h)
    x = size(h["x"])
    y = size(h["y"])
    str = get_value(h)
    font_size, font_face = get_font(h)
    w = font_size * str.size
    h = font_size
    @doc.bounding_box([x, y], :width => w, :height => h) do
      @doc.font_size font_size
      @doc.font font_face
      @doc.text str
    end
  end

  def box(h)
    line_style(h)
    x = size(h["x"])
    y = size(h["y"])
    w = size(h["width"])
    h = size(h["height"])
    @doc.move_to(x, y)
    @doc.line_to(x + w, y)
    @doc.line_to(x + w, y + h)
    @doc.line_to(x, y + h)
    @doc.close_and_stroke
  end

  def line(h)
    line_style(h)
    x = size(h["x"])
    y = size(h["y"])
    dx = size(h["dx"])
    dy = size(h["dy"])
    @doc.move_to(x, y)
    @doc.line_to(x + dx, y + dy)
    @doc.stroke
  end

  def lines(h)
    line_style(h)
    points = h["points"]
    x = size(points[0]["x"])
    y = size(points[0]["y"])
    close = h.has_key?("close")
    @doc.move_to(x, y)
    points[1..(points.size - 1)].each do |i|
      if i.has_key?("dx")
        x = x + size(i["dx"])
      else
        x = size(i["x"])
      end
      if i.has_key?("dy")
        y = y + size(i["dy"])
      else
        y = size(i["y"])
      end
      @doc.line_to(x, y)
    end
    if close
      @doc.close_and_stroke
    else
      @doc.stroke
    end
  end

  def multi_lines(h)
    line_style(h)
    x = size(h["x"])
    y = size(h["y"])
    dx = size(h["dx"])
    dy = size(h["dy"])
    sx = size(h["sx"])
    sy = size(h["sy"])
    n = h["num"].to_i
    n.times do |i|
      @doc.move_to(x, y)
      @doc.line_to(x + dx, y + dy)
      @doc.stroke
      x = x + sx
      y = y + sy
    end
  end

  def puts_history(year_x, month_x, value_x, h)
    year = h.fetch("year", "").to_s
    month = h.fetch("month", "").to_s
    put_string(year_x, y, year, font_size, font_face)
    x = month_x - (month.size - 1) * font_size * 0.3
    put_string(x, y, month, font_size, font_face)
    put_string(value_x, y, h["value"].to_s, font_size, font_face)
  end

  # 学歴・職歴
  def education_experience(h)
    y = size(h["y"])
    year_x = size(h["year_x"])
    month_x = size(h["month_x"])
    value_x = size(h["value_x"])
    ijo_x = size(h["ijo_x"])
    dy = size(h["dy"])
    caption_x = size(h["caption_x"])
    font_size, font_face = get_font(h)
    put_string(caption_x, y, "学歴", font_size, font_face)
    y = y - dy
    education = @data["education"]
    education.each do |i|
      year = i.fetch("year", "").to_s
      month = i.fetch("month", "").to_s
      put_string(year_x, y, year, font_size, font_face)
      x = month_x - (month.size - 1) * font_size * 0.3
      put_string(x, y, month, font_size, font_face)
      put_string(value_x, y, i["value"].to_s, font_size, font_face)
      y = y - dy
    end
    put_string(caption_x, y, "職歴", font_size, font_face)
    y = y - dy
    experience = @data["experience"]
    experience.each do |i|
      year = i.fetch("year", "").to_s
      month = i.fetch("month", "").to_s
      put_string(year_x, y, year, font_size, font_face)
      x = month_x - (month.size - 1) * font_size * 0.3
      put_string(x, y, month, font_size, font_face)
      put_string(value_x, y, i["value"].to_s, font_size, font_face)
      y = y - dy
    end
    put_string(ijo_x, y, "以上", font_size, font_face)
  end

  def new_page(h)
    @doc.start_new_page
  end

  # 年・月・内容形式
  def history(h)
    y = size(h["y"])
    year_x = size(h["year_x"])
    month_x = size(h["month_x"])
    value_x = size(h["value_x"])
    font_size, font_face = get_font(h)
    data = get_value(h)
    dy = size(h["dy"])
    return if data == ""
    data.each do |i|
      year = i.fetch("year", "").to_s
      month = i.fetch("month", "").to_s
      put_string(year_x, y, year, font_size, font_face)
      x = month_x - (month.size - 1) * font_size * 0.3
      put_string(x, y, month, font_size, font_face)
      put_string(value_x, y, i["value"].to_s, font_size, font_face)
      y = y + dy
    end
  end

  def textbox(h)
    x = size(h["x"])
    y = size(h["y"])
    width = size(h["width"])
    height = size(h["height"])
    value = get_value(h)
    font_size, font_face = get_font(h)
    @doc.bounding_box([x, y], :width => width, :height => height) do
      @doc.font_size font_size
      @doc.font font_face
      @doc.text value
    end
  end

  def generate(data, style)
    @data = data
    @doc = Prawn::Document.new(:page_size => "A4")
    style.each do |i|
      send(i["type"], i)
    end
    @doc
  end
end
