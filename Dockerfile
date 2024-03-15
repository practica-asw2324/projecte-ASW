 FROM ruby:3.2.2
  RUN apt-get update && apt-get install -y nodejs
  WORKDIR /app
  COPY Gemfile* .
  RUN bundle install
  COPY . .