class QuotesController < ApplicationController
  before_filter :authenticate_user!, except: [:show, :accept_quote]
  before_action :check_token, only: [:show]
  before_action :set_quote, only: [:show, :edit, :update, :destroy, :accept_quote]
  before_action :parse_request, only: [:show]

  # GET /quotes
  # GET /quotes.json
  def index
    @quotes = Quote.page(params[:page]).per(25)
  end

  # GET /quotes/1
  # GET /quotes/1.json
  def show
  end

  # GET /quotes/new
  def new
    @quote = Quote.new
    @qb = Quote.new
    @request = Request.find(params[:request_id]) if params[:request_id]
  end

  # GET /quotes/1/edit
  def edit
    @qb = Quote.find(params[:id])
    @request = Request.find(@qb.request_id)
  end

  # POST /quotes
  # POST /quotes.json
  def create
    @quote = Quote.new(quote_params)

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
  def accept_quote
    @quote.signature = params[:sig]
    @quote.request.status = 'confirmed'
    if @quote.save
      redirect_to :back, :notice => "You have accepted this quote"
    else
      redirect_to :back, :notice => "Can't save your signature"
    end
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_quote
    @quote = Quote.find(params[:id])
  end

  def parse_request
    # Get owner by tenant name
    @owner = Account.find_by_subdomain(request.subdomain).owner
    @total = @quote.amount + @quote.options.map { |id, op| op['amount'].to_f }.inject(:+) 
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def quote_params
    params.require(:quote).permit(:amount, :token, :expires_at, :request_id, :description, options: [:description, :amount])
  end

  def token_validity
    token = Quote.find_by_token(params[:token])
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
