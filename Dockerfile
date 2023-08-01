FROM ruby:2.7
ENV BUNDLER_VERSION=2.2.26
RUN apt-get update -qq && apt-get install -y
# Install node and Yarn
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs
RUN apt-get install -y python2
RUN npm install -g yarn
WORKDIR /samples_extraction
ADD Gemfile /samples_extraction
ADD Gemfile.lock /samples_extraction
ADD package.json /samples_extraction
ADD yarn.lock /samples_extraction
RUN gem install bundler
RUN bundle install --jobs=5 --deployment --without development test
RUN yarn install

ADD . /samples_extraction/

# Compiling assets
RUN SE_REDIS_URI= SECRET_KEY_BASE=`bin/rake secret` WARREN_TYPE=log RAILS_ENV=production bundle exec rake assets:precompile

# Generating sha
RUN git rev-parse HEAD > REVISION
RUN git tag -l --points-at HEAD --sort -version:refname | head -1 > TAG
RUN git rev-parse --abbrev-ref HEAD > BRANCH
