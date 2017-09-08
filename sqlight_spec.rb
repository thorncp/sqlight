RSpec.describe "sqlight" do
  before(:all) do
    `clang sqlight.c -o sqlight`
  end

  def run_script(commands)
    raw_output = nil

    IO.popen("./sqlight", "r+") do |pipe|
      commands.each do |command|
        pipe.puts command
      end

      pipe.close_write

      raw_output = pipe.gets(nil)
    end

    raw_output.split("\n")
  end

  it "inserts and retrieves a row" do
    script = [
      "insert 1 user user@example.com",
      "select",
      ".exit",
    ]

    result = run_script(script)

    expect(result).to eq [
      "db > Executed",
      "db > (1, user, user@example.com)",
      "Executed",
      "db > bye bye",
    ]
  end

  it "allows string values up to the max length" do
    long_username = "a" * 32
    long_email = "a" * 255
    script = [
      "insert 1 #{long_username} #{long_email}",
      "select",
      ".exit",
    ]

    result = run_script(script)

    expect(result).to eq [
      "db > Executed",
      "db > (1, #{long_username}, #{long_email})",
      "Executed",
      "db > bye bye",
    ]
  end

  context "when the table is full" do
    it "prints an error message" do
      script = (1..1401).map do |i|
        "insert #{i} user#{i} user#{i}@example.com"
      end
      script << ".exit"

      result = run_script(script)

      expect(result[-2]).to eq("db > Error: Table full")
    end
  end

  context "when a value longer than the column size" do
    it "prints an error message" do
      long_username = "a" * 33
      long_email = "a" * 256
      script = [
        "insert 1 #{long_username} #{long_email}",
        "select",
        ".exit",
      ]

      result = run_script(script)

      expect(result).to eq [
        "db > String too long",
        "db > Executed",
        "db > bye bye",
      ]
    end
  end

  context "when inserting a negative id" do
    it "prints an error message" do
      script = [
        "insert -1 user user@example.com",
        "select",
        ".exit",
      ]

      result = run_script(script)

      expect(result).to eq [
        "db > ID must be positive",
        "db > Executed",
        "db > bye bye",
      ]
    end
  end
end
