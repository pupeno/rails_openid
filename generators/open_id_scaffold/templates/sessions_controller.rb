class SessionsController < ApplicationController
  include RailsOpenId

  def new
    # render an openid form
  end

  def destroy
    # TODO: whatever you need to remove the user from the session.
    session["user_id"] = nil
    flash[:notice] = "You are now logged out."
    redirect_to root_url
  end

  def create
    # TODO: pick what you want to ask for, email, nickname, fullname, etc.
    send_open_id_request(params, new_session_url, finish_creating_session_url, ['email', 'nickname', 'fullname'])
  end

  def finish_creating
    oid_data = process_open_id_response(params, finish_creating_session_url, new_session_url)

    if oid_data
      oid = OpenId.find(:first, :conditions => ['identifier = ?', oid_data[:identity_url]], :include => :user)

      if not oid
        # TODO: whatever you need to do to create a new user.
        user = User.create!(
          :name => oid_data['name'],
          :nickname => oid_data['nickname'],
          :email => oid_data['email'])
        oid = user.open_ids.create(
          :identifier => oid_data[:identity_url],
          :display_identifier => oid_data[:display_identifier])
      end

      # TODO: do whatever you need to do to mark the user as logged in, merge it (if you are using ubiquitous_user), etc.
      session["user_id"] = oid.user.id
      flash[:notice] = "Welcome #{oid.user.name}, you are now logged in."
      redirect_to root_url
    end
  end
end
