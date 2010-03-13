require 'test_helper'
require 'mocha'

class SessionsControllerTest < ActionController::TestCase
  test 'get log in form' do
    assert_no_difference('User.count') do
      get :new
    end
    assert_response :success
  end

  test 'start openid authentication' do
    # Mock out OpenID Request
    oidreq = mock('OpenID Request')
    oidreq.expects(:add_extension)
    oidreq.expects(:return_to_args).returns({})
    oidreq.expects(:send_redirect?).returns(true)
    oidreq.expects(:redirect_url).returns('http://cyberspace.com/login')
    OpenID::Consumer.any_instance.stubs(:begin).returns(oidreq)

    assert_no_difference('User.count') do
      post :create, :openid_identifier => 'william.cyberspace.com'
    end

    assert_redirected_to 'http://cyberspace.com/login'
  end

  test 'start openid authentication with no redirect' do
    # Mock out OpenID Request
    oidreq = mock('OpenID Request')
    oidreq.expects(:add_extension)
    oidreq.expects(:return_to_args).returns({})
    oidreq.expects(:send_redirect?).returns(false)
    body = "blah blah blah"
    oidreq.expects(:html_markup).returns(body)
    OpenID::Consumer.any_instance.stubs(:begin).returns(oidreq)

    assert_no_difference('User.count') do
      post :create, :openid_identifier => 'william.cyberspace.com'
    end

    assert_response :success
    assert_equal body, @response.body
  end

  test 'fail to start openid authentication due to invalid identifier' do
    OpenID::Consumer.any_instance.stubs(:begin).raises(OpenID::OpenIDError, "Mock OpenID error")

    assert_no_difference('User.count') do
      post :create, :openid_identifier => 'william.cyberspace.com'
    end

    assert_redirected_to new_session_url
  end

  test 'fail to start openid authentication due to empty identifier' do
    assert_no_difference('User.count') do
      post :create, :openid_identifier => ''
    end

    assert_match /enter an OpenID/, flash[:error]
  end

  test 'fail to start openid authentication due to nil identifier' do
    assert_no_difference('User.count') do
      post :create, :openid_identifier => nil
    end

    assert_match /enter an OpenID/, flash[:error]
  end

  test 'fail to start openid authentication due to missing identifier' do
    assert_no_difference('User.count') do
      post :create
    end

    assert_match /enter an OpenID/, flash[:error]
  end

  test 'log in with existing user' do
    mock_openid_response(:open_id => open_ids(:one))

    assert_no_difference('User.count') do
      get :finish_creating, :did_sreg => 'y'
    end

    assert_response :redirect
    assert_logged_in(open_ids(:one).identifier)
  end

  test 'log in creating user' do
    name = 'Ray Bradbury'
    email = 'ray@mars.com'
    identifier = 'http://ray.mars.com'
    mock_openid_response(:name => name, :email => email, :identifier => identifier)

    assert_difference('User.count', +1) do
      get :finish_creating, :did_sreg => 'y'
    end

    assert_response :redirect
    assert_logged_in(identifier)
    # Verify the user is properly create.
    oid = OpenId.find(:first, :conditions => ['identifier = ?', identifier])
    assert oid
    assert_equal name, oid.user.name
    assert_equal email, oid.user.email
  end

  test 'log in creating a user without metadata' do
    identifier = 'http://ray.mars.com'
    mock_openid_response(:identifier => identifier)

    assert_difference('User.count', +1) do
      get :finish_creating, :did_sreg => 'y'
    end

    assert_response :redirect
    assert_logged_in(identifier)
    # Verify the user is properly create.
    oid = OpenId.find(:first, :conditions => ['identifier = ?', identifier])
    assert oid
    assert_equal identifier, oid.identifier
    assert oid.user.name.blank?
    assert oid.user.nickname.blank?
    assert oid.user.email.blank?
  end

  test 'log in creating a user without metadata and an ugly identifier' do
    identifier = 'http://ray.mars.com/very/long/and/ugly/identifier/than/nobody/wants/to/ever/see'
    mock_openid_response(:identifier => identifier)

    assert_difference('User.count', +1) do
      get :finish_creating, :did_sreg => 'y'
    end

    assert_response :redirect
    assert_logged_in(identifier)
    # Verify the user is properly create.
    oid = OpenId.find(:first, :conditions => ['identifier = ?', identifier])
    assert oid
    #assert_equal User::ANON_NAME, oid.user.name_or_else
    assert oid.user.name.blank?
    assert oid.user.email.blank?
  end

  test 'log in and log out' do
    mock_openid_response(:open_id => open_ids(:one))

    assert_no_difference('User.count') do
      get :finish_creating, :did_sreg => 'y'
    end

    assert_logged_in(open_ids(:one).identifier)

    assert_no_difference('User.count') do
      get :destroy
    end
    assert_nil session[:user_id]
    assert_nil session[:user_name]
    assert_match /You are now logged out/, flash[:notice]
  end

  test 'fail to log in due to cancelled OpenID request' do
    mock_openid_response(:outcome => :cancel, :identifier => 'example.com')

    assert_no_difference('User.count') do
      get :finish_creating
    end

    assert_match /We couldn\'t verify your OpenID/, flash[:error]
  end

  test 'fail to log in due to cancelled OpenID request with no display identifier' do
    mock_openid_response(:outcome => :cancel, :identifier => 'example.com', :display_identifier => '')

    assert_no_difference('User.count') do
      get :finish_creating
    end

    assert_match /We couldn\'t verify your OpenID/, flash[:error]
  end

  private

  def assert_logged_in(identifier)
    oid = OpenId.find(:first, :conditions => ['identifier = ?', identifier])
    assert oid
    assert_equal oid.user.id, session[:user_id]
    #assert_equal oid.user.name_or_else, session[:user_name]
    #assert_match /#{oid.user.name}.*you are now logged in/, flash[:notice]
    assert_match /you are now logged in/, flash[:notice]
  end
  
  def mock_openid_response(options = {})
    identifier = options[:identifier] || options[:open_id].identifier
    display_identifier = options[:display_identifier] || (options[:open_id] && options[:open_id].display_identifier) || identifier
    outcome = options[:outcome] || :success

    oidresp = mock("OpenID Response: #{outcome}")
    oidresp.expects(:status).returns(outcome == :success ? OpenID::Consumer::SUCCESS : OpenID::Consumer::CANCEL).at_least(0)
    oidresp.expects(:identity_url).returns(identifier).at_least(0)
    oidresp.expects(:display_identifier).returns(display_identifier).at_least(0)
    OpenID::Consumer.any_instance.stubs(:complete).returns(oidresp)

    if outcome == :success
      email = options[:email] or (options[:open_id] and options[:open_id].user and options[:open_id].user.email)
      name = options[:name] or (options[:open_id] and options[:open_id].user and options[:open_id].user.name)
      nickname = options[:nickname] or (name and name.split[0])   # users never have a nickname

      sreg_resp = mock('OpenID SReg Response')
      sreg_resp.expects(:data).at_least(0).returns({
        'email' => email,
        'name' => name,
        'nickname' => nickname
        })
      OpenID::SReg::Response.stubs(:from_success_response).returns(sreg_resp)
    end
  end
end
