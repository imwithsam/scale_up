require "logger"
require "pry"
require "capybara"
require 'capybara/poltergeist'
require "faker"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host
    def initialize(host = nil)
      Capybara.default_driver = :poltergeist
      @host = host || "http://localhost:3000"
      @lender_count = 0
      @borrower_count = 0
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [:browse_loan_requests_anonymously,
       :browse_loan_requests_anonymously,
       :browse_loan_requests_by_category_anonymously,
       :browse_loan_requests_by_category_logged_in,
       :sign_up_lender,
       :sign_up_borrower,
       :create_loan_request,
       :lend]
    end

    def log_in(email="demo+horace@jumpstartlab.com", pw="password")
      log_out
      session.visit host
      session.click_link("Login")
      session.fill_in("Email", with: email)
      session.fill_in("Password", with: pw)
      session.click_link_or_button("Log In")
    end

    def getRandomPageNumber
      page_count = session.find("body > div.pagination > a:nth-child(13)")
                          .text
                          .to_i
      1 + rand(page_count)
    end

    def getRandomCategoryNumber
      category_count = session.all("#category option").length
      rand(category_count)
    end

    def visit_random_loan_requests_page
      session.visit "#{host}/browse"
      page = getRandomPageNumber
      session.visit("#{host}/browse?page=#{page}")
    end

    def browse_loan_requests_anonymously
      log_out
      visit_random_loan_requests_page
      session.all(".lr-about").sample.click
    end

    def browse_loan_requests_logged_in
      log_in("lender@example.com", "password")
      visit_random_loan_requests_page
      session.all(".lr-about").sample.click
    end

    def visit_random_loan_requests_page_by_category
      session.visit "#{host}/browse"
      category = getRandomCategoryNumber
      session.visit("#{host}/browse?category=#{category}")
      page = getRandomPageNumber
      session.visit("#{host}/browse?category=#{category}&page=#{page}")
    end

    def browse_loan_requests_by_category_anonymously
      log_out
      visit_random_loan_requests_page_by_category
      session.all(".lr-about").sample.click
    end

    def browse_loan_requests_by_category_logged_in
      log_in("lender@example.com", "password")
      visit_random_loan_requests_page_by_category
      session.all(".lr-about").sample.click
    end

    def log_out
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_lender_email
      @lender_count = @lender_count + 1
      "lender-#{@lender_count}@example.com"
    end

    def new_borrower_email
      @borrower_count = @borrower_count + 1
      "borrower-#{@borrower_count}@example.com"
    end

    def sign_up(type = :lender, name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      if type == :lender
        session.find("#sign-up-as-lender").click
        modal = "#lenderSignUpModal"
        email = new_lender_email
      else
        session.find("#sign-up-as-borrower").click
        modal = "#borrowerSignUpModal"
        email = new_borrower_email
      end
      session.within(modal) do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: email)
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button("Create Account")
      end
    end

    def sign_up_lender
      sign_up(:lender)
    end

    def sign_up_borrower
      sign_up(:borrower)
    end

    def new_loan_title
      "#{Faker::Commerce.product_name} #{Time.now.to_i}"
    end

    def random_repayment_rate
      ["Monthly", "Weekly"].sample
    end

    def random_category
      ["Agriculture",
       "Education",
       "Water and Sanitation",
       "Youth",
       "Conflict Zones",
       "Transportation",
       "Housing",
       "Banking and Finance",
       "Manufacturing",
       "Food and Nutrition",
       "Vulnerable Groups"].sample
    end

    def random_amount
      100 + rand(99899)
    end

    def create_loan_request
      if @borrower_count > 0
        borrower = 1 + rand(@borrower_count)
        log_in("borrower-#{borrower}@example.com", "password")
      else
        log_in("borrower@example.com", "password")
      end
      session.click_link_or_button("Create Loan Request")
      session.within("#loanRequestModal") do
        session.fill_in("Title", with: new_loan_title)
        session.fill_in("Description", with: Faker::Lorem.paragraph)
        session.fill_in("Image url", with: Faker::Avatar.image)
        session.fill_in("Requested by date",
                        with: Faker::Date.between(Date.today, 7.days.from_now))
        session.fill_in("Repayment begin date",
                        with: Faker::Date.between(8.days.from_now, 365.days.from_now))
        session.select(random_repayment_rate, from: "Repayment rate")
        session.select(random_category, from: "Category")
        session.fill_in("Amount", with: random_amount)
        session.click_link_or_button "Submit"
      end
    end

    def lend
      if @lender_count > 0
        lender = 1 + rand(@lender_count)
        log_in("lender-#{lender}@example.com", "password")
      else
        log_in("lender@example.com", "password")
      end
      visit_random_loan_requests_page_by_category
      session.all(".lr-about + a").sample.click
      session.click_link_or_button "Basket"
      session.click_link_or_button "Transfer Funds"
    end
  end
end
