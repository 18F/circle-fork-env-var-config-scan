## Install all of these
require 'octokit'
require 'httpi'
require 'curb'

## Don't install this, it's standard lib
require 'json'

## You'll have to grab this one from a browser session
CIRCLE_SESSION_COOKIE = ENV['CIRCLE_SESSION_COOKIE']
GITHUB_API_TOKEN = ENV['GITHUB_API_TOKEN']

if CIRCLE_SESSION_COOKIE.empty?
  raise 'SET CIRCLE_SESSION_COOKIE before running, e.g. `docker run -e "CIRCLE_SESSION_COOKIE=123abc" circle-scan`'
end

HTTPI.adapter = :curb

Octokit.auto_paginate = true
github_repos = Octokit::Client.new(
  ## Uncomment the next line if you don't mind the folks over at CircleCI
  ## knowing the names of all of our private repos
  # access_token: GITHUB_API_TOKEN,
  auto_traversal: true,
  per_page: 100
).org_repos('18F')

@circle_cookie = HTTPI::Cookie.new(
  "ring-session=#{CIRCLE_SESSION_COOKIE}; path=/; domain=.circleci.com; "
)

@responses = {
  not_authorized: [],
  not_found: [],
  feature_enabled: [],
  feature_disabled: [],
  unknown: [],
}

def get_repo(repo_name)
  request = HTTPI::Request.new
  request.url =
    "https://circleci.com/api/v1.1/project/github/18F/#{repo_name}/settings"
  request.set_cookies @circle_cookie
  response = HTTPI.get(request)

  case response.code
  when 200
    featue_enabled = JSON.parse(response.body)["feature_flags"]["forks-receive-secret-env-vars"]
    if featue_enabled
      @responses[:feature_enabled].push(repo_name)
    else
      @responses[:feature_disabled].push(repo_name)
    end
  when 404
    @responses[:not_found].push(repo_name)
  when 403
    @responses[:not_authorized].push(repo_name)
  else
    warn "Unknown Response: #{response.code} - #{response.body}"
    @responses[:unknown].push(repo_name)
  end
rescue => e
  warn "Error fetching #{repo_name}"
  warn e
  @responses[:unknown].push(repo_name)
end

github_repos.each do |repo|
  ## idk how circle handles archived repos in this case
  ## the next line speeds this up, but excludes archived repos
  ## comment out if you want them included (there's a lot of them)
  next if repo.archived
  get_repo(repo.name)
  # If you start tripping rate limits (I managed to make 3-4 runs before I did)
  # throw a `sleep 0.25` or similar in here to pump the brakes a bit
end

puts "\nNot Found"
puts "========="
@responses[:not_found].each { |n| puts n }
puts "\nNot Authorized"
puts "=============="
@responses[:not_authorized].each { |n| puts n }
puts "\nFeature Enabled"
puts "==============="
@responses[:feature_enabled].each { |n| puts n }
puts "\nFeature Disabled"
puts "================"
@responses[:feature_disabled].each { |n| puts n }
puts "\nUnknown"
puts "======="
@responses[:unknown].each { |n| puts n }
