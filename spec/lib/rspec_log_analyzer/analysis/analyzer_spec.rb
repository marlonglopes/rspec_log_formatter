require "spec_helper"
require 'tempfile'

describe RspecLogFormatter::Analysis::Analyzer do
  it "sorts the parsed results by failure fraction" do
    filepath = File.expand_path("../../../../fixtures/varying_flakiness.history", __FILE__)
    described_class.new.analyze(filepath).map{|r| r[:fraction] }.should == [
      0.75, 2.0/3.0, 0.50
    ]
    described_class.new.analyze(filepath, max_reruns: 0).map{|r| r[:cost] }.should == [14.0, 13.333333333333332, 12.0]
    described_class.new.analyze(filepath, max_reruns: 1).map{|r| r[:cost] }.should == [15.5, 15.11111111111111, 14.0]
    described_class.new.analyze(filepath, max_reruns: 2).map{|r| r[:cost] }.should == [18.875, 18.666666666666668, 17.0]
    described_class.new.analyze(filepath, max_reruns: 3).map{|r| r[:cost] }.should == [23.09375, 22.617283950617285, 19.5]
  end

  it "works" do
    filepath = File.expand_path("../../../../fixtures/fail_history_analyzer.rspec.history", __FILE__)
    described_class.new.analyze(filepath).first.should == {
      description: "description0",
      fraction: 0.8571428571428571,
      failure_messages: [
        "ec10\n      msg10",
        "ec20\n      msg20",
        "ec30\n      msg30",
        "ec40\n      msg40",
        "ec50\n      msg50",
        "ec60\n      msg60",
      ]
    }
  end


  it "can truncate the log file" do
    filepath = File.expand_path("../../../../fixtures/test_was_flaky_then_fixed.history", __FILE__)
    temp = Tempfile.new('fixture')
    FileUtils.copy(filepath, temp.path)
    described_class.new.truncate(temp.path, keep_builds: 3)
    File.open(temp.path, 'r').read.should == <<HEREDOC
5	2014-01-21 16:08:25 -0800	passed	desc	./spec/m1k1_spec.rb
6	2014-01-21 16:08:25 -0800	passed	desc	./spec/m1k1_spec.rb
7	2014-01-21 16:08:25 -0800	passed	desc	./spec/m1k1_spec.rb
HEREDOC
  end

  it "can analyze only a window of builds" do
    filepath = File.expand_path("../../../../fixtures/test_was_flaky_then_fixed.history", __FILE__)
    subject.analyze(filepath, last_builds: 7).first.should == {
      description: "desc",
      fraction: 0.30,
      failure_messages: ["ec10\n      msg10", "ec10\n      msg10", "ec10\n      msg10"]
    }
    subject.analyze(filepath, last_builds: 5).first.should == {
      description: "desc",
      fraction: 0.16666666666666666,
      failure_messages: ["ec10\n      msg10"],
    }

  end
end
