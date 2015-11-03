desc "Simulate load against Keevahh application"
task :load_test => :environment do
  4.times.map { Thread.new { browse } }.map(&:join)
end

def browse
  session = Capybara::Session.new(:poltergeist)
  session.visit("http://localhost:3000")
  session.click_link("Login")
  session.fill_in "Email", with: "jorge@example.com"
  session.fill_in "Password", with: "password"
  session.click_button "Log In"
  puts "Logged in as jorge@example.com"

  loop do
    page = 1 + rand(16700)
    session.visit("http://localhost:3000/browse?page=#{page}")
    session.all(".caption p a").sample.click
    puts session.current_path
  end
end
