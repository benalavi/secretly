require "stories_helper"

class SiteTest < Test::Unit::TestCase
  story "As a Visitor I want to enter a secret to pass to a friend so I can share some secure information" do
    scenario "A visitor enters a secret" do
      visit "/"
      fill_in "secret_content", with: "Foo bar baz bang!"
      click_button "Save"
      assert_contain ""
    end
  end
end
