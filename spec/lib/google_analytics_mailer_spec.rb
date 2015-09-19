require 'spec_helper'

describe GoogleAnalyticsMailer do

  it 'ActionMailer::Base should extend GoogleAnalyticsMailer' do
    expect((class << ActionMailer::Base; self end).included_modules).to include(GoogleAnalyticsMailer)
  end

  describe '.google_analytics_mailer' do

    class TestMailer1 < ActionMailer::Base
    end

    it 'should raise on invalid options for GA params' do
      expect {
        ActionMailer::Base.google_analytics_mailer(foo: 'bar')
      }.to raise_error(ArgumentError, /:foo/)
    end

    it 'should assign given parameters to a class variable' do
      params = {utm_source: 'newsletter', utm_medium: 'email'}
      TestMailer1.google_analytics_mailer(params)
      expect(TestMailer1.google_analytics_class_params).to eq(params)
    end

    it 'should be aliased to google_analytics_controller' do
      expect(ActionMailer::Base).to respond_to :google_analytics_controller
    end

  end

  class AbstractMailer < ActionMailer::Base
    default :from => 'no-reply@example.com'

    # simulate url helper
    helper do
      def newsletter_url params = {}
        'http://www.example.com/newsletter'.tap do |u|
          u << "?#{params.to_param}" if params.any?
        end.html_safe
      end
    end

    # Links in this email will have all links with GA params automatically inserted
    def welcome
      mail(to: 'user@example.com')
    end

    def welcome2
      google_analytics_params(utm_source: 'second_newsletter', utm_term: 'welcome2')
      mail(to: 'user@example.com')
    end

    def welcome3
      mail(to: 'user@example.com')
    end
  end

  class UserMailer < AbstractMailer
    # declare url parameters for this mailer
    google_analytics_mailer utm_source: 'newsletter', utm_medium: 'email' # etc
  end

  class FilteredMailer < AbstractMailer
    # declare url parameters for this mailer
    google_analytics_mailer utm_source: 'newsletter', utm_medium: 'email', filter: ->(uri) { uri.host == 'www.example.com' }
  end

  describe FilteredMailer do

    # see view in spec/support/views/user_mailer/welcome.html.erb
    describe '#welcome' do

      subject { FilteredMailer.welcome }

      it 'should have analytics link with params taken from class definition' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=newsletter'
      end

      it 'should have analytics link with overridden params' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=my_newsletter'
      end

      it 'should have non-http link with no tracking' do
        expect(subject).to have_body_text '"http://www.external.com/"'
      end
    end
  end

  describe UserMailer do

    # Used in groups, retrieve mailer using example description
    subject do |example|
      mailer_action = example.example_group.description.sub /^\./, ''
      described_class.public_send(mailer_action)
    end

    # see view in spec/support/views/user_mailer/welcome.html.erb
    describe '.welcome' do

      it 'should have analytics link with params taken from class definition' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=newsletter'
      end

      it 'should have analytics link with overridden params' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=my_newsletter'
      end

    end

    # see view in spec/support/views/user_mailer/welcome2.html.erb
    describe '.welcome2' do

      it 'should have analytics link with params taken from instance' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=second_newsletter&utm_term=welcome2'
      end

      it 'should have analytics link with overridden params' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=my_newsletter&utm_term=welcome2'
      end

    end

    # see view in spec/support/views/user_mailer/welcome3.html.erb
    describe '.welcome3' do

      it 'should have analytics link with params taken from view' do
        expect(subject).to have_body_text 'http://www.example.com/newsletter?utm_medium=email&utm_source=newsletter&utm_term=footer'
      end

    end

  end

end