#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'cgi'
require 'byebug'

class Mite
  def initialize
    account = 'nerdgeschoss'
    @token   = ENV["TOKEN"]
    @base_uri = "https://#{account}.mite.yo.lk"
    @cache_file = ".projectscache"
  end

  def list_projects(query)
    projects = load_or_initialize_cache
    res = projects.select  { |pj| pj['project']['name'] =~ /#{query}/i }
    res += projects.select { |pj| pj['project']['customer_name'] =~ /#{query}/i }
    res.length > 0 ? res.uniq : projects
  end

  def test_auth
    get "/account.json"
  end

  private

  def load_or_initialize_cache
    if File.exists?(@cache_file)
      JSON.parse File.read(@cache_file)
    else
      cache_all_projects_for_user
    end
  end

  def cache_all_projects_for_user
    projects = get "/projects.json"
    File.open(@cache_file, 'w') do |f|
      f.write projects.to_json
    end
    projects
  end

  def get(path, params = {})
    qs = ''
    uri = URI("#{@base_uri}#{path}#{qs}")

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(uri)
      req['X-MiteApiKey'] = @token
      http.request(req)
    end

    json = JSON.parse res.body
  end
end

query = ARGV[0]
opt   = ARGV[1]
mite = Mite.new
puts mite.send query, opt

# begin
#   if query == '--update'
#   elsif query == '--auth'
#     mite.store_token(ARGV[1])
#   else
#     results = mite.list_projects(query || '')
#
#     output = XmlBuilder.build do |xml|
#       xml.items do
#         results.each do |pj|
#           xml.item Item.new(pj['url'])
#         end
#       end
#     end
#
#     puts output
#   end
# end
