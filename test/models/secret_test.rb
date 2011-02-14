require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SecretTest < Test::Unit::TestCase
  Ohm.flush
  
  context "creating a Secret" do
    setup do
      @secret = Secret.create content: "Foo bar baz bang.", expires_in: 3
    end
    
    should "generate a url and store a hashed version of the url" do
      assert @secret.url
      assert_equal Secret.hash_url(@secret.url), @secret.encrypted_url
    end

    should "encrypt the contents of the secret against the generated url" do
      assert_not_equal "Foo bar baz bang.", @secret.encrypted_content
      assert_equal "Foo bar baz bang.", @secret.content(@secret.url)
    end
    
    should "not save the unhashed URL" do
      secret = Secret.find(encrypted_url: Secret.hash_url(@secret.url)).first
      assert secret
      assert !secret.url
    end
    
    should "set expires_at 3 hours in the future" do
      assert_equal Time.now.hour + 3, @secret.expires_at.hour
    end
  end
  
  context "finding Secrets" do
    setup do
      @expired = Secret.create content: "Foo bar baz bang.", expires_in: -1
      @current = Secret.create content: "Foo bar baz bang.", expires_in: 1
    end
    
    should "find only expired secrets" do
      assert_equal 1, Secret.expired.length
      assert_equal @expired, Secret.expired.first
    end    
  end
end
