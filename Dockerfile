FROM ruby:2.4.3

ENV CIRCLE_SESSION_COOKIE ''
ENV GITHUB_API_TOKEN ''

ADD scan.rb Gemfile Gemfile.lock ./
RUN bundle install

CMD ruby scan.rb
