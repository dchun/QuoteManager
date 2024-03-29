class QuotesController < ApplicationController
  include Notable

  before_filter :authenticate_user!, except: [:accept, :public, :track_email, :decline]
  before_filter :block_freeloaders!, except: [:accept, :public, :track_email, :decline]
  before_action :set_quote, only: [:show, :edit, :update, :destroy]
  before_action :get_quote, only: [:accept, :decline]
  before_action :check_token, only: [:public]
  before_action :parse_request, only: [:public]
  load_and_authorize_resource param_method: :quote_params, except: [:accept, :public, :track_email, :decline]

  # Tracking quote
  #after_filter :track_action, only: [:public]

  # GET /quotes
  # GET /quotes.json
  def index
    @quotes = current_account.quotes.includes(:note).page(params[:page]).per(25)
  end

  # GET /quotes/1
  # GET /quotes/1.json
  def show
  end

  # GET /quotes/new
  def new
    @quote = current_account.quotes.new
    @qb = current_account.quotes.new
    @request = current_account.requests.find(params[:request_id]) if params[:request_id]
    @quote.note ||= Note.new
    @templates = current_account.templates.where(using_type: 'Quote')
  end

  # GET /quotes/1/edit
  def edit
    @qb = current_account.quotes.find(params[:id])
    @templates = current_account.templates.where(using_type: 'Quote')
    @quote.note ||= Note.new
  end

  # POST /quotes
  # POST /quotes.json
  def create
    @quote = current_account.quotes.new(quote_params)

    respond_to do |format|
      if @quote.save
        format.html { redirect_to @quote, notice: 'Quote was successfully created.' }
        format.json { render :show, status: :created, location: @quote }
      else
        format.html { render :new }
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /quotes/1
  # PATCH/PUT /quotes/1.json
  def update
    respond_to do |format|
      if @quote.update(quote_params)
        format.html { redirect_to @quote, notice: 'Quote was successfully updated.' }
        format.json { render :show, status: :ok, location: @quote }
      else
        format.html { render :edit }
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quotes/1
  # DELETE /quotes/1.json
  def destroy
    @quote.destroy
    respond_to do |format|
      format.html { redirect_to quotes_url }
      format.json { head :no_content }
    end
  end

  # POST /quotes/:id 
  # User accept a quote
  def accept
    @quote.signature = params[:sig]
    @quote.request.status = 'completed'
    tran = @quote.transition_to!(:accepted)

    if tran && @quote.save
      redirect_to :back, :notice => "You have accepted this quote"
    else
      redirect_to :back, :notice => "Can't save your signature"
    end
  end

  # POST /quotes/:id 
  # User decline a quote
  def decline
    tran = @quote.transition_to!(:declined)
    if tran
      redirect_to :back, :alert => "You have declined this quote"
    else
      redirect_to :back, :alert => "You can't decline this quote at this time. Please try again!"
    end
  end

  # GET /quotes?token=
  def public
    @quote.update(email_opened:  @quote.email_opened + 1)
  end

  # POST /quotes/:id/send-quote
  def send_quote
    quote = Quote.find(params[:quote_id])
    errors = find_invalid_email(params[:email]['addresses'].split(','))
    quote.email_sent = quote.email_sent + 1
    quote.transition_to!(:sent) if quote.current_state == 'draft'

    respond_to do |format|
      if errors.nil? && quote.save 
    
        identity = Identity.by_google_account(current_user.account_id)
        send_quote_email(params[:email], quote, identity)

        unless identity.present? && identity.refresh_token.present?

          format.html { redirect_to :back, notice: "Your email is on it's way!." }
          format.json { render json: params[:email], status: :ok }
        else
          format.html { redirect_to request.referrer, alert: "Looks like permissions have changed. Unlink your account and revoke access to this application and restart the syncing process." }
        end
      else 
        format.html { redirect_to :back, alert: 'Invalid email address.' }
        format.json { render json: params[:email], status: 400 }
      end
    end
  end

  # POST /quotes/:id/note
  def update_note
    quote = Quote.find(params[:quote_id])
    update_notable(quote, quote_params)
  end

  # GET /quotes/:id/email-tracking
  def track_email
    quote = Quote.find(params[:quote_id])
    quote.update_columns(email_opened: (quote.email_opened + 1))

    send_file Rails.root.to_s + "/app/assets/images/quote-email-tracking.png", :s_sendfile => true
  end

  # GET /quotes/:id/track
  def analytics
    @quote = Quote.analytics(params[:quote_id])[0]
    @visitors = @quote.visitors.page(params[:page]).per(25)
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_quote
    @quote = Quote.find(params[:id])
  end

  def get_quote
    @quote = Quote.find(params[:quote_id])
  end

  def find_invalid_email(emails)
    emails.detect do |e| 
      e.match(/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/).nil?
    end
  end

  def send_quote_email(email, quote, identity)
    # Choose to use GMail api or default email
    if identity.present? && identity.refresh_token.present?
      google_auth = GoogleAuth.new(identity)
      gmail_api = GmailAPI.new(google_auth.fresh_token)

      email['addresses'].split(',').each do |address|
        msg = QuoteMailer.send_quote(address, quote, email['content'], identities[0].social_name)
        gmail_api.send_message(msg)
      end
    else
      Thread.new do
        email['addresses'].split(',').each do |address|
          QuoteMailer.send_quote(address, quote, email['content'], ENV['DEFAULT_EMAIL']).deliver
        end
      end
    end
  end

  def parse_request
    @quote = Quote.find(params[:id])
    @company = @quote.account
    if @quote.request.present?
      @contact = @quote.request.contact
    end
    if @quote.options.present?
      @total = @quote.amount + @quote.options.map { |id, op| op['amount'].to_f }.inject(:+) 
    else
      @total = @quote.amount
    end

    # Get sender information
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def quote_params
    params.require(:quote).permit(
      :amount, 
      :token, 
      :expires_at, 
      :template_id, 
      :request_id, 
      :currency,
      :description, 
      :note_attributes => [:title, :content],
      options: [:description, :amount])
  end

  def token_validity
    Quote.find_by_token(params[:token])
  end

  def check_token
    unless user_signed_in?
      if token_validity.nil?
        redirect_to root_url, alert: "Not authorized"
      elsif token_validity.expires_at <= Time.now
        redirect_to root_url, alert: "Offer has expired"
      end
    end
  end
end
