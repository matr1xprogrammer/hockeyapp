module HockeyApp
  class Invite
    extend  ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModelCompliance

    ANDROID = 'Android'
    IOS = 'iOS'

    ATTRIBUTES = [:title, :status, :company, :owner, :bundle_identifier, :platform,
        :public_identifier, :role, :release_type]

    POST_PAYLOAD = [:status, :email, :first_name, :last_name, :message, :role, :tags ]

    ROLES_TO_SYM = {
        1 => :developers,
        2 => :members,
        3 => :testers
    }

    STATUS_TO_SYM = {
        1 => :deny,
        2 => :allow
    }

    attr_accessor *ATTRIBUTES
    attr_accessor *POST_PAYLOAD
    attr_reader :app

    validates :role, :inclusion => { :in => ROLES_TO_SYM.keys }
    validates :status, :inclusion => { :in => STATUS_TO_SYM.keys }

    def self.from_hash(h, app, client)
      res = self.new app, client
      ATTRIBUTES.each do |attribute|
        res.send("#{attribute.to_s}=", h[attribute.to_s]) unless (h[attribute.to_s].nil?)
      end
      res
    end

    def initialize app, client
      @app = app
      @client = client
      default_values!
    end

    def to_key
      [public_identifier] if persisted?
    end

    def platform= platform
      @platform = platform
    end

    def crashes
      @crashes ||= @app.crashes.select{|crash| "#{crash.app_version_id}" == @id.to_s}
    end

    def crash_reasons options = {}
      @crash_groups ||= client.get_crash_groups_for_version(self, options)
    end


    def direct_download_url
      url_strategy.direct_download_url
    end

    def install_url
      url_strategy.install_url
    end

    private

    attr_reader :client

    def default_values!
      @first_name=''
      @last_name=''
      @message=''
      @role=3
      @status=Invite::STATUS_TO_SYM.invert[:allow]
    end

    def url_strategy
      return HockeyApp::IOSAppUrls.new(self) if platform == IOS
      return HockeyApp::AndroidAppUrls.new(self) if platform == ANDROID
    end

  end
end