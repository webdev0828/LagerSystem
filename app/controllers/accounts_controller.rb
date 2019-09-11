# encoding: utf-8
require 'csv'

class AccountsController < ApplicationController
  include AccountsHelper
  include ActionView::Helpers::NumberHelper

  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  load_and_authorize_resource :interval, :parent => false, :through => :customer,
    :only => [:index, :show, :destroy, :list, :list_weight, :summary]

  before_filter :build_current_interval, :only => [:current, :new, :current_list, :current_list_weight]

  def index
    @intervals = @intervals.order('`to` DESC')
  end

  def show
    @notes = @interval.notes
  end

  def new
  end

  def create
    authorize! :manage, Interval
    last_count = @customer.last_count
    @interval = @customer.intervals.build(interval_params)
    @interval.from = last_count || @interval.from

    if @interval.save
      redirect_to [@department, @customer, @interval], :notice => "Optællingen er nu oprettet."
    else
      render :action => 'new'
    end
  end

  def destroy
    if @interval.to == @customer.last_count
      @interval.destroy
      redirect_to [:current, @department, @customer, :intervals], :notice => "Optællingen er nu slettet."
    else
      redirect_to [@department, @customer, @interval], :alert => "Det er kun muligt at slette den seneste optælling."
    end
  end

  def current
    authorize! :read, Interval
    @intervals = @customer.intervals.order('`to` DESC').limit(4).all
    @more = @intervals.size > 3
    @intervals = @intervals.first(3)
    
    # list relevant notes
    @notes = @interval.notes
  end

  def test
    authorize! :manage, Interval
    last_count = @customer.last_count
    @interval = @customer.intervals.build(interval_params)
    @interval.from = last_count || @interval.from
  end

  BOM_UTF16 = "\377\376".force_encoding('utf-16le')

  #---------------------------#
  #   Defining export lists   #
  #---------------------------#
  def list
    filename = "#{@customer.name} - Optælling - Uge %{week} - %{year}" % @interval.week_info
    respond_to do |format|
      format.pdf do
        pdf = AccountsDocument.with_counts(view_context)
        send_data pdf.render, filename: "#{filename}.pdf", type: "application/pdf", disposition: "inline"
      end
      format.csv do
        csv = @interval.csv_counts(view_context)
        csv = BOM_UTF16 + csv.encode("utf-16le")
        send_data csv, :filename => "#{filename}.csv"
      end
      format.xls do
        send_as_file(:xls, "#{filename}.xls")
      end
    end
  end

  def list_weight
    filename = "#{@customer.name} - Optælling (vægt) - Uge %{week} - %{year}" % @interval.week_info
    respond_to do |format|
      format.pdf do
        pdf = AccountsDocument.with_weights(view_context)
        send_data pdf.render, filename: "#{filename}.pdf", type: "application/pdf", disposition: "inline"
      end
      format.csv do
        csv = @interval.csv_weights(view_context)
        csv = BOM_UTF16 + csv.encode("utf-16le")
        send_data csv, :filename => "#{filename}.csv"
      end
    end
  end

  def summary
    filename = "#{@customer.name} - Regnskab - Uge %{week} - %{year}" % @interval.week_info
    respond_to do |format|
      format.pdf do
        pdf = AccountsDocument.summary(view_context)
        send_data pdf.render, filename: "#{filename}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end


  #---------------------------------------#
  #   Defining export lists for current   #
  #---------------------------------------#
  def current_list
    filename = "#{@customer.name} - Optælling - Uge %{week} - %{year} (foreløbig)" % @interval.week_info
    respond_to do |format|
      format.pdf do
        pdf = AccountsDocument.with_counts(view_context)
        send_data pdf.render, filename: "#{filename}.pdf", type: "application/pdf", disposition: "inline"
      end
      format.csv do
        csv = @interval.csv_counts(view_context)
        csv = BOM_UTF16 + csv.encode("utf-16le")
        send_data csv, :filename => "#{filename}.csv"
      end
      format.xls do
        send_as_file(:xls, "#{filename}.xls")
        render :action => 'list'
      end
    end
  end

  def current_list_weight
    filename = "#{@customer.name} - Optælling (vægt) - Uge %{week} - %{year} (foreløbig)" % @interval.week_info
    respond_to do |format|
      format.pdf do
        pdf = AccountsDocument.with_weights(view_context)
        send_data pdf.render, filename: "#{filename}.pdf", type: "application/pdf", disposition: "inline"
      end
      format.csv do
        csv = @interval.csv_weights(view_context)
        csv = BOM_UTF16 + csv.encode("utf-16le")
        send_data csv, :filename => "#{filename}.csv"
      end
    end
  end

private

  def build_current_interval
    @interval = @customer.build_current_interval
  end

  def interval_params
    params.require(:interval).permit(:from, :to)
  end

end