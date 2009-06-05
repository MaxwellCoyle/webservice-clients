#!/usr/bin/env ruby
# $Id$
# ======================================================================
# NCBI BLAST jDispatcher SOAP web service Ruby client
#
# Tested with:
#   SOAP4R 1.5.5 and Ruby 1.8.5 (CentOS 5)
#
# See:
# http://www.ebi.ac.uk/Tools/webservices/services/ncbiblast
# http://www.ebi.ac.uk/Tools/webservices/clients/ncbiblast
# http://www.ebi.ac.uk/Tools/webservices/tutorials/ruby
# ======================================================================
# Note: stubs need to be generated using:
# wsdl2ruby.rb --type client --wsdl http://wwwdev.ebi.ac.uk/Tools/jdispatcher/services/soap/ncbiblast?wsdl
# ======================================================================
# WSDL URL for service
#wsdlUrl = 'http://wwwdev.ebi.ac.uk/Tools/jdispatcher/services/soap/ncbiblast?wsdl'

# Load libraries 
require 'getoptlong' # Command-line option handling
require 'base64' # Unpack encoded data
require 'ncbiblastDriver.rb' # Generated stubs

# Usage message
def printUsage(returnCode)
  puts <<END_OF_STRING
NCBI BLAST
==========
   
Rapid sequence database search programs utilizing the BLAST algorithm
    
For more detailed help information refer to 
http://www.ebi.ac.uk/Tools/blastall/help.html

[Required]

  -p, --program     : str  : BLAST program to use, see --paramDetail program
  -D, --database    : str  : database(s) to search, space separated. See
                             --paramDetail database
      --stype       : str  : query sequence type, see --paramDetail stype
  seqFile           : file : query sequence ("-" for STDIN)

[Optional]

  -m, --matrix      : str  : scoring matrix, see --paramDetail matrix
  -e, --exp         : real : 0<E<= 1000. Statistical significance threshold 
                             for reporting database sequence matches.
  -f, --filter      :      : filter the query sequence for low complexity 
                             regions, see --paramDetail filter
  -A, --align     : int  : pairwise alignment format, see --paramDetail align
  -s, --scores      : int  : number of scores to be reported
  -n, --alignments  : int  : number of alignments to report
  -u, --match       : int  : Match score (BLASTN only)
  -v, --mismatch    : int  : Mismatch score (BLASTN only)
  -o, --gapopen     : int  : Gap open penalty
  -x, --gapext      : int  : Gap extension penalty
  -d, --dropoff     : int  : Drop-off
  -g, --gapalign    :      : Optimise gapped alignments
      --seqrange    : str  : region within input to use as query

[General]

  -h, --help        :      : prints this help text
      --async       :      : forces to make an asynchronous query
      --email     : str  : e-mail address
      --title       : str  : title for job
      --status      :      : get job status
      --resultTypes :      : get available result types for job
      --polljob     :      : poll for the status of a job
      --jobid       : str  : jobid that was returned when an asynchronous job 
                             was submitted.
      --outfile     : str  : file name for results (default is jobid;
                             "-" for STDOUT)
      --outformat   : str  : result format to retrieve
      --params      :      : list input parameters
      --paramDetail : str  : display details for input parameter
      --quiet       :      : decrease output
      --verbose     :      : increase output
      --trace     :      : show SOAP messages being interchanged 
   
Synchronous job:

  The results/errors are returned as soon as the job is finished.
  Usage: $scriptName --email <your\@email> [options...] seqFile
  Returns: results as an attachment

Asynchronous job:

  Use this if you want to retrieve the results at a later time. The results 
  are stored for up to 24 hours.  
  Usage: $scriptName --async --email <your\@email> [options...] seqFile
  Returns: jobid

  Use the jobid to query for the status of the job. If the job is finished, 
  it also returns the results/errors.
  Usage: $scriptName --polljob --jobid <jobId> [--outfile string]
  Returns: string indicating the status of the job and if applicable, results 
  as an attachment.

Further information:

  http://www.ebi.ac.uk/Tools/ncbiblast/
  http://www.ebi.ac.uk/Tools/webservices/clients/ncbiblast
  http://www.ebi.ac.uk/Tools/webservices/services/ncbiblast
  http://www.ebi.ac.uk/Tools/webservices/tutorials/perl
END_OF_STRING
  exit(returnCode)
end

