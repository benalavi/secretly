require "digest/sha1"
require "openssl"
require "ohm/contrib"

class Secret < Ohm::Model
  include Ohm::Callbacks
  
  class ContentExpiredError < RuntimeError;end;
  
  # TODO: take a password and hash that w/ the URL as the decryption key
  attr_accessor :password, :password_verification
  attr_accessor :content
  attr_reader :url
  
  attribute :encrypted_url
  index :encrypted_url
  attribute :encrypted_content
  attribute :expires_at
  
  class << self
    def hash_url(url)
      Digest::SHA1.hexdigest(settings(:hash_key) + "::" + url.to_s)
    end
    
    def expired
      key[:expires_at].zrevrangebyscore(Time.now.to_i, 0).collect(&Secret)
    end
  end
  
  # Returns the decrypted content using the given key for decryption.
  def content(key=nil)
    # Fail to show content when expired, in case something went wrong like the
    # expunge cron failed.
    raise ContentExpiredError.new("Content expired") if Time.now > self.expires_at
    
    return @content unless @content.nil?
    
    aes = OpenSSL::Cipher::Cipher.new("AES-256-ECB")
    aes.decrypt
    aes.key = key
    @content = aes.update(encrypted_content) + aes.final
  end
  
  # Set expires_at to the given number of hours from now.
  def expires_in=(expires_in)
    @expires_at = Time.now + expires_in.to_i * 3600
  end
  
  def expires_at
    @expires_at ||= Time.at(read_local(:expires_at))
  end
  
  protected
  
  def before_create
    # Generate URL
    # Based on Time.now to help avoid collisions, hash_key to avoid
    # predictability, and a randomly generated string just for good measure.
    # Take a SHA1 of that (really just to make a nice URL string from it) to
    # use as our URL/encryption key, then we'll SHA1 that again before storing
    # to ensure that the user got the key from the URL they were given and 
    # didn't hack it from the database.
    @url = Digest::SHA1.hexdigest(Time.now.to_i.to_s + "::" + settings(:hash_key) + "::" + rand(10**10).to_s(36))
    self.encrypted_url = self.class.hash_url(@url)
    
    # Encrypt the content against our key
    aes = OpenSSL::Cipher::Cipher.new("AES-256-ECB")
    aes.encrypt
    aes.key = @url

    self.encrypted_content = aes.update(@content) + aes.final
    
    write_local(:expires_at, self.expires_at.to_i)
  end
  
  def after_create
    self.class.key[:expires_at].zadd(self.expires_at.to_i, id)
  end
  
  def after_delete
    self.class.key[:expires_at].zrem(id)
  end
end
