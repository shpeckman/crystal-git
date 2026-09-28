# spec/attrs_spec.cr
require "./spec_helper"

describe "ignore and attributes" do
  after_each { Fixture.cleanup }

  it "reports ignored paths from .gitignore" do
    Fixture.with_repo("attr_ignore") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, ".gitignore", "*.log\nbuild/\n")

      stream = Git::Stream.new(repo)
      log    = stream.ignored?("app.log")
      build  = stream.ignored?("build/output.bin")
      normal = stream.ignored?("seed.txt")
      stream.run.error.should be_nil
      stream.seal

      stream[log].should be_true
      stream[build].should be_true
      stream[normal].should be_false
    end
  end

  it "resolves attribute values" do
    Fixture.with_repo("attr_values") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, ".gitattributes", "*.txt text\n*.bin binary\n*.md eol=lf\n")

      stream      = Git::Stream.new(repo)
      text        = stream.attr("a.txt", "text")
      binary      = stream.attr("a.bin", "text")
      eol         = stream.attr("README.md", "eol")
      unspecified = stream.attr("a.txt", "bogus")
      stream.run.error.should be_nil
      stream.seal

      stream[text].should eq("set")
      stream[binary].should eq("unset")
      stream[eol].should eq("lf")
      stream[unspecified].should be_nil
    end
  end
end
