FROM ruby:2.6

RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_HOME /kohinga
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile $APP_HOME/
RUN bundle install --without development test
RUN apt-get install -y ffmpeg
ADD . $APP_HOME

EXPOSE 4567

CMD ["/kohinga/entry.sh"]