# Process command-line options
optParser = GetoptLong.new(
# Generic options
['--help', '-h', GetoptLong::NO_ARGUMENT],
['--params', GetoptLong::NO_ARGUMENT],
['--paramDetail', GetoptLong::REQUIRED_ARGUMENT],
['--email', GetoptLong::REQUIRED_ARGUMENT],
['--title', GetoptLong::REQUIRED_ARGUMENT],
['--async', GetoptLong::NO_ARGUMENT],
['--jobid', GetoptLong::REQUIRED_ARGUMENT],
['--status', GetoptLong::NO_ARGUMENT],
['--resultTypes', GetoptLong::NO_ARGUMENT],
['--polljob', GetoptLong::NO_ARGUMENT],
['--outformat', GetoptLong::REQUIRED_ARGUMENT],
['--outfile', GetoptLong::REQUIRED_ARGUMENT],
['--quiet', GetoptLong::NO_ARGUMENT],
['--verbose', GetoptLong::NO_ARGUMENT],
['--debugLevel', GetoptLong::REQUIRED_ARGUMENT],
['--timeout', GetoptLong::REQUIRED_ARGUMENT],
['--trace', GetoptLong::NO_ARGUMENT],
['--WSDL', GetoptLong::REQUIRED_ARGUMENT],

# Tool specific options
['--program', '-p', GetoptLong::REQUIRED_ARGUMENT],
['--database', '-D', GetoptLong::REQUIRED_ARGUMENT],
['--matrix', '-m', GetoptLong::REQUIRED_ARGUMENT],
['--exp', '-E', GetoptLong::REQUIRED_ARGUMENT],
['--filter', '-f', GetoptLong::NO_ARGUMENT],
['--align', '-A', GetoptLong::REQUIRED_ARGUMENT],
['--scores', '-s', GetoptLong::REQUIRED_ARGUMENT],
['--alignments', '-n', GetoptLong::REQUIRED_ARGUMENT],
['--dropoff', '-d', GetoptLong::REQUIRED_ARGUMENT],
['--match_scores', GetoptLong::REQUIRED_ARGUMENT],
['--match', '-u', GetoptLong::REQUIRED_ARGUMENT],
['--mismatch', '-v', GetoptLong::REQUIRED_ARGUMENT],
['--gapopen', '-o', GetoptLong::REQUIRED_ARGUMENT],
['--gapext', '-x', GetoptLong::REQUIRED_ARGUMENT],
['--gapalign', '-g', GetoptLong::NO_ARGUMENT],
['--stype', GetoptLong::REQUIRED_ARGUMENT],
['--seqrange', GetoptLong::REQUIRED_ARGUMENT],
['--sequence', GetoptLong::REQUIRED_ARGUMENT]
)

# Options to exclude from the options passed to launch the app
excludeOpts = {
  'polljob' => 1,
  'status' => 1,
  'jobid' => 1,
  'outfile' => 1,
  'trace' => 1,
}

