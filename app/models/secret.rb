require "digest/sha1"
require "openssl"

class Secret < Ohm::Model
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
      Digest::SHA1.hexdigest(ENV["HASH_KEY"] + "::" + url.to_s)
    end
  end
  
  # Returns the decrypted content using the given key for decryption.
  def content(key=nil)
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
    @expires_at ||= Time.parse(read_local(:expires_at))
  end
    
  def create  
    # Generate URL
    # Based on Time.now to help avoid collisions, hash_key to avoid
    # predictability, and a randomly generated string just for good measure.
    # Take a SHA1 of that (really just to make a nice URL string from it) to
    # use as our URL/encryption key, then we'll SHA1 that again before storing
    # to ensure that the user got the key from the URL they were given and 
    # didn't hack it from the database.
    @url = Digest::SHA1.hexdigest(Time.now.to_i.to_s + "::" + ENV["HASH_KEY"] + "::" + rand(10**10).to_s(36))
    self.encrypted_url = self.class.hash_url(@url)
    
    # Encrypt the content against our key
    aes = OpenSSL::Cipher::Cipher.new("AES-256-ECB")
    aes.encrypt
    aes.key = @url

    self.encrypted_content = aes.update(@content) + aes.final
    
    super
  end
end
