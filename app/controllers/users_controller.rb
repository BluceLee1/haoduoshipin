class UsersController < ApplicationController
   before_action :check_admin, :only => [:newmail, :new_ep_release_mail, :sendmail]

  def login
  end

  def index
    @users = User.all
  end

  def signup
    @user = User.new
  end

  def new_ep_release_mail
    @episode = Episode.find(params[:eid])
    User.all.each do |u|
      if u.email_subscription?
        HappyMailer.new_ep_release(u.id, params[:eid]).deliver
      end
    end
    redirect_to root_url, :notice => "Mail sent!"
  end

  def edit
    @user = User.find_by_name(current_user.name) if current_user
    if @user.nil?
      redirect_to_target_or_default :root, :notice => "login first plz"
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      @user.encrypt_password
      @user.save!
      redirect_to_target_or_default :root
    else
      render :action => "edit"
    end
  end

  def login_with_providers #this will create a new user acount on local db, if this is the first time login
    omniauth = request.env["omniauth.auth"]
    # if find_by_github_uid return ture, create_from_omniauth won't be
    # executed. that's the nature of ||
    if params[:provider] == "github"
      @user = User.find_by_github_uid(omniauth["uid"]) || User.create_from_omniauth(omniauth, params[:provider])
    else
      @user = User.find_by_google_uid(omniauth["uid"]) || User.create_from_omniauth(omniauth, params[:provider])
    end
    cookies.permanent[:token] = @user.token
    redirect_to_target_or_default root_url, :notice => "Signed in successfully"
  end

  def login_with_github_failure
    @reason = params[:message]
  end

  def create # create a local account
    @user = User.new(params[:user])
    @user.encrypt_password
    if @user.save
      cookies.permanent[:token] = @user.token
      redirect_to user_path(@user), :notice => "signed up!"
    else
      render "signup"
    end
  end

  def create_login_session  #login with a local account
    user = User.authenticate(params[:name], params[:password])
    if user
      cookies.permanent[:token] = user.token
      redirect_to_target_or_default root_url :notice => "logged in"
    else
      flash.notice = "Invalid name or password"
      redirect_to :login
    end
  end

  def logout
    cookies.delete(:token)
    redirect_to root_url, :notice => "You have been logged out."
  end

  def show
    session[:return_to] = request.url
    @user = User.find_by_name(params[:username]) if params[:username]
    if @user == nil
      redirect_to root_url, :notice => "no such user!"
      return
    end
  end
end
