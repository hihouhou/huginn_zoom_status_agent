require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::ZoomStatusAgent do
  before(:each) do
    @valid_options = Agents::ZoomStatusAgent.new.default_options
    @checker = Agents::ZoomStatusAgent.new(:name => "ZoomStatusAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
