# encoding: utf-8
require "logstash/outputs/base"
require 'swiftype-enterprise'

# An elastic_ent_search output that ingest content to enterprise search.
# Example config file:
#
#input {
#  file {
#    path => "./ent_search_sample.csv"
#    start_position => "beginning"
#  }
#}
#
#filter {
#  csv {
#    autodetect_column_names => true
#  }
#  mutate {
#    remove_field => [ "path" ]
#  }
#}
#
#output {
#  elastic_ent_search {
#    access_token => '<ACCESS TOKEN>'
#    content_source_key => '<CONTENT SOURCE KEY>'
#    endpoint => 'http://localhost:3002/api/v1/'
#  }
#}
#
# Example ent_search_sample.csv
# external_id,url,title,body,created_at,updated_at,type
# 11,http://www.elastic.co/11,document1,Test document1,2019-06-01T12:00:00+00:00,2019-07-02T12:00:00+00:00,list


class LogStash::Outputs::ElasticEntSearch < LogStash::Outputs::Base
  config_name "elastic_ent_search"

  config :access_token, :validate => :string, :required => true
  config :content_source_key, :validate => :string, :required => true
  config :timestamp_destination, :validate => :string
  config :document_id, :validate => :string
  config :endpoint, :validate => :string, :required => true

  public
  def register
    if @endpoint.nil? 
      raise ::LogStash::ConfigurationError.new("Please specify the endpoint \"endpoint\".")
    elsif @access_token.nil?
      raise ::LogStash::ConfigurationError.new("Please specify the access token \"access_token\".")
    elsif @content_source_key.nil?
      raise ::LogStash::ConfigurationError.new("Please specify the content source key \"access_token\".")
    end 
    SwiftypeEnterprise.access_token = @access_token
    @swiftype = SwiftypeEnterprise::Client.new
    SwiftypeEnterprise.endpoint = @endpoint
    check_connection!
  rescue => e
    if e.message =~ /401/
      raise ::LogStash::ConfigurationError.new("Failed to connect to Enterprise Search. Error: 401. Please check your credentials")
    elsif e.message =~ /404/
      raise ::LogStash::ConfigurationError.new("Failed to connect to Enterprise Search. Error: 404. Please check if host '#{@host}' is correct and you've created an engine with name '#{@engine}'")
    else
      raise ::LogStash::ConfigurationError.new("Failed to connect to Enterprise Search. #{e.message}")
    end
  end # def register

  public
  def multi_receive(events)
    # because App Search has a limit of 100 documents per bulk
    events.each_slice(100) do |events|
      batch = format_batch(events)
      if @logger.trace?
        @logger.trace("Sending bulk to Enterprise Search", :size => batch.size, :data => batch.inspect)
      end
      index(batch)
    end
  end

  private
  def format_batch(events)
    events.map do |event|
      doc = event.to_hash
      # we need to remove default fields that start with "@"
      # since Elastic Ent Search doesn't accept them
      if @timestamp_destination
        doc[@timestamp_destination] = doc.delete("@timestamp")
      else # delete it
        doc.delete("@timestamp")
      end
      if @document_id
        doc["external_id"] = event.sprintf(@document_id)
      end
      doc.delete("@version")
      doc.delete("host")
      doc.delete("message")
      doc
    end
  end

  def index(documents)
    SwiftypeEnterprise.endpoint = @endpoint
    #response = @swiftype.index_documents(@content_source_key, documents)
    response = @swiftype.index_documents(@content_source_key, documents)

    report(documents, response)
    # handle results
  rescue SwiftypeEnterprise::ClientException => e
    # handle error
    @logger.error("Failed to execute index operation. Retrying..", :exception => e.class, :reason => e.message)
    sleep(1)
  end 

  def report(documents, response)
    documents.each_with_index do |document, i|
      errors = response[i]["errors"]
      if errors.empty?
        @logger.trace? && @logger.trace("Document was indexed with no errors", :document => document)
      else
        @logger.warn("Document failed to index. Dropping..", :document => document, :errors => errors.to_a)
      end
    end
  end

  def check_connection!
  end

end # class LogStash::Outputs::ElasticEntSearch

