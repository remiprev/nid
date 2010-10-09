class Importer < Nid

  def self.add_tweet tweet # {{{
    new_tweet = Tweet.create({
      :tweet_id => tweet.id,
      :text => tweet.text,
      :created_at => tweet.created_at
    })

    # Import user @mentions
    tweet.entities.user_mentions.each do |mention|
      new_tweet.mentions.push({ :user_id => User.first_or_create({ :user_id => mention.id, :username => mention.screen_name, }).id })
    end

    # Import #hashtags
    tweet.entities.hashtags.each do |hashtag|
      new_tweet.hashtags.push({ :tag_id => Tag.first_or_create({ :tag => hashtag.text, }).id })
    end

    new_tweet.save
  end # }}}

  def self.twitter # {{{
    twitter_config = NID_CONFIG["twitter"]
    oauth = Twitter::OAuth.new twitter_config["consumer_key"], twitter_config["consumer_secret"]
    oauth.authorize_from_access twitter_config["access_token"], twitter_config["access_secret"]

    client = Twitter::Base.new(oauth)
  end # }}}

  def self.import! # {{{
    client = Importer.twitter

    page = 1
    options = {
      :page => page,
      :screen_name => "remi",
      :trim_user => 1,
      :count => 200,
      :include_entities => 1,
    }

    last_tweet = Tweet.first :order => :created_at.asc, :limit => 1
    options.merge! :max_id => last_tweet.tweet_id-1 if last_tweet

    while true
      tweets = client.user_timeline(options.merge :page => page)
      break unless tweets.length > 0

      tweets.each do |tweet|
        Importer.add_tweet tweet
      end

      page += 1
      p "Sleeping for 10 seconds..."
      sleep 10
    end
  end # }}}

  def self.update! # {{{
    client = Importer.twitter
    page = 1
    options = {
      :page => page,
      :screen_name => "remi",
      :trim_user => 1,
      :count => 200,
      :include_entities => 1,
    }

    first_tweet = Tweet.first :order => :created_at.desc, :limit => 1
    options.merge! :since_id => first_tweet.tweet_id if first_tweet

    while true
      tweets = client.user_timeline(options.merge :page => page)
      break unless tweets.length > 0

      tweets.each do |tweet|
        Importer.add_tweet tweet
      end

      page += 1
      p "Sleeping for 10 seconds..."
      sleep 10
    end
  end # }}}

end
