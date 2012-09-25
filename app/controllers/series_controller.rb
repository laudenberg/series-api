class SeriesController < ApplicationController

  require "open-uri"
  require "digest/md5"
  require "zip/zip"

  def index
  end

  def search
    doc = Nokogiri::XML(get("#{host}/api/GetSeries.php?seriesname=#{URI.encode params[:query]}"))

    series = []
    doc.css("Series").each do |series_element|
      series.push({
        id: series_element.css("seriesid").first.content,
        name: series_element.css("SeriesName").first.content,
        overview: (series_element.css("Overview").first.content rescue "")
      })
    end

    render json: series, callback: params[:callback]
  end

  def show
    filename = ""
    series = {}
    doc, banners = docs_from_zip_url("#{host}/api/#{api_key}/series/#{params[:id]}/all/en.zip", "en.xml", "banners.xml")

    series_element = doc.css("Series")
    series[:remote_id] = series_element.css("id").first.content.to_i
    series[:name] = series_element.css("SeriesName").first.content
    series[:overview] = series_element.css("Overview").first.content
    series[:banner] = series_element.css("banner").first.content
    series[:poster] = series_element.css("poster").first.content
    series[:last_updated] = series_element.css("lastupdated").first.content.to_i
    series[:episodes] = []
    

    doc.css("Episode").each do |episode_element|
      episode = {}
      episode[:remote_id] = episode_element.css("id").first.content.to_i
      episode[:episode_number] = episode_element.css("EpisodeNumber").first.content.to_i
      episode[:season_number] = episode_element.css("SeasonNumber").first.content.to_i
      episode[:name] = episode_element.css("EpisodeName").first.content
      episode[:overview] = episode_element.css("Overview").first.content
      episode[:date] = episode_element.css("FirstAired").first.content
      episode[:image] = episode_element.css("filename").first.content
      episode[:last_updated] = episode_element.css("lastupdated").first.content.to_i

      since = params[:since].to_i

      if episode[:date] != ''
        episode[:unixdate] = Time.parse(episode[:date]).to_i
        if Time.parse(episode[:date]).to_i > since
          series[:episodes].push episode
        end
      end

    end

    if !params[:episode]
      series[:banners] = []
      banners.css("Banner").each do |banner|
        if banner.css("BannerType").first.content == "series" &&
          banner.css("BannerType2").first.content == "graphical"
          series[:banners].push banner.css("BannerPath").first.content
        end
      end
    end

    if params["season"].present?
      #debugger
      series[:episodes].delete_if{ |episode| episode[:season_number] != params[:season].to_i}
    end

    if params["episode"].present?
      series[:episodes].delete_if{ |episode| episode[:episode_number] != params[:episode].to_i}
    end

    render json: series, callback: params[:callback]
  end

  private

  def docs_from_zip_url(url, *files)
    filename = cache(url)
    
    begin
      docs = docs_from_zip(filename, *files)
    rescue
      invalidate(url)
      cache(url)
      # Give it a second try. If it fails, fail badly.
      docs = docs_from_zip(filename, *files)
    end

    return docs
  end

  def docs_from_zip(zip, *files)
    docs = []
    Zip::ZipInputStream::open(zip) do |f|
      while entry = f.get_next_entry
        docs.push Nokogiri::XML(f.read) if files.include? entry.name
      end
    end
    docs
  end

  def host
    "http://thetvdb.com"
  end

  def api_key
    "FF8BC00413A5520E"
  end

  def max_age
    1 * 60 * 15
  end

  def cache_dir
    'tmp/apicache'
  end

  def cache(url)
    logger.debug "caching #{url}"
    cache_filename = cache_dir + url.gsub(host, "")
    cache_path = File.dirname(cache_filename)
    FileUtils.mkdir_p(cache_path) 

    if !File.exists?(cache_filename) || (Time.now - File.mtime(cache_filename)) > max_age
      logger.debug "cache miss #{cache_filename}"
      File.open(cache_filename, 'w+', encoding: "ascii-8bit") {|f| f.write(open(url).read) }
    end

    cache_filename
  end

  def invalidate(url)
    logger.debug "invalidating #{url}"
    cache_filename = cache_dir + url.gsub(host,"")
    File.unlink(cache_filename) if File.exists?(cache_filename)
  end

  def get(url)
    File.read(cache(url))
  end

end