# Wrapping class for working with the application
class EbiWsAppl
  # Accessor methods for attributes
  attr_reader :timeout, :outputLevel, :debugLevel

  # Constructor
  def initialize(outputLevel, debugLevel, trace, timeout)
    @outputLevel = outputLevel.to_i
    @debugLevel = debugLevel.to_i
    @trace = trace
    @timeout = timeout
  end
  
  # Print debug message
  def printDebugMessage(methodName, message, level)
    if(level <= @debugLevel)
      puts '[' + methodName + '] ' + message
    end
  end
  
  # Get list of input parameters
  def getParams()
    printDebugMessage('getParams', 'Begin', 1)
    soap = soapConnect
    req = nil #GetParameters.new()
    res = soap.getParameters(req)
    p res
    printDebugMessage('getParams', 'End', 1)
    return res.parameters
  end
  
  # Print list of parameter names
  def printParams()
    printDebugMessage('printParams', 'Begin', 1)
    paramsList = getParams()
    paramsList.each { |param|
      puts param.id
    }
    printDebugMessage('printParams', 'End', 1)
  end
  
  # Get detail about a parameter
  def getParamDetail(paramName)
    soap = soapConnect
    return soap.getParameterDetails(paramName)
  end

  # Submit a job
  def submitJob(method, inData, params)
    if File.exist?(inData)
      # Input is a file read it in, otherwise treat as an ID
      inFile = File.new(inData, 'r')
      # Read in input sequence
      sequence = inFile.gets(nil)
      data = [{'type'=>'sequence', 'content'=>sequence}]
    else # Argument is an ID, not a file
      data = [{'type'=>'sequence', 'content'=>inData}]
    end
    # Lauch the job and print the jobId
    soap = soapConnect
    jobId = eval "soap.#{method}(params, data)"
    return jobId
  end

  # Get job status
  def getStatus(jobId)
    printDebugMessage('getStatus', 'Begin', 1)
    soap = soapConnect
    req = GetStatus.new()
    req.jobId = jobId
    res = soap.getStatus(req)
    p res
    status = res.status
    printDebugMessage('getStatus', 'End', 1)
    return status
  end
  
  # Print job status
  def printStatus(jobId)
    printDebugMessage('printStatus', 'Begin', 1)
    status = getStatus(jobId)
    puts status
    printDebugMessage('printStatus', 'End', 1)
  end
  
  # Get result types
  def getResultTypes(jobId)
    printDebugMessage('getResultTypes', 'Begin', 1)
    soap = soapConnect
    req = GetResultTypes.new()
    req.jobId = jobId
    res = soap.getResultTypes(req)
    p res
    printDebugMessage('getResultTypes', 'End', 1)
    return res.resultTypes
  end

  # Print result types
  def printResultTypes(jobId)
    printDebugMessage('printResultTypes', 'Begin', 1)
    resultTypes = getResultTypes(jobId)
    resultTypes.each { |resultType|
      puts resultType
    }
    printDebugMessage('printResultTypes', 'End', 1)
  end

  # Get results for a job
  def getResults(jobId, outfile)
    retFileList = []
    soap = soapConnect
    results = soap.getResults(jobId)
    # Write result to file !!!
    results.each { |result|
      outFileName = "#{outfile}.#{result.ext}"
      outFile = File.new(outFileName, 'w')
      retFileList << outFileName
      # Due to a naming conflict get the result type the long way
      resType = result.__xmlele.last[1]
      resData = soap.poll(jobId, resType)
      # Service retuens base64 encoded string to decode to use
      outFile.puts Base64.decode64(resData)
      outFile.close
    }
    return retFileList
  end

  private
  def soapConnect
    printDebugMessage('soapConnect', 'Begin', 11)
    # Create the service proxy
    soap = JDispatcherService.new()
    soap.options["protocol.http.connect_timeout"] = @timeout
    soap.options["protocol.http.receive_timeout"] = @timeout
    soap.wiredump_dev = STDOUT if @trace
    printDebugMessage('soapConnect', 'End', 11)
    return soap
  end
    
end

# Process command line options
begin
  argHash = {}
  argHash['debugLevel'] = 0
  params = {}
  optParser.each do |name, arg|
    key = name.sub(/^--/, '') # Clean up the argument name
    puts "key: #{key}\tval: #{arg}"
    argHash[key] = arg
    # For application options add to the params hash
    if arg != ''
      params[key] = arg.dup unless excludeOpts[key]
    else
      params[key] = 1
    end
  end
rescue
  $stderr.print 'Error: command line parsing failed: ' + $!
  exit(1)
end

# Do the requested actions
begin
  # Set timeout for connection
  if argHash['timeout']
    timeout = argHash['timeout'].to_i
  else
    timeout = 120
  end
  ebiWsApp = EbiWsAppl.new(argHash['outputLevel'], argHash['debugLevel'], argHash['trace'], timeout)
  
  puts "blah"
  # Help info
  if argHash['help']
    printUsage(0)

  # Get lsit of parameter names
  elsif argHash['params']
    ebiWsApp.printParams()

  # Job based actions
  elsif argHash['jobid']
    puts "JobID: " + argHash['jobid']
    # Get job status
    if argHash['status'] 
      ebiWsApp.printStatus(argHash['jobid'])
    # Get result types
    elsif argHash['resultTypes'] 
      ebiWsApp.printResultTypes(argHash['jobid'])
    # Get job results
    elsif argHash['polljob']
      jobId = argHash['jobid']
      if argHash['outfile']
        fileList = ebiWsApp.getResults(jobId, argHash['outfile'])
      else
        fileList = ebiWsApp.getResults(jobId, jobId)
      end
      fileList.each { |fileName| puts "Wrote result file: #{fileName}" }
    else
      $stderr.print 'Error: for --jobid requires an action (e.g. --status, --resultTypes, --polljob'
      exit(1)
    end

  # Submit a job
  elsif ARGV[0]
    jobId = ebiWsApp.submitJob('runInterProScan', ARGV[0], params)
    # In synchronous mode can now get results otherwise print the jobId
    puts 'JobId: ' + jobId
    if !argHash['async']
      if argHash['outfile']
        fileList = ebiWsApp.getResults(jobId, argHash['outfile'])
      else
        fileList = ebiWsApp.getResults(jobId, jobId)
      end
      fileList.each { |fileName| puts "Wrote result file: #{fileName}" }
    end

  # Unsupported combination of options (or no options)
  else
    $stderr.print "Error: unknown option combination\n"
    exit(1)
  end

# Catch any exceptions and display
rescue StandardError => ex
  puts ex
end
