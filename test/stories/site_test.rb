require File.expand_path(File.dirname(__FILE__) + "/../stories_helper")

class SiteTest < Test::Unit::TestCase
  story "As a Visitor I want to enter a secret to pass to a friend so I can share some secure information" do
    scenario "A visitor enters a secret" do
      visit "/"
      fill_in "secret_content", with: "Foo bar baz bang!"
      click_button "Save"
      assert_contain "Your secret can be accessed"
      click_link "secret_url"
      assert_contain "Foo bar baz bang!"
    end
  end
end
